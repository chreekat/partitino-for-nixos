set -e

hdr () {
	echo
	echo "$@" | tr a-z A-Z
	echo "----------------------------------------------------------------------------"
}

hdr2 () {
	echo
	echo "*      $@"
	echo "----------------------------------------------------------------------------"
}


hdr "choose your device"

fdisk -l

while true; do
	echo; echo
	read -p "Disk to use: " DISK


	hdr overwrite this disk and all "contents?"
	fdisk -l $DISK
	err="$?"
	echo "----------------------------------------------------------------------------"
	echo

	if [[ $err > 0 ]]; then
		echo "Oops, that's not a device anyway"
	else
		read -p "Type yes to overwrite: "
		if [[ $REPLY == "yes" ]]; then
			break
		fi
	fi
done


hdr "Encryption and partitions"

hdr2 "Wiping"

#cryptsetup open --type plain -d /dev/urandom -- "$DISK" to_be_wiped
#dd if=/dev/zero of=/dev/mapper/to_be_wiped  status=progress bs=1M
#cryptsetup close to_be_wiped

hdr2 "Partitioning"
parted -- "$DISK" mklabel gpt
sleep 0.5
parted -- "$DISK" mkpart ESP fat32 1MiB 512MiB
sleep 0.5
parted -- "$DISK" set 1 esp on
parted -- "$DISK" mkpart primary 512MiB 100%

fdisk -l "$DISK"

BOOT="$(lsblk -p --raw | grep "$DISK" | grep ':1' | cut -f1 -d' ')"
ROOT="$(lsblk -p --raw | grep "$DISK" | grep ':2' | cut -f1 -d' ')"

read -p "BOOT will be '$BOOT'. Is this ok?> "
if [[ $REPLY != "yes" ]]; then
	echo "Well fuck you too! :D"
	exit 1
fi
read -p "ROOT will be '$ROOT'. Is this ok?> "
if [[ $REPLY != "yes" ]]; then
	echo "Well fuck you too! :D"
	exit 1
fi

hdr2 "Encrypting"

cryptsetup -- luksFormat "$ROOT"
cryptsetup open "$ROOT" root

hdr2 "Formatting"

mkfs.fat -F 32 -n boot -- "$BOOT"
mkfs.btrfs -L root -- /dev/mapper/root


hdr2 "Creating subvolumes"

mount -- /dev/mapper/root /mnt
btrfs subvolume create /mnt/@
umount /mnt
mount -o subvol=@ /dev/mapper/root /mnt
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/swap

hdr2 "Mounting"

mkdir -p /mnt/boot
mount -- /dev/disk/by-label/boot /mnt/boot

hdr "Enabling swap"

# www.jwillikers.com/btrfs-swapfile
SWAP=/mnt/swap/swapfile
chmod 700 /mnt/swap
truncate -s 0 "$SWAP"
chattr +C "$SWAP"
btrfs property set "$SWAP" compression none
fallocate -l 32G "$SWAP"
chmod 600 "$SWAP"
mkswap "$SWAP"
swapon "$SWAP"

hdr "Enjoy your new filesystems"

nixos-generate-config --root /mnt
