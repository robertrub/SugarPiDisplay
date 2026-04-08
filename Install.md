# SugarPiDisplay Installation Guide

Complete installation instructions for Raspberry Pi Zero W running latest Raspbian (Bookworm).

## Hardware Requirements

- Raspberry Pi Zero W with WiFi (or Pi Zero 2 W)
- Waveshare 2.13" e-ink display (V2 or V3)
- MicroSD card (4GB minimum, 8GB+ recommended)
- Power supply (5V, 2A)
- GPIO header soldered to Pi
- SPI cable for display connection

## Prerequisites

### Update Your Raspberry Pi

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo reboot
```

### Enable SPI and I2C (if needed)

```bash
sudo raspi-config
# Navigate to Interface Options > SPI > Enable
# Also check I2C if using that
```

## Installation Steps

### 1. Clone or Download Repository

```bash
cd ~
git clone https://github.com/robertrub/SugarPiDisplay.git
cd SugarPiDisplay
```

### 2. Run Installation Script

```bash
chmod +x install.sh
./install.sh
```

The script will:
- Install all system dependencies
- Create a Python virtual environment
- Install Python packages from `requirements.txt`
- Configure GPIO permissions
- Enable SPI interface
- Create systemd service files
- Set up automatic startup

### 3. Log Out and Back In

For GPIO permissions to take effect:

```bash
exit
# Log back in via SSH or console
```

### 4. Start the Service

```bash
sudo systemctl start sugarpidisplay.service
sudo systemctl status sugarpidisplay.service
```

## Configuration

### First Run

Access the web interface at: `http://<your-pi-ip>:8080`

Configure:
1. **Data Source**: Choose Nightscout or Dexcom Share
2. **Nightscout URL**: Your Nightscout instance URL
3. **API Token**: Your Nightscout API token
4. **Display Settings**: Orientation, units (mg/dL or mmol/L), 24-hour time format

### Config File Location

Configuration is stored at: `~/.sugarpidisplay/config.json`

### Manual Configuration

Edit directly:
```bash
nano ~/.sugarpidisplay/config.json
```

Example `config.json`:
```json
{
    "data_source": "nightscout",
    "ns_url": "https://yourname.herokuapp.com",
    "ns_token": "your-api-token",
    "time_24hour": true,
    "orientation": 0,
    "show_graph": true,
    "unit_mmol": false,
    "use_animation": false
}
```

## Service Management

### View Service Status

```bash
sudo systemctl status sugarpidisplay.service
```

### View Live Logs

```bash
sudo journalctl -u sugarpidisplay.service -f
```

### View Last 50 Log Lines

```bash
sudo journalctl -u sugarpidisplay.service -n 50
```

### Stop Service

```bash
sudo systemctl stop sugarpidisplay.service
```

### Restart Service

```bash
sudo systemctl restart sugarpidisplay.service
```

### Disable Auto-start

```bash
sudo systemctl disable sugarpidisplay.service
```

### Re-enable Auto-start

```bash
sudo systemctl enable sugarpidisplay.service
```

## Troubleshooting

### Service Won't Start

Check logs for errors:
```bash
sudo journalctl -u sugarpidisplay.service -n 20
```

Common issues:
- GPIO permissions not active (log out and back in)
- SPI not enabled (run `sudo raspi-config`)
- Display not properly connected
- Config file missing or invalid

### GPIO Permission Issues

If you see permission errors:
```bash
sudo usermod -aG gpio $USER
# Log out and back in
```

### Display Not Showing

1. Verify SPI is enabled: `ls /dev/spi*`
2. Check GPIO connections
3. Verify display version in code matches hardware (V2 vs V3)
4. Test with debug mode:
   ```bash
   source ~/SugarPiDisplay/venv/bin/activate
   python3 -m sugarpidisplay debug
   ```

### Network Connectivity

The service includes automatic network monitoring. Check timer status:
```bash
sudo systemctl status sugarpidisplay-network-check.timer
sudo journalctl -u sugarpidisplay-network-check.service -n 10
```

## Updating

To update to latest version:

```bash
cd ~/SugarPiDisplay
git pull origin master
source venv/bin/activate
pip install -r requirements.txt --upgrade
sudo systemctl restart sugarpidisplay.service
```

## Logs Location

Application logs are stored at:
```
~/.sugarpidisplay/sugarpidisplay.log
```

View directly:
```bash
tail -f ~/.sugarpidisplay/sugarpidisplay.log
```

## Performance Notes

- Pi Zero W is single-core with limited RAM - initial startup may take 30-60 seconds
- Web interface port: 8080
- Update interval: 300 seconds (5 minutes) between glucose readings
- Display refresh: Partial when reading updates, full refresh every ~5.5 minutes

## Support

For issues, check:
1. [GitHub Issues](https://github.com/robertrub/SugarPiDisplay/issues)
2. Service logs: `sudo journalctl -u sugarpidisplay.service -f`
3. Configuration at: `~/.sugarpidisplay/config.json`

## License

MIT License - See LICENSE file
