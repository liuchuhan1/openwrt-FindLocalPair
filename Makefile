include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-owrt-peer
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=OpenWRT User
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-owrt-peer
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=OWRT Peer - 内网路由器IP发现
  DEPENDS:=+luci-base +tcpdump +netcat
  PKGARCH:=all
endef

define Package/luci-app-owrt-peer/description
  两台OpenWRT路由器通过ICMP触发+UDP认证互相发现对方IP。
  支持大网段扫描和静态IP模式，带LuCI配置界面。
endef

define Build/Compile
endef

define Package/luci-app-owrt-peer/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/owrt-peer $(1)/etc/config/owrt-peer

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/owrt-peer $(1)/etc/init.d/owrt-peer

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/99-owrt-peer $(1)/etc/uci-defaults/99-owrt-peer

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/owrt-peer-discover $(1)/usr/bin/owrt-peer-discover
	$(INSTALL_BIN) ./files/usr/bin/owrt-peer-status $(1)/usr/bin/owrt-peer-status

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/owrt-peer.lua $(1)/usr/lib/lua/luci/controller/owrt-peer.lua

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/owrt-peer
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/owrt-peer/owrt-peer.lua $(1)/usr/lib/lua/luci/model/cbi/owrt-peer/owrt-peer.lua
endef

$(eval $(call BuildPackage,luci-app-owrt-peer))
