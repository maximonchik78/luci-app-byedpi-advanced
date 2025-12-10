include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for ByeDPI with Auto-detection
LUCI_DEPENDS:=+byedpi +curl +bash +kmod-nf-ipt +iptables-mod-filter +libpcap +libnetfilter-queue +kmod-nfnetlink-queue
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-byedpi-advanced
PKG_VERSION:=2.0.1
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/conffiles
/etc/config/byedpi
/etc/byedpi/
endef

# call BuildPackage - OpenWrt buildroot signature
