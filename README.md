# install-gentoo

This is a learning project to see whether I could actually achieve the feat of automating an entire stage3 tarball based install of Gentoo with Ansible. Please feel free to copy, modify or use it, but don't expect it to be bug-free or work entirely as expected.

Thanks to [jameskyle/ansible-gentoo](https://github.com/jameskyle/ansible-gentoo) for some of the code in the disks/filesystem roles.

![Screenshot of installed Gentoo system with GNOME3](https://gitlab.com/alexhaydock/ansible-gentoo/raw/master/screenshot.png)

### Project Scope
This project loosely follows the Gentoo Handbook and configures a stage3 Gentoo install as follows:
* Partitioning disks
* Creating/mounting filesystems
* Downloading and deploying a stage3 tarball
* Entering the chroot
* Downloading an emerge snapshot and running `emerge --sync`
* Downloading and building the Kernel from source
* Configuring relevant OS services and networking
* Installing GRUB bootloader to primary disk
* Installing GNOME, X.Org and other relevant applications
* Creating users
* (and just generally provisioning a full working desktop environment)

### Known issues / things to bear in mind
* The default user:password combos are `user:user-password` and `root:root-password`, which aren't great and will need changing after install.
* The initial `install.yml` playbook isn't quite fully idempotent, which is generally considered bad Ansible practice. I've tried to control for this by adding checkpoints that write files into `/tmp` as we run through the playbook, recording which steps we've successfully run and making it easier to iterate on the playbook for development.
* This setup uses `systemd`. There is no simple way to switch this to OpenRC within this playbook, but feel free to fork it and do so.

---

## Installation
To use this Ansible Playbook, you will need a system somewhere on your network booted into a fresh copy of the Gentoo Minimal Installation CD.

### Pre-reqs (remote host)
* Remote host, booted to the latest [Gentoo Minimal Installation CD](https://www.gentoo.org/downloads/).
  * If possible, it's recommended to boot in UEFI mode rather than BIOS mode.
* An ethernet connection, up and with an IP address.
  * In theory you could do this on Wi-Fi but you're on your own in terms of configuring Wi-Fi in the LiveCD environment before running this playbook.
* SSH, started and running on the Gentoo LiveCD:
  * `/etc/init.d/sshd start`
* A password set for the `root` account:
  * `passwd root`
  * If you use `root-password` as the password, this playbook will run without modification.
* At least 8GB RAM, otherwise building a full desktop environment will be extremely slow and involve a lot of swapfile use.

### Pre-reqs (local host)
* Ansible
* Ensure that the `firmware_type` variable in `group_vars/all/main.yml` has been updated to reflect your system. The default is EFI. I haven't found a way to automatically switch this yet.
* Ensure that the `eselect_profile` variable in `group_vars/all/main.yml` has been updated to the `eselect profile` that you want to use.

### Install initial system (runs against LiveCD)
Deploy the first stage of installation (targets the booted LiveCD) with:
```sh
ansible-playbook install.yml -vvv -i 'gentoo,' --ask-pass --extra-vars "ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_user=root ansible_host=10.42.2.102"
```

### Install system packages (runs against newly-installed system after a reboot)
and then, once the system is installed and the remote host has rebooted:
```sh
ansible-playbook postinstall.yml -vvv -i 'gentoo,' --ask-pass --extra-vars "ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_user=root ansible_host=10.42.2.102"
```

---

## Known issues / Troubleshooting

### Garbled video output in Proxmox after installation
In Proxmox (and possibly more QEMU/KVM distributions), I've had some issues with the default display adapter after installing the system in EFI mode.

I've found that choosing the `VMware compatible (vmware)` video adapter in the VM's Hardware options fixes the issue.

### Debugging Ansible connectivity
To do some basic debugging, we can run this against our LiveCD host to get some useful Ansible output about our target system:
```sh
ansible gentoo -m setup -vvv -i 'gentoo,' --ask-pass --extra-vars "ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_user=root ansible_host=10.42.2.102"
```

### Deeper debugging within LiveCD environment
If something goes wrong with the Gentoo installation before you've completed it and rebooted into the new system, you can ssh into the LiveCD system:
```sh
ssh 10.42.2.102
```

And then chroot into the installed Gentoo environment to have a look around:
```sh
chroot /mnt/gentoo bash
```

### A note on "Distribution Kernels"
I experimented briefly with using a ["Distribution Kernel"](https://wiki.gentoo.org/wiki/Project:Distribution_Kernel) to simplify the deployment process here. This automates a bunch of steps including building the `initramfs` that the bootloader hands off to. Unfortunately, it seems like the default config used by `sys-kernel/gentoo-kernel` when building the initramfs does not include LVM support (at least it didn't when I tried).

Instead of taking the Distribution Kernel approach, I instead use [Genkernel](https://wiki.gentoo.org/wiki/Genkernel) and build our `initramfs` using `genkernel --lvm --install initramfs`, which builds with LVM support and allows us to boot to a disk that is partitioned using LVM.
