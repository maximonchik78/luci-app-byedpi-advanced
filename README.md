# luci-app-byedpi-advanced

Advanced LuCI interface for ByeDPI on OpenWrt with auto-detection features.

## Features

* Web interface for ByeDPI configuration
* Auto-detection of DPI blocking methods
* Support for multiple bypass modes:
  * Mode 0: Auto (all methods)
  * Mode 1: TTL manipulation
  * Mode 2: Wrong TCP checksums
  * Mode 3: Wrong TCP sequence/acknowledgment
  * Mode 4: TCP fragmentation
  * Mode 5: TCP ACK tampering
  * Mode 6: TCP checksum tampering
* Real-time status monitoring
* Scheduled operation
* Statistics collection
* Easy installation via install.sh

## Installation

### Method 1: Using install.sh (recommended)

```bash
cd /tmp
wget https://raw.githubusercontent.com/maximonchik78/luci-app-byedpi-advanced/main/install.sh
chmod +x install.sh
./install.sh
Method 2: Via OpenWrt feeds
Add to feeds.conf.default:

text
src-git byedpi https://github.com/maximonchik78/luci-app-byedpi-advanced.git
Then:

bash
./scripts/feeds update byedpi
./scripts/feeds install -a -p byedpi
make menuconfig  # Select LuCI -> Applications -> luci-app-byedpi-advanced
Configuration
After installation, configure via LuCI web interface:

Open LuCI: http://192.168.1.1

Go to: Services → ByeDPI Advanced

Configure settings:

Enable service

Select bypass mode (0 for auto)

Set ports (default: 443,80)

Enable auto-detection if needed

Configure test URLs for DPI detection

Usage
Web Interface
Access all features through LuCI web interface.

Command Line
bash
# Start service
/etc/init.d/byedpi start

# Stop service
/etc/init.d/byedpi stop

# Auto-detect DPI settings
/usr/sbin/byedpi-autodetect

# Test current configuration
/etc/init.d/byedpi test

# View logs
cat /tmp/byedpi-autodetect.log
Auto-detection
The auto-detection feature tests multiple bypass methods and ports to find the optimal configuration for your network. It tests against known blocked sites and selects the first working combination.

Test URLs (configurable):

https://rutracker.org

https://vk.com

https://telegram.org

Requirements
OpenWrt 19.07 or newer (24+ recommended)

ByeDPI package installed

LuCI web interface

curl, bash, uci utilities

License
MIT License

Support
For issues and questions, please open an issue on GitHub.

Contributing
Contributions are welcome! Please ensure all shell scripts are POSIX-compatible.
