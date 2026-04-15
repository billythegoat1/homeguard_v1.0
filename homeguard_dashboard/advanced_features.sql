-- HomeGuard Attack Database - Advanced Features

-- ========================================
-- TRIGGER: Auto-update last_seen timestamp
-- ========================================

CREATE TRIGGER IF NOT EXISTS update_device_last_seen
AFTER INSERT ON firewall_events
FOR EACH ROW
BEGIN
    UPDATE devices 
    SET last_seen = CURRENT_TIMESTAMP 
    WHERE device_id = NEW.device_id;
END;

-- Test the trigger
INSERT INTO firewall_events (device_id, event_type, source_ip, destination_port, protocol)
VALUES (1, 'ALLOW', '10.42.0.192', 443, 'TCP');

-- Verify last_seen was updated
SELECT device_name, last_seen FROM devices WHERE device_id = 1;

-- ========================================
-- TRIGGER: Detect port scan attacks
-- ========================================

CREATE TRIGGER IF NOT EXISTS detect_port_scan
AFTER INSERT ON firewall_events
FOR EACH ROW
WHEN NEW.event_type = 'BLOCK'
BEGIN
    -- Count recent blocks from same device
    INSERT OR REPLACE INTO detected_attacks (device_id, attack_type, severity, event_count, status)
    SELECT 
        NEW.device_id,
        'port_scan',
        CASE 
            WHEN COUNT(*) > 20 THEN 'HIGH'
            WHEN COUNT(*) > 10 THEN 'MEDIUM'
            ELSE 'LOW'
        END,
        COUNT(*),
        'ACTIVE'
    FROM firewall_events
    WHERE device_id = NEW.device_id 
      AND event_type = 'BLOCK'
      AND timestamp > datetime('now', '-1 minute');
END;

-- ========================================
-- TRANSACTION: Resolve attack and log action
-- ========================================

BEGIN TRANSACTION;

-- Mark attack as resolved
UPDATE detected_attacks 
SET status = 'RESOLVED', 
    notes = 'Admin intervention - device quarantined'
WHERE attack_id = 2;

-- Log the resolution in firewall events
INSERT INTO firewall_events (device_id, event_type, source_ip, destination_port, protocol)
SELECT device_id, 'BLOCK', '10.42.0.75', 0, 'TCP'
FROM detected_attacks
WHERE attack_id = 2;

COMMIT;

-- Rollback example (for demonstration)
BEGIN TRANSACTION;
DELETE FROM devices WHERE device_id = 1;
ROLLBACK; -- Undo the delete

-- ========================================
-- STORED PROCEDURE EQUIVALENT (User-Defined Function simulation)
-- ========================================

-- SQLite doesn't have stored procedures, but we can create reusable queries as views

CREATE VIEW IF NOT EXISTS high_risk_devices AS
SELECT 
    d.device_name,
    d.ip_address,
    COUNT(DISTINCT da.attack_id) as attack_count,
    MAX(da.severity) as highest_severity,
    SUM(fe_stats.blocks) as total_blocks
FROM devices d
LEFT JOIN detected_attacks da ON d.device_id = da.device_id AND da.status = 'ACTIVE'
LEFT JOIN (
    SELECT device_id, COUNT(*) as blocks
    FROM firewall_events
    WHERE event_type = 'BLOCK'
    GROUP BY device_id
) fe_stats ON d.device_id = fe_stats.device_id
GROUP BY d.device_id
HAVING attack_count > 0 OR total_blocks > 5
ORDER BY attack_count DESC, total_blocks DESC;

-- Use it
SELECT * FROM high_risk_devices;
