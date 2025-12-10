include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for ByeDPI with Auto-detection
LUCI_DEPENDS:=+byedpi +curl +bash +kmod-nf-ipt +iptables-mod-filter
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-byedpi-advanced
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
