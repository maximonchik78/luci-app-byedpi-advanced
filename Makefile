include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for ByeDPI with Auto-detection
LUCI_DEPENDS:=+byedpi +curl +bash +kmod-nf-ipt +iptables-mod-filter +libpcap +libnetfilter-queue
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-byedpi-advanced
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

define Package/$(PKG_NAME)/conffiles
/etc/config/byedpi
/etc/byedpi/
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
