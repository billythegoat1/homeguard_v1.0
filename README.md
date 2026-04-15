# 🛡️ HomeGuard - Network Security Dashboard

A Raspberry Pi-powered network security appliance that provides DNS-based ad blocking, firewall protection, and real-time threat monitoring for your entire home network.

## 🌟 Features

- **WiFi Access Point Mode** - Pi acts as network gateway, routing all traffic
- **DNS-Based Ad Blocking** - Powered by Pi-hole, blocks ads and malware domains  
- **Network-Wide Firewall** - UFW firewall protecting all connected devices
- **Real-Time Dashboard** - Beautiful web interface showing security stats
- **Attack Detection Database** - Logs and tracks security events
- **Auto-Refresh** - Dashboard updates every 10 seconds
- **Mobile Responsive** - Works on phones, tablets, and desktops

## 📊 System Architecture
/home/batman/homeguard/Architecture.png
**All devices connecting to HomeGuard WiFi are:**
- Protected by DNS filtering (blocks ads, malware, trackers)
- Protected by network firewall (blocks unauthorized access)
- Monitored for suspicious activity (logged to database)

## 🚀 Quick Start

### Prerequisites

- Raspberry Pi 4 (2GB+ RAM)
- MicroSD card (16GB+)
- Ethernet cable
- Router with DHCP

### Installation

See **[INSTALL.md](INSTALL.md)** for complete step-by-step guide.

**Quick version:**

```bash
# 1. Install Pi-hole
curl -sSL https://install.pi-hole.net | bash

# 2. Clone this repository
git clone https://github.com/billythegoat1/homeguard.git
cd homeguard

# 3. Setup WiFi Access Point (see INSTALL.md for details)

# 4. Install dashboard dependencies
cd homeguard_dashboard
pip3 install flask --break-system-packages

# 5. Create attack database
sqlite3 homeguard_attacks.db < create_database.sql
sqlite3 homeguard_attacks.db < insert_sample_data.sql

# 6. Run dashboard
sudo python3 app.py

# 7. Access dashboard at http://YOUR_PI_IP:5000
```

## 🏗️ Technology Stack

**Hardware:**
- Raspberry Pi 4 (WiFi AP + Gateway)

**Software:**
- **OS:** Raspberry Pi OS (Debian 12)
- **DNS Filtering:** Pi-hole 6.0
- **Firewall:** UFW (iptables)
- **Access Point:** NetworkManager
- **Dashboard:** Python Flask 3.0
- **Database:** SQLite 3

## 📊 Database Schema

### Pi-hole Database (Read-Only)
Located at `/etc/pihole/pihole-FTL.db`
- Stores DNS queries and blocking history
- Used for dashboard statistics

### Attack Logging Database  
Located at `homeguard_dashboard/homeguard_attacks.db`

**Tables:**
- `devices` - Network devices (MAC, IP, name)
- `firewall_events` - UFW blocks and allows
- `detected_attacks` - Security incidents (port scans, brute force)

**Views:**
- `active_threats` - Currently active security events
- `device_firewall_stats` - Per-device firewall statistics

See `homeguard_dashboard/create_database.sql` for complete schema.

## 🔧 Configuration

### WiFi Network Settings

**Default Credentials:**
- SSID: `HomeGuard`
- Password: `homeguard`

**Change via NetworkManager:**
```bash
sudo nmcli connection modify HomeGuard wifi-sec.psk "YOUR_NEW_PASSWORD"
sudo nmcli connection down HomeGuard
sudo nmcli connection up HomeGuard
```

### Dashboard Port

Default: `5000`

Change in `homeguard_dashboard/app.py`:
```python
app.run(host='0.0.0.0', port=5000, debug=True)
```

### Firewall Rules

```bash
sudo ufw status              # View current rules
sudo ufw allow 8080/tcp      # Add new rule
sudo ufw delete allow 8080   # Remove rule
```
## 🐛 Common Issues

**WiFi devices can't get IP addresses**
- Check firewall allows ports 67/68 (DHCP)
- Verify NetworkManager connection is up

**No internet on WiFi**
- Check NAT rule: `sudo iptables -t nat -L -n -v`
- Verify IP forwarding: `cat /proc/sys/net/ipv4/ip_forward` (should be 1)

**Ads not blocked**
- Verify Pi-hole is running: `pihole status`
- Check DNS on device (should be 10.42.0.1)

**Dashboard won't load**
- Check Flask is running: `sudo systemctl status homeguard-dashboard`
- Verify port 5000 allowed: `sudo ufw status | grep 5000`

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Acknowledgments

- **Pi-hole Team** - DNS filtering excellence
- **Raspberry Pi Foundation** - Affordable computing
- **Flask Team** - Lightweight web framework

## 🎯 Roadmap

- [ ] Email/SMS alerts for critical threats
- [ ] Historical data graphs (Chart.js)
- [ ] Time period filters (Today/Week/Month)
- [ ] Device management UI (block/allow by MAC)
- [ ] Export security reports (PDF)
- [ ] Suricata IDS integration
- [ ] Mobile app

## 📧 Contact

**Billy Nitunga**  
GitHub: [@billythegoat1](https://github.com/billythegoat1)

---

**⭐ Star this repo if you find it useful!**
