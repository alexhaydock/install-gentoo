# ansible-gentoo

[![pipeline status](https://gitlab.com/alexhaydock/ansible-gentoo/badges/master/pipeline.svg)](https://gitlab.com/alexhaydock/ansible-gentoo/-/commits/master)

This is a learning project to see whether I could actually achieve the feat of automating an entire stage3 tarball based install of Gentoo with Ansible. Please feel free to copy, modify or use it, but don't expect it to be bug-free or work entirely as expected.

Thanks to [jameskyle/ansible-gentoo](https://github.com/jameskyle/ansible-gentoo) for some of the code in the disks/filesystem roles.

![Screenshot of installed Gentoo system with GNOME3](https://gitlab.com/alexhaydock/ansible-gentoo/raw/master/screenshot.png)

### Project Scope
This project loosely follows the Gentoo Handbook and configures a stage3 Gentoo install as follows:
* Partitioning disks
* Creating/mounting filesystems
* Entering the chroot
* Downloading and deploying a stage3 tarball
* Downloading an emerge snapshot and running `emerge --sync`
* Configuring relevant OS services and networking
* Installing GRUB bootloader to primary disk
* Installing Docker, GNOME, X.Org and other relevant applications
* Creating users
* Just generally provisioning a full working desktop environment

### What I learned from this project (and why you should try it too!)
I wanted to start a project based around a Gentoo Linux system, as Gentoo is notable for taking a very 'bring your own OS' approach to Linux. As a user, you build your own system exactly how you want it, bringing your own kernel, init system, bootloader, window manager & desktop environment, and applications.

Over the years, Gentoo has gained quite a reputation within tech culture, with the ["Install Gentoo"](https://knowyourmeme.com/memes/install-gentoo) meme spawning from a widely-held belief that the installation process is particularly difficult and laborious. In reality, the documentation behind Gentoo (particularly the [Gentoo Handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64)) is quite comprehensive and easy to follow. Even a relatively-new user should be able to get a system up and running by following the handbook's instructions closely.

With my project, I hoped that learning to automate the build process of a system in this way would teach me more about how Linux systems function and fit together than any course or YouTube tutorial would. However, copy-and-paste does not a guru make, so I decided that merely following the handbook to the letter wasn't going to cut it for my project. I wanted to build myself a functional but *modern* system.

Gentoo is rare among modern Linux distributions in that it still provides first-class support for the OpenRC init system (a.k.a. the old way of doing things). This is what is targeted in the Handbook, and most of the instructions available on the Wiki for other packages assume you are running OpenRC. All is not lost, however, for denizens of planet Red Hat, as Gentoo does make `systemd` available if the user wants to use it. All of the other components of a "next-gen" Linux system are available too: Wayland, `systemd-boot`.

So I decided my direction for the project would be to build out a system using the handbook's suggested setup. After building and automating the handbook's suggested config (over and over, until it works), I would switch out the old-hat components that Gentoo suggests for their fancy modern equivalents. I would switch out OpenRC for systemd, then `grub` for `systemd-boot`, then X.Org for Wayland. Even as simple as migrating from editing `/etc/conf.d/hostname` and `/etc/hosts` to using `hostnamectl`. You get the idea.

It's worth noting that you might not actually *want* all of these components in your system. Next-gen does not always mean "ready", and that's certainly something I discovered along the way. But the idea was not to build myself a next-gen system I actually wanted to use. After all, I could just use [Fedora](https://getfedora.org/) for that. I simply wanted to teach myself more about how systems like this are glued together 'under the hood'.

Anyway, as I'd hoped, I learned a lot from this project, and my progress building out this playbook is all tracked in this repo's git history. I can fully recommend it for anyone interested in learning more about how Linux works under the hood.

**Taking it further:** In future, I'd like to automate the **whole** process using Vagrant, with Ansible as a provisioner, as there's still some pre-setup work that needs to be done in the Gentoo LiveCD before this playbook is run (editing the `sshd` config and starting the daemon, and setting the root password).

### Notes / Caveats
* Uses `systemd`. There is no simple way to switch this to OpenRC.
* There is no LSM active. There is an `eselect profile` with SELinux which I may attempt to use in the future.
* This is also not Gentoo Hardened, but I will consider that `eselect profile` too.
* You need at least 4GB RAM to build a proper system with GNOME. Once it gets to building bits like Webkit and Spidermonkey, it will happily shoot up to 4.5GB+ used. So really 8GB is a bare minimum for desktop Gentoo unless you want to be grinding swap all day.

---

# Building a local VM with Packer (recommended)

### Pre-reqs
* Ansible
* Packer
* VirtualBox
* Nothing listening on port `6666` already on your system (the VM will listen for SSH connections on this port while building)

### Note on Packer and SSH client config
If you experience an error where Ansible is unable to connect, then ensure your `~/.ssh/config` is not too restrictive when it comes to key exchange algorithms and ciphers.

Suggested host ssh client config:
```
Host 127.0.0.1
    HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519,ssh-rsa,ssh-dss
    Ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes256-ctr
```

### Building a VM with Packer
```sh
packer build -on-error=ask packer.json
```

### Packer Quirks
Looking at [the Packer template](https://gitlab.com/alexhaydock/ansible-gentoo/-/blob/master/packer.json) in this repo, you will probably find it to be a bit more rigid than Packer 'best practices'. I have to specify a VirtualBox NAT port for SSH manually, and the Ansible playbook is being run with the [local shell provisioner](https://packer.io/docs/provisioners/shell-local.html) instead of the probably more-appropriate [Ansible provisioner](https://packer.io/docs/provisioners/ansible.html).

The Ansible provisioner for Packer passes `IdentitiesOnly=yes` to the `ansible-playbook` command (to avoid SSH auth failure caused by trying every key the user might have inside `~/.ssh`). Under normal circumstances this would be sensible, but it causes problems here since we're essentially provisioning two machines. (One being the LiveCD where we connect via SSH and install Gentoo into a chroot, and the other being the installed system we then connect to continue setup.)

---

# Installing to a remote host

### Pre-reqs
* Ansible
* Remote host, booted to the latest Gentoo LiveCD
* Local `inventory` file for Ansible to use
* Edit the `group_vars/all/main.yml` file to set any variables which need setting.
  * In particular, there is a variable in here (`firmware_type`) which must be set to either `bios` or `efi` depending on the system you have booted. Setting this wrong may leave your system unbootable or, more likely, the GRUB installation step will simply fail.
* Set a root password on the booted LiveCD
* After install, change the LiveCD's `sshd_config` to allow `root` login with password:
  * `PasswordAuthentication yes`
  * `PermitRootLogin yes`
* Start the SSH server

### Invoke installation with Ansible
Deploy the first stage of installation (targets the booted LiveCD) with:
```sh
make install
```

and then, once the system is installed and the remote host has rebooted:
```sh
make postinstall
```

---

# Development notes for myself

### TODO
* Ditch GRUB for a more modern systemd boot (in progress)
* Follow this guide: https://github.com/hiroru/gentoo_install
* Check whether the `-icu` USE flag is actually needed.

### Notes on USE flag choice
* We might need the `-bindist` flag for GNOME because of licensing issues around elliptic curve patents in the OpenSSL ebuild Yeah... what(?)
  * Anyway, see: https://packages.gentoo.org/useflags/bindist
* The GNU EFI flag might solve an issue where systemd-boot does not work but is definitely not needed for GRUB (it's not even a valid USE flag for GRUB):
  * https://forums.gentoo.org/viewtopic-p-8220098.html?sid=6d1708663f6bd8a6e13382d6715980c6#8220098
* Might need `-consolekit` to avoid conflicts with systemd-logind(?)
* We (might?) need to use `-icu` to work around a circular dependency issue for emerging grub. (Stops `dev-db/sqlite` using this flag).
