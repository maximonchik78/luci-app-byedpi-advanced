# luci-app-byedpi-advanced

Advanced LuCI interface for ByeDPI on OpenWrt with auto-detection features.

## Features
- Web interface for ByeDPI configuration
- Auto-detection of DPI blocking methods
- Support for multiple bypass modes
- Real-time status monitoring
- Easy installation via install.sh

## Installation

### Method 1: Using install.sh
```bash
wget https://raw.githubusercontent.com/maximonchik78/luci-app-byedpi-advanced/main/install.sh
chmod +x install.sh
./install.sh

Method 2: Via OpenWrt feeds
Add to feeds.conf.default:
src-git byedpi https://github.com/maximonchik78/luci-app-byedpi-advanced.git

