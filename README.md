# SugarPiDisplay

Display your CGM (Continuous Glucose Monitor) data on an e-Paper display anywhere in your home or office.

This work have been done by @bassettb . I just updated the code to the new Linux distro and corrected some minor bugs (using a lot of CoPilot time ;)  )
The code have NOT been widely tested and I only use Nightscout (never tested the Dexcom part). If you find bugs or problems, please report.

![SugarPiDisplay](https://raw.githubusercontent.com/bassettb/SugarPiDisplay/master/docs/image2.jpg)

## Features

- **Nightscout Integration**: Read glucose data from your Nightscout instance
- **Dexcom Support**: Connect to Dexcom Share accounts (not tested)
- **Beautiful Display**: Shows glucose level, trend arrow, time of last reading, and optional graph
- **Web Configuration**: Easy-to-use web interface for setup and settings
- **Low Power**: Optimized for Raspberry Pi Zero W
- **Automatic Startup**: Configured to run at boot via systemd
- **Real-time Updates**: Checks for new glucose readings every 5 minutes

## Hardware

- Raspberry Pi Zero W with soldered headers (or Pi Zero 2 W)
- Waveshare 2.13" e-Paper Display (V2 or V3)
- 4GB+ microSD card
- 5V power supply

## Recent Updates (Latest Raspbian Support)

This version has been updated for **Raspbian Bookworm** with:
- ✅ Modern systemd service management (replaces init.d)
- ✅ Python virtual environment support
- ✅ Updated dependencies for Python 3.8+
- ✅ Improved GPIO permission handling
- ✅ Enhanced logging with journalctl
- ✅ Network health monitoring
- ✅ Correction of minor errors and shortcomings of the settings setup page 

## Quick Start

### 1. Clone Repository

```bash
cd ~
git clone https://github.com/robertrub/SugarPiDisplay.git
cd SugarPiDisplay
```

### 2. Run Installation

```bash
chmod +x install.sh
./install.sh
```

### 3. Configure

After installation:
```bash
exit  # Log out to apply permissions
# Log back in
sudo systemctl start sugarpidisplay.service
# Access http://<your-pi-ip>:8080 to configure
```

## Documentation

- **[Hardware Setup](docs/hardware_setup.md)** - Physical assembly guide
- **[Software Setup](docs/software_setup.md)** - Software configuration

## Configuration

Access the web interface at `http://<your-pi-ip>:8080`

Configure:
- Data source (Nightscout or Dexcom)
- API credentials
- Display settings (orientation, units, time format)

Configuration is saved to `~/.sugarpidisplay/config.json`

## Service Commands

```bash
# Start service
sudo systemctl start sugarpidisplay.service

# Check status
sudo systemctl status sugarpidisplay.service

# View logs
sudo journalctl -u sugarpidisplay.service -f

# Stop service
sudo systemctl stop sugarpidisplay.service

# Disable autostart
sudo systemctl disable sugarpidisplay.service
```

## Troubleshooting

Check the [Installation Guide](INSTALL.md) troubleshooting section for common issues.

## License

This code is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Credits

Original project by [Bryan Bassett](https://github.com/bassettb/SugarPiDisplay)

Maintained and updated for modern Raspbian versions.

## Support

- Check logs: `sudo journalctl -u sugarpidisplay.service -f`
- Review config: `cat ~/.sugarpidisplay/config.json`
- GitHub Issues: [Report a problem](https://github.com/robertrub/SugarPiDisplay/issues)
