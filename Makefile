
CONFIG_PATH = config/
FILES_PATH = files/

HOST = 192.168.1.1
USER = root

SSH = ssh -l $(USER) $(HOST)

# on the route install batctl-defauld
PACKAGES_INSTALL = wpad-mesh-wolfssl kmod-batman-adv
PACKAGES_REMOVAL = wpad-basic-wolfssl

CONFIG_WIRELESS = /etc/config/wireless
CONFIG_NETWORK = /etc/config/network

W_IFACE =
W_MODE = sta
W_DEVICE = radio1
W_SSID = my-ssid
W_ENC = psk2
W_KEY = my-password
NETWORK =
N_PROTO = dhcp

HOSTNAME = Accesspoint
DUMB_SERVICES = firewall odhcpd dnsmasq

HAS_INTERNET ?= $(shell $(SSH) ping -c1 www.openwrt.org >/dev/null && echo 1 || echo 0)
HAS_WLAN ?= $(shell $(SSH) grep '$(W_SSID)' $(CONFIG_WIRELESS) >/dev/null && echo 1 || echo 0)

.PHONY: all
all:

.PHONY: connect
connect:
	$(SSH) $(SSH_COMMAND)

.PHONY: reboot
reboot:
	$(SSH) reboot

.PHONY: halt
halt:
	$(SSH) halt

.PHONY: ping
ping:
	ping $(HOST)

.PHONY: route
route:
	watch ip route

.PHONY: clean-knownhosts
clean-knownhosts: $(HOME)/.ssh/known_hosts
	ssh-keygen -f "$(HOME)/.ssh/known_hosts" -R "$(HOST)"

.PHONY: config-ssh
config-ssh: ssh-keys passwd $(CONFIG_PATH)dropbear
	scp $(CONFIG_PATH)dropbear $(USER)@$(HOST):/etc/config/dropbear
	$(SSH) /etc/init.d/dropbear restart

.PHONY: ssh-keys
ssh-keys: authorized_keys
	scp authorized_keys $(USER)@$(HOST):/etc/dropbear/authorized_keys

.PHONY: passwd
passwd:
	$(SSH) grep -c $(USER):: /etc/shadow && \
		$(SSH) passwd || \
		true

.env: .env.dist
	cp .env.dist .env

.PHONY: software
software: $(FILES_PATH)*.ipk
	scp $(FILES_PATH)*.ipk $(USER)@$(HOST):./
	$(SSH) opkg update
	$(SSH) opkg install --download-only $(PACKAGES_INSTALL)
ifneq ($(PACKAGES_REMOVAL),)
	$(SSH) opkg remove $(PACKAGES_REMOVAL)
endif
	$(SSH) opkg install $(PACKAGES_INSTALL)
	$(SSH) opkg install '*.ipk'
	$(SSH) rm '*.ipk'

.PHONY: wifi
wifi: W_IFACE=wifi
wifi: W_MODE=sta
wifi: SERVICE=network
wifi: ACTION=restart
wifi: wireless network radio-enable commit service

.PHONY: wifi-del
wifi-delete: W_IFACE=wifi
wifi-delete: SERVICE=network
wifi-delete: ACTION=restart
wifi-delete: wireless-delete network-delete commit service

.PHONY: mesh
mesh: W_IFACE=mesh
mesh: W_MODE=mesh
mesh: W_ENC=sae
mesh: SERVICE=network
mesh: ACTION=restart
mesh: wireless commit service

.PHONY: mesh-delete
mesh-delete: W_IFACE=mesh
mesh-delete: SERVICE=network
mesh-delete: ACTION=restart
mesh-delete: wireless-delete commit service

.PHONY: wireless
wireless:
ifeq ($(HAS_WLAN),1)
	exit 0
endif
	@echo "config wifi-iface '$(W_IFACE)'\n\
		option device '$(W_DEVICE)'\n\
		option mode '$(W_MODE)'\n\
		option encryption '$(W_ENC)'" \
		| $(SSH) 'tee -a $(CONFIG_WIRELESS)'
ifneq ($(W_MESH_ID),)
	@echo "	option mesh_id '$(W_MESH_ID)'\n\
		option mesh_rssi_threshold '0'\n\
		option mesh_fwding '0'" \
	   	| $(SSH) 'tee -a $(CONFIG_WIRELESS)'
endif
ifneq ($(NETWORK),)
	@echo "	option network '$(NETWORK)'" \
	   	| $(SSH) 'tee -a $(CONFIG_WIRELESS)'
endif
ifneq ($(W_SSID),)
	@echo "	option ssid '$(W_SSID)'" \
	   	| $(SSH) 'tee -a $(CONFIG_WIRELESS)'
endif
	@echo "	option key '$(W_KEY)'\n\n" \
		| $(SSH) 'tee -a $(CONFIG_WIRELESS)'

.PHONY: wireless-delete
wireless-delete:
	$(SSH) uci delete wireless.$(W_IFACE)

.PHONY: radio-enable
radio-enable:
	-$(SSH) uci delete wireless.radio0.disabled
	-$(SSH) uci delete wireless.radio1.disabled

.PHONY: radio-disable
radio-disable:
	$(SSH) uci set wireless.radio0.disabled=1
	$(SSH) uci set wireless.radio1.disabled=1

.PHONY: network
network:
ifneq ($(NETWORK),)
	@echo "config interface '$(NETWORK)'\n\
		option proto '$(N_PROTO)'\n\
" | $(SSH) 'tee -a $(CONFIG_NETWORK)'
endif

.PHONY: network-delete
network-delete:
ifneq ($(NETWORK),)
	$(SSH) uci delete network.$(NETWORK)
endif

.PHONY: commit
commit:
	$(SSH) uci commit

.PHONY: service
service:
	$(SSH) /etc/init.d/$(SERVICE) $(ACTION)

.PHONY: hostname
hostname:
	$(SSH) uci set 'system.@system[0].hostname=$(HOSTNAME)'
	$(SSH) uci set 'uhttpd.defaults.commonname=$(HOSTNAME)'

.PHONY: dumb-services
dumb-services:
	$(SSH) 'for s in $(DUMB_SERVICES); do /etc/init.d/$$s stop; rm -vf /etc/rc.d/*$$s; done'

