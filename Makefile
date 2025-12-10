include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for ByeDPI with Auto-detection
LUCI_DEPENDS:=+byedpi +curl +bash +kmod-nf-ipt +iptables-mod-filter +libpcap +libnetfilter-queue
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-byedpi-advanced
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

define Package/$(PKG_NAME)/conffiles
/etc/config/byedpi
/etc/byedpi/
/usr/sbin/byedpi-autodetect
/usr/sbin/byedpi-manager
endef

define Package/$(PKG_NAME)/description
Advanced LuCI interface for ByeDPI with auto-detection features.
Includes web interface, automatic DPI bypass detection,
and support for multiple bypass modes.
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
