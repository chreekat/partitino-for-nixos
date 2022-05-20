# Partition for NixOS

One man's attempt to set up his new devices for NixOS.

## Current setup

* Unencrypted /boot
* Btrfs on LUKS for the rest
* /home is a subvolume
* /swap is a subvolume
    * TODO: /swap/swapfile exists, but isn't automatically recognized by
      nixos-generate-config.

## Steps taken

* User is prompted for installation disk
* Disk is first randomized
* Partitions created
* Main partition encrypted
* Subvolumes created
* Swap created
* `nixos-generate-config` is run

## Steps *not* taken

(Feel free to suggest improvements here).

* Get your SSH keys from somewhere (or generate new ones)
* Get your standard NixOS configuration from somewhere
* `nixos-install`
