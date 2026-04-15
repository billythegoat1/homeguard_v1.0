-- HomeGuard Attack Database - Example Queries

-- ========================================
-- BASIC CRUD OPERATIONS
-- ========================================

-- CREATE: Add a new device
INSERT INTO devices (mac_address, ip_address, device_name) 
VALUES ('ff:ee:dd:cc:bb:aa', '10.42.0.100', 'Laptop-Work');

-- READ: Get all devices
SELECT * FROM devices;

-- UPDATE: Update device name
UPDATE devices 
SET device_name = 'Personal-Laptop' 
WHERE mac_address = 'ff:ee:dd:cc:bb:aa';

-- DELETE: Remove a device
DELETE FROM devices WHERE device_id = 5;

-- ========================================
-- JOINS - Multiple Tables
-- ========================================

-- Show all firewall events with device info
SELECT 
    d.device_name,
    d.ip_address,
    fe.event_type,
    fe.destination_port,
    fe.timestamp
FROM firewall_events fe
JOIN devices d ON fe.device_id = d.device_id
ORDER BY fe.timestamp DESC;

-- Show attacks with device details
SELECT 
    d.device_name,
    d.ip_address,
    da.attack_type,
    da.severity,
    da.event_count,
    da.status
FROM detected_attacks da
JOIN devices d ON da.device_id = d.device_id
WHERE da.status = 'ACTIVE';

-- ========================================
-- AGGREGATIONS & ANALYTICS
-- ========================================

-- Count attacks by severity
SELECT severity, COUNT(*) as attack_count
FROM detected_attacks
GROUP BY severity
ORDER BY 
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
    END;

-- Device with most firewall blocks
SELECT 
    d.device_name,
    d.ip_address,
    COUNT(*) as block_count
FROM firewall_events fe
JOIN devices d ON fe.device_id = d.device_id
WHERE fe.event_type = 'BLOCK'
GROUP BY d.device_id
ORDER BY block_count DESC
LIMIT 1;

-- ========================================
-- VIEWS - Simplified Access
-- ========================================

-- Use the active_threats view
SELECT * FROM active_threats;

-- Use device_firewall_stats view
SELECT * FROM device_firewall_stats
WHERE blocks > 0
ORDER BY blocks DESC;

-- ========================================
-- SUBQUERIES
-- ========================================

-- Find devices involved in HIGH severity attacks
SELECT DISTINCT d.device_name, d.ip_address
FROM devices d
WHERE d.device_id IN (
    SELECT device_id 
    FROM detected_attacks 
    WHERE severity = 'HIGH'
);

-- ========================================
-- DATE/TIME QUERIES
-- ========================================

-- Attacks detected in last 24 hours
SELECT * FROM detected_attacks
WHERE first_detected > datetime('now', '-1 day');

-- Firewall events from today
SELECT * FROM firewall_events
WHERE date(timestamp) = date('now');
