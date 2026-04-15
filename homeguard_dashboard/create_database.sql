-- HomeGuard Attack Logging Database
-- Created: 2026-03-31

-- Table 1: Devices on the network
CREATE TABLE IF NOT EXISTS devices (
    device_id INTEGER PRIMARY KEY AUTOINCREMENT,
    mac_address TEXT NOT NULL UNIQUE,
    ip_address TEXT,
    device_name TEXT,
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_mac CHECK (length(mac_address) = 17)
);

-- Table 2: Firewall Events
CREATE TABLE IF NOT EXISTS firewall_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_type TEXT NOT NULL CHECK (event_type IN ('BLOCK', 'ALLOW')),
    source_ip TEXT NOT NULL,
    destination_port INTEGER,
    protocol TEXT CHECK (protocol IN ('TCP', 'UDP', 'ICMP')),
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- Table 3: Detected Attacks
CREATE TABLE IF NOT EXISTS detected_attacks (
    attack_id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id INTEGER,
    attack_type TEXT NOT NULL CHECK (attack_type IN ('port_scan', 'brute_force', 'dos', 'suspicious_traffic')),
    severity TEXT NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    event_count INTEGER DEFAULT 1,
    first_detected TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_detected TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RESOLVED', 'INVESTIGATING')),
    notes TEXT,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE SET NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_firewall_timestamp ON firewall_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_firewall_device ON firewall_events(device_id);
CREATE INDEX IF NOT EXISTS idx_attacks_status ON detected_attacks(status);
CREATE INDEX IF NOT EXISTS idx_attacks_severity ON detected_attacks(severity);
CREATE INDEX IF NOT EXISTS idx_devices_ip ON devices(ip_address);

-- View: Active threats summary
CREATE VIEW IF NOT EXISTS active_threats AS
SELECT 
    d.ip_address,
    d.device_name,
    da.attack_type,
    da.severity,
    da.event_count,
    da.first_detected,
    da.last_detected
FROM detected_attacks da
JOIN devices d ON da.device_id = d.device_id
WHERE da.status = 'ACTIVE'
ORDER BY da.severity DESC, da.last_detected DESC;

-- View: Firewall statistics per device
CREATE VIEW IF NOT EXISTS device_firewall_stats AS
SELECT 
    d.ip_address,
    d.device_name,
    COUNT(CASE WHEN fe.event_type = 'BLOCK' THEN 1 END) as blocks,
    COUNT(CASE WHEN fe.event_type = 'ALLOW' THEN 1 END) as allows,
    MAX(fe.timestamp) as last_activity
FROM devices d
LEFT JOIN firewall_events fe ON d.device_id = fe.device_id
GROUP BY d.device_id;
