-- Sample Data for HomeGuard Attack Logging Database

-- Insert devices (network devices)
INSERT INTO devices (mac_address, ip_address, device_name) VALUES
('32:25:8a:44:3b:2d', '10.42.0.192', 'Redmi-Note-11'),
('aa:bb:cc:dd:ee:ff', '10.42.0.50', 'iPhone-Personal'),
('11:22:33:44:55:66', '10.42.0.75', 'Unknown-Device'),
('2c:cf:67:3e:0d:e3', '10.42.0.1', 'HomeGuard-Pi');

-- Insert firewall events
INSERT INTO firewall_events (device_id, event_type, source_ip, destination_port, protocol) VALUES
(3, 'BLOCK', '10.42.0.75', 22, 'TCP'),
(3, 'BLOCK', '10.42.0.75', 23, 'TCP'),
(3, 'BLOCK', '10.42.0.75', 80, 'TCP'),
(3, 'BLOCK', '10.42.0.75', 443, 'TCP'),
(3, 'BLOCK', '10.42.0.75', 3389, 'TCP'),
(1, 'ALLOW', '10.42.0.192', 443, 'TCP'),
(1, 'ALLOW', '10.42.0.192', 80, 'TCP'),
(2, 'ALLOW', '10.42.0.50', 443, 'TCP');

-- Insert detected attacks
INSERT INTO detected_attacks (device_id, attack_type, severity, event_count, notes) VALUES
(3, 'port_scan', 'HIGH', 5, 'Scanning common ports - potential reconnaissance'),
(3, 'suspicious_traffic', 'MEDIUM', 12, 'Multiple connection attempts to restricted ports');

-- Update a device's last_seen timestamp
UPDATE devices SET last_seen = CURRENT_TIMESTAMP WHERE mac_address = '32:25:8a:44:3b:2d';

-- Mark an attack as resolved
UPDATE detected_attacks SET status = 'RESOLVED', notes = 'Device blocked via MAC filter' 
WHERE attack_id = 1;
