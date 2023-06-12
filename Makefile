
CONFIG_PATH = config/
FILES_PATH = files/

HOST = 192.168.1.1
USER = root

SSH = ssh -l $(USER) $(HOST)

# on the route install batctl-defauld
PACKAGES_INSTALL = wpad-mesh-wolfssl batman-adv
PACKAGES_REMOVAL = wpad-basic-wolfssl

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

.PHONY: clean-knownhosts
clean-knownhosts: $(HOME)/.ssh/known_hosts
	ssh-keygen -f "$(HOME)/.ssh/known_hosts" -R "$(HOST)"

.PHONY: config-ssh
config-ssh: ssh-keys passwd $(CONFIG_PATH)dropbear
	scp $(CONFIG_PATH)dropbear $(USER)@$(HOST):/etc/config/dropbear
	$(SSH) uci commit

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
	$(SSH) install --download-only $(PACKAGES_INSTALL)
ifneq ($(PACKAGES_REMOVAL),)
	$(SSH) remove $(PACKAGES_REMOVAL)
endif
	$(SSH) install $(PACKAGES_INSTALL)
	$(SSH) install '*.ipk'

