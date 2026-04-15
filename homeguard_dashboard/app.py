#! /usr/bin/env python3

from flask import Flask, render_template

import sqlite3
import subprocess

def get_ufw_stats():
	"""
	Get UFW logs and count allows and blocks
	"""
	result = subprocess.run(["sudo","dmesg"], capture_output=True, text=True)
	output = result.stdout
	#Split the output into lines
	lines = output.split('\n')

	#Check if the line contain allow or block
	block_count = 0
	allow_count = 0
	for line in lines:
		if 'UFW BLOCK' in line:
			block_count += 1
		if 'UFW ALLOW' in line:
			allow_count += 1

	return block_count, allow_count

app = Flask(__name__)


@app.route('/')
def home():
    #connect to the pihole database
    conn = sqlite3.connect('/etc/pihole/pihole-FTL.db')
    cursor = conn.cursor()

    #Get total today queries
    cursor.execute("""

	SELECT COUNT(*)
	FROM queries
	WHERE timestamp > strftime('%s', 'now', 'start of day')
                   
    """)
    today_total_queries = cursor.fetchone()[0]

    #Get today blocked queries
    cursor.execute("""
                   
	SELECT COUNT(*)
	FROM queries
	WHERE status in (1,4,5,6,7,8,9,10,11)
	AND timestamp > strftime('%s', 'now', 'start of day')
                   
    """)
    today_blocked_queries = cursor.fetchone()[0]

    #Query 3: Top blocked queries today
    cursor.execute("""
                   
	SELECT domain, COUNT(*) as count
	FROM queries
	WHERE status in (1,4,5,6,7,8,9,10,11)
	AND timestamp > strftime('%s', 'now', 'start of day')
  	GROUP BY domain
	ORDER BY count DESC
	LIMIT 5
                   
    """)
    today_top_blocked_queries = cursor.fetchall()
    ufw_blocks, ufw_allows = get_ufw_stats()

    return render_template('dashboard.html', 
                           today_total_queries=today_total_queries,
                           today_blocked_queries=today_blocked_queries,
                           today_top_blocked_queries=today_top_blocked_queries,
			   ufw_blocks= ufw_blocks,
			   ufw_allows= ufw_allows)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
