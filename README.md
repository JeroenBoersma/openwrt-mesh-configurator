# OpenWRT mesh configurator Makefile
Configure multiple [OpenWRT](https://openwrt.org/) routers/accesspoints into a mesh network with one Makefile.
To make it a repeatable task.

The configuration is with [B.A.T.M.A.N](https://www.open-mesh.org/projects/batman-adv/wiki)

*WIP: this is my Work In Progress repo to make, expect backwards incompatible changes*

## Goal
Make configuration of multiple routers/accesspoints an easy task.
If the accesspoint is in the mesh and you can access it, your can do run over the air commands for example for adding or removing networks.

## Features/TODO
- (dis-)connect to a existing wifi (for installing software and updates)
- install software (at least `kmod-batman-adv` and `wpad-mesh-wolfssl`)
- connect and configure mesh
- connect to batman/bat0 \*
- configure bridges to batman vlans \*
- turn your router into a dump accesspoint
- add/remove networks/interfaces/wlans \*
- reboot/halt
- enable/disable radio
- connect (SSH into a device)
- ... \*

\* todo

## Hardware
I went for hardware which is in the [Table of Hardware](https://openwrt.org/toh/start) to make sure it's supported, furtermore, I went for hardware which supports the latest version of openwrt.

## Prequisities
You already have the latest OpenWRT installed on your accesspoint and you can connect to it over wire.

Make sure to put your cabled network on `192.168.1.66/24` because we disable `dhcpd` on the dump accesspoints.

## Notes
- I leave the `192.168.1.1/24`(`br-lan`) for what it is, if you make and error, you can recover because this network is still working over wire.

## Thanks to
It would be impossible to build this if the next list of mentions didn't already put time in this.

- (OpenWRT)[https://openwrt.org/] for this amazing firmware
- (B.A.T.M.A.N)(https://www.open-mesh.org/projects/batman-adv/wiki) for an easy way to connect everything together
- (Freifunk)[https://freifunk.net/en/] for building all this and supporting
- (oneMarcFifty)[https://github.com/onemarcfifty] for the work and videos which triggered me
- (Carlos Gomes)[https://cgomesu.com/blog/Mesh-networking-openwrt-batman/] for a througout

