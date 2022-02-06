#
# Copyright (C) 2018 Chion Tang <tech@chionlab.moe>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=fullconenat
PKG_RELEASE:=1

PKG_SOURCE_DATE:=2022-01-29
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/llccd/netfilter-full-cone-nat.git
PKG_SOURCE_VERSION:=1dffa4c87659c58c0b6a680b08acd4dfdb78da38

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/fullconenat
  SUBMENU:=Firewall
  SECTION:=net
  CATEGORY:=Network
  TITLE:=FULLCONENAT config and script
  DEPENDS:=+iptables-mod-fullconenat +firewall
  MAINTAINER:=pexcn <i@pexcn.me>
endef

define Package/fullconenat/conffiles
/etc/config/fullconenat
endef

define Package/fullconenat/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) files/fullconenat.init $(1)/etc/init.d/fullconenat
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) files/fullconenat.defaults $(1)/etc/uci-defaults/99-fullconenat
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) files/fullconenat.config $(1)/etc/config/fullconenat
endef

define Package/fullconenat/postrm
#!/bin/sh
uci -q delete firewall.fullconenat
uci commit firewall
endef

define Package/iptables-mod-fullconenat
  SUBMENU:=Firewall
  SECTION:=net
  CATEGORY:=Network
  TITLE:=FULLCONENAT iptables extension
  DEPENDS:=+iptables +kmod-ipt-fullconenat
  MAINTAINER:=Chion Tang <tech@chionlab.moe>
endef

define Package/iptables-mod-fullconenat/install
	$(INSTALL_DIR) $(1)/usr/lib/iptables
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libipt_FULLCONENAT.so $(1)/usr/lib/iptables
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libip6t_FULLCONENAT.so $(1)/usr/lib/iptables
endef

define KernelPackage/ipt-fullconenat
  SUBMENU:=Netfilter Extensions
  TITLE:=FULLCONENAT netfilter module
  DEPENDS:=+kmod-nf-ipt +kmod-nf-nat +kmod-nf-ipt6 +kmod-nf-nat6
  MAINTAINER:=Chion Tang <tech@chionlab.moe>
  KCONFIG:=CONFIG_NF_CONNTRACK_EVENTS=y CONFIG_NF_CONNTRACK_CHAIN_EVENTS=y
  FILES:=$(PKG_BUILD_DIR)/xt_FULLCONENAT.ko
endef

include $(INCLUDE_DIR)/kernel-defaults.mk

define Build/Prepare
	$(call Build/Prepare/Default)
	$(CP) ./files/Makefile $(PKG_BUILD_DIR)/
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" \
        CROSS_COMPILE="$(TARGET_CROSS)" \
        ARCH="$(LINUX_KARCH)" \
        M="$(PKG_BUILD_DIR)" \
        EXTRA_CFLAGS="$(BUILDFLAGS)" \
        modules
	$(call Build/Compile/Default)
endef

$(eval $(call BuildPackage,fullconenat))
$(eval $(call BuildPackage,iptables-mod-fullconenat))
$(eval $(call KernelPackage,ipt-fullconenat))
