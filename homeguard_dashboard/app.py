#!/usr/bin/env python3

from flask import Flask, render_template
import sqlite3
import subprocess

app = Flask(__name__)

# Database path
PIHOLE_DB = '/etc/pihole/pihole-FTL.db'


def get_ufw_stats():
    """
    Get UFW logs and count allows and blocks
    """
    result = subprocess.run(["sudo", "dmesg"], capture_output=True, text=True)
    output = result.stdout
    
    # Count blocks and allows
    block_count = output.count('[UFW BLOCK]')
    allow_count = output.count('[UFW ALLOW]')
    
    return block_count, allow_count


def detect_dns_attacks():
    """
    Detect DNS-based attacks from Pi-hole query patterns
    Returns: List of detected attacks with severity
    """
    conn = sqlite3.connect(PIHOLE_DB)
    cursor = conn.cursor()
    
    detected = []
    
    # DNS Tunneling Detection (domains >50 chars)
    cursor.execute("""
        SELECT domain, LENGTH(domain) as len, client
        FROM queries
        WHERE LENGTH(domain) > 50
        AND timestamp > strftime('%s', 'now', '-1 hour')
        GROUP BY domain, client
        ORDER BY len DESC
        LIMIT 10
    """)
    
    for domain, length, client in cursor.fetchall():
        detected.append({
            'type': 'DNS Tunneling',
            'severity': 'HIGH' if length > 80 else 'MEDIUM',
            'client': client,
            'details': f'{length} chars',
            'domain': domain[:50] + '...' if len(domain) > 50 else domain
        })
    
    # Query Flooding Detection (>100 queries in 5 min)
    cursor.execute("""
        SELECT client, COUNT(*) as query_count
        FROM queries
        WHERE timestamp > strftime('%s', 'now', '-5 minutes')
        GROUP BY client
        HAVING COUNT(*) > 100
        ORDER BY query_count DESC
        LIMIT 10
    """)
    
    for client, count in cursor.fetchall():
        detected.append({
            'type': 'Query Flooding',
            'severity': 'HIGH' if count > 200 else 'MEDIUM',
            'client': client,
            'details': f'{count} queries/5min',
            'domain': 'Multiple'
        })
    
    conn.close()
    return detected

def get_last_7_days_stats():
    """
    Get query statistics for the last 7 days
    Returns: Dictionary with dates and counts
    """
    conn = sqlite3.connect(PIHOLE_DB)
    cursor = conn.cursor()
    
    # Get total queries per day for last 7 days
    cursor.execute("""
        SELECT 
            DATE(timestamp, 'unixepoch', 'localtime') as day,
            COUNT(*) as total_queries,
            SUM(CASE WHEN status IN (1,4,5,6,7,8,9,10,11) THEN 1 ELSE 0 END) as blocked_queries
        FROM queries
        WHERE timestamp > strftime('%s', 'now', '-7 days')
        GROUP BY day
        ORDER BY day ASC
    """)
    
    results = cursor.fetchall()
    conn.close()
    
    # Format data for Chart.js
    labels = []
    total_data = []
    blocked_data = []
    
    for day, total, blocked in results:
        labels.append(day)
        total_data.append(total)
        blocked_data.append(blocked if blocked else 0)
    
    return {
        'labels': labels,
        'total_queries': total_data,
        'blocked_queries': blocked_data
    }

@app.route('/')
def home():
    # Connect to the Pi-hole database
    conn = sqlite3.connect(PIHOLE_DB)
    cursor = conn.cursor()

    # Get total queries today
    cursor.execute("""
        SELECT COUNT(*)
        FROM queries
        WHERE timestamp > strftime('%s', 'now', 'start of day')
    """)
    today_total_queries = cursor.fetchone()[0]

    # Get blocked queries today
    cursor.execute("""
        SELECT COUNT(*)
        FROM queries
        WHERE status IN (1,4,5,6,7,8,9,10,11)
        AND timestamp > strftime('%s', 'now', 'start of day')
    """)
    today_blocked_queries = cursor.fetchone()[0]

    # Top blocked queries today
    cursor.execute("""
        SELECT domain, COUNT(*) as count
        FROM queries
        WHERE status IN (1,4,5,6,7,8,9,10,11)
        AND timestamp > strftime('%s', 'now', 'start of day')
        GROUP BY domain
        ORDER BY count DESC
        LIMIT 5
    """)
    today_top_blocked_queries = cursor.fetchall()
    
    conn.close()
    
    # Get firewall stats
    ufw_blocks, ufw_allows = get_ufw_stats()
    
    # Detect attacks
    detected_attacks = detect_dns_attacks()

    # Get last 7 days stats (ADD THIS)
    history = get_last_7_days_stats()

    return render_template('dashboard.html', 
                         today_total_queries=today_total_queries,
                         today_blocked_queries=today_blocked_queries,
                         today_top_blocked_queries=today_top_blocked_queries,
                         ufw_blocks=ufw_blocks,
                         ufw_allows=ufw_allows,
                         detected_attacks=detected_attacks,
                         history=history)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)