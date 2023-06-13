
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

INTERNET_IFACE = wifinet2
INTERNET_DEVICE = radio1
INTERNET_MODE = sta
INTERNET_NETWORK = wwan
INTERNET_SSID = my-ssid
INTERNET_ENC = psk2
INTERNET_KEY = my-password
INTERNET_PROTO = dhcp

HAS_INTERNET := $(shell $(SSH) ping -c1 www.openwrt.org >/dev/null && echo 1 || echo 0)
HAS_WLAN := $(shell $(SSH) grep '$(INTERNET_SSID)' $(CONFIG_WIRELESS) >/dev/null && echo 1 || echo 0)

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
wifi:
ifeq ($(HAS_WLAN),0)
	echo "config wifi-iface '$(INTERNET_IFACE)'\n\
		option device '$(INTERNET_DEVICE)'\n\
		option mode '$(INTERNET_MODE)'\n\
		option network '$(INTERNET_NETWORK)'\n\
		option ssid '$(INTERNET_SSID)'\n\
		option encryption '$(INTERNET_ENC)'\n\
		option key '$(INTERNET_KEY)'\n\
" | $(SSH) 'tee -a $(CONFIG_WIRELESS)'
	echo "config interface '$(INTERNET_NETWORK)'\n\
		option proto '$(INTERNET_PROTO)'\n\
" | $(SSH) 'tee -a $(CONFIG_NETWORK)'
	$(SSH) /etc/init.d/network restart
endif

