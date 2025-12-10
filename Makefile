include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-byedpi-advanced
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=maximonchik78 <your@email.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI Support for ByeDPI with Auto-detection
  DEPENDS:=+luci-base +byedpi +curl +bash +kmod-nf-ipt +iptables-mod-filter +libpcap +libnetfilter-queue
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  Advanced LuCI interface for ByeDPI with auto-detection features.
  Includes web interface, automatic DPI bypass detection,
  and support for multiple bypass modes.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/byedpi
/etc/byedpi/
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) ./luasrc/* $(1)/usr/lib/lua/luci/
	
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/byedpi $(1)/etc/config/byedpi
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/byedpi $(1)/etc/init.d/byedpi
	
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/* $(1)/usr/sbin/
	
	$(INSTALL_DIR) $(1)/etc/byedpi/scripts
	$(INSTALL_BIN) ./files/etc/byedpi/scripts/* $(1)/etc/byedpi/scripts/
	
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./files/usr/libexec/rpcd/* $(1)/usr/libexec/rpcd/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
