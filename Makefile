# Copyright 2025 Filip Pynckels
# See https://github.com/Pynckels/gnu-linux/blob/main/LICENSE

# This software is distributed as-is,
# with no warranty or guarantee of its
# functionality, performance, or usability.

# ------------------------------------------------------------------------------
#
# kernel.defconfig is created as follows:
#
# cd kernel
# make tinyconfig
# make menuconfig
#
#    General setup
#        Configure standard kernel features (expert users)
#            [*]   Enable support for printk
#    [*] 64-bit kernel
#    [*] Enable the block layer
#    Executable file formats
#        [*] Kernel support for ELF binaries
#        [*] Kernel support for scripts starting with #!
#    Device Drivers
#        [*] PCI support
#        Generic Driver Options
#            [*] Maintain a devtmpfs filesystem to mount at /dev
#            [*]   Automount devtmpfs at /dev, after the kernel mounted the roo>
#        [*] Serial ATA and Parallel ATA drivers (libata)
#            [*]       Intel ESB, ICH, PIIX3, PIIX4 PATA/SATA support
#        SCSI device support
#            [*] SCSI disk support
#        Character devices
#            [*] Enable TTY
#            Serial drivers
#                [*] 8250/16550 and compatible serial support
#                [*]   Console on 8250/16550 and compatible serial port
#    File systems
#        [*] The Extended 4 (ext4) filesystem
#        Pseudo filesystems
#            [*] /proc file system support
#            [*] sysfs file system support
#
# make savedefconfig
# mv defconfig ../kernel.defconfig.
# cd ..
#
# ------------------------------------------------------------------------------

DISK      = gnu-linux.img
DISK_SIZE = 1G

# Default value if "make DEBUG=0" or "make DEBUG=1" is not used
MESSAGES ?= 0

# ------------------------------------------------------------------------------

NJBS = $(shell nproc)
ROOT = $(shell pwd)/root
USER = $(shell id -u)

ifeq ($(MESSAGES), 0)
	GETOUT = -q
	GITOUT = -q
	STDOUT = > /dev/null 2>&1
else
	# These are defined because empty variables
	# generate make errors...
	GETOUT = -v
	GITOUT = -v
	STDOUT = 2>&1
endif

# ------------------------------------------------------------------------------

all: gnu-linux-ext

gnu-linux-ext:       \
	build_kernel     \
	build_bash       \
	build_ncurses    \
	build_coreutils  \
	build_util_linux \
	build_glibc      \
	build_nano       \
	create_init      \
	create_disk

gnu-linux:           \
	build_kernel     \
	build_bash       \
	build_ncurses    \
	build_coreutils  \
	build_util_linux \
	build_glibc      \
	create_init      \
	create_disk

# ------------------------------------------------------------------------------

build_bash: create_directories

	@if [ ! -d "bash/.git" ]; then                                                    \
		echo "  CLONE   bash";                                                        \
		git clone --depth 1 $(GITOUT) https://git.savannah.gnu.org/git/bash.git bash; \
	fi

	@mkdir -p bash-build

	@if [ ! -f "bash-build/Makefile" ]; then                        \
		echo "  CONFIG  bash";                                      \
		cd bash-build && ../bash/configure --prefix=/usr $(STDOUT); \
	fi

	@if [ ! -f "bash-build/bash" ]; then                                \
		echo "  BUILD   bash";                                          \
		$(MAKE) -j$(NJBS) --no-print-directory -C bash-build $(STDOUT); \
	fi

	@if [ ! -f "$(ROOT)/usr/bin/bash" ]; then                         \
		echo "  INSTALL bash";                                        \
		$(MAKE) DESTDIR=$(ROOT) install -C bash-build $(STDOUT); \
	fi

	@cd $(ROOT) && ln -f -s bash bin/sh

# ------------------------------------------------------------------------------

build_coreutils: create_directories

	@if [ ! -d "coreutils/.git" ]; then                                                 \
		echo "  CLONE   coreutils";                                                     \
		git clone --depth 1 $(STDOUT) https://github.com/coreutils/coreutils coreutils; \
	fi

	@mkdir -p coreutils-build

	@if [ ! -f "coreutils/configure" ]; then   \
		echo "  CONFIG  coreutils-configure";  \
		cd coreutils && ./bootstrap $(STDOUT); \
	fi

	@if [ ! -f "coreutils-build/Makefile" ]; then                                                                 \
		echo "  CONFIG  coreutils";                                                                               \
		cd coreutils-build && ../coreutils/configure --without-selinux --disable-libcap --prefix=/usr $(STDOUT); \
	fi

	@if [ ! -f "coreutils-build/src/whoami" ]; then                          \
		echo "  BUILD   coreutils";                                          \
		$(MAKE) -j$(NJBS) --no-print-directory -C coreutils-build $(STDOUT); \
	fi

	@if [ ! -f "$(ROOT)/usr/bin/whoami" ]; then                             \
		echo "  INSTALL coreutils";                                         \
		$(MAKE) DESTDIR=$(ROOT) install -C coreutils-build  $(STDOUT); \
	fi


# ------------------------------------------------------------------------------

build_glibc: create_directories

	@if [ ! -d "glibc/.git" ]; then                                     \
		echo "  CLONE   glibc";                                         \
		git clone --depth 1 $(GITOUT) https://sourceware.org/git/glibc; \
	fi

	@mkdir -p glibc-build

	@if [ ! -f "glibc-build/Makefile" ]; then                                       \
		echo "  CONFIG  glibc";                                                     \
		cd glibc-build && ../glibc/configure --libdir=/lib --prefix=/usr $(STDOUT); \
	fi

	@if [ ! -f "glibc-build/libc.so" ]; then                             \
		echo "  BUILD   glibc";                                          \
		$(MAKE) -j$(NJBS) --no-print-directory -C glibc-build $(STDOUT); \
	fi

	@if [ ! -f "$(ROOT)/usr/lib/libc.so" ]; then                       \
		echo "  INSTALL glibc";                                        \
		$(MAKE) DESTDIR=$(ROOT) install -C glibc-build $(STDOUT); \
	fi

# ------------------------------------------------------------------------------

build_kernel: create_directories

	@if [ ! -d "kernel/.git" ]; then                                            \
		echo "  CLONE   kernel";                                                \
		git clone --depth 1 $(GITOUT) https://github.com/torvalds/linux kernel; \
	fi

	@if [ ! -f "kernel/.config" ]; then                                \
		echo "  CONFIG  kernel";                                       \
		cp kernel.defconfig kernel/.config;                            \
		$(MAKE) olddefconfig --no-print-directory -C kernel $(STDOUT); \
	fi

	@if [ ! -f "kernel/arch/x86/boot/bzImage" ]; then               \
		echo "  BUILD   kernel";                                    \
		$(MAKE) -j$(NJBS) --no-print-directory -C kernel $(STDOUT); \
	fi

	@if [ ! -f "$(ROOT)/boot/bzImage" ]; then           \
		echo "  INSTALL kernel";                        \
		cp kernel/arch/x86/boot/bzImage $(ROOT)/boot/;  \
	fi

# ------------------------------------------------------------------------------

build_nano: create_directories

	@if [ ! -d "nano/.git" ]; then                                         \
		echo "  CLONE   nano";                                             \
		git clone --depth 1 $(GITOUT) git://git.savannah.gnu.org/nano.git; \
	fi

	@mkdir -p nano-build

	@if [ ! -f "nano/configure" ]; then    \
		echo "  CONFIG  nano-configure";   \
		cd nano && ./autogen.sh $(STDOUT); \
	fi

	@if [ ! -f "nano-build/Makefile" ]; then                                           \
		echo "  CONFIG  nano";                                                         \
		cd nano-build && ../nano/configure --disable-libmagic --prefix=/usr $(STDOUT); \
	fi

	@if [ ! -f "nano-build/src/nano" ]; then                            \
		echo "  BUILD   nano";                                          \
		$(MAKE) -j$(NJBS) --no-print-directory -C nano-build $(STDOUT); \
	fi

	@if [ ! -f "$(ROOT)/usr/bin/nano" ]; then                         \
		echo "  INSTALL nano";                                        \
		$(MAKE) DESTDIR=$(ROOT) install -C nano-build $(STDOUT); \
	fi

# ------------------------------------------------------------------------------

build_ncurses: create_directories

	@if [ ! -d "ncurses" ]; then                                           \
		echo "  GET     ncurses";                                          \
		wget $(GETOUT) https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz; \
		tar -xvzf ncurses-6.5.tar.gz $(STDOUT);                            \
		rm ncurses-6.5.tar.gz;                                             \
		mv ncurses-6.5 ncurses;                                            \
	fi

	@mkdir -p ncurses-build

	@if [ ! -f "ncurses-build/Makefile" ]; then                                                                                            \
		echo "  CONFIG  ncurses";                                                                                                          \
		cd ncurses-build && ../ncurses/configure --with-shared --with-termlib --enable-wedec -with-versioned-syms --prefix=/usr $(STDOUT); \
	fi

	@if [ ! -f "ncurses-build/lib/libncursesw.so" ]; then                  \
		echo "  BUILD   ncurses";                                          \
		$(MAKE) -j$(NJBS) --no-print-directory -C ncurses-build $(STDOUT); \
	fi

	@if [ ! -f "$(ROOT)/usr/lib/libncurses.so.6" ]; then                         \
		echo "  INSTALL ncurses";                                                \
		$(MAKE) DESTDIR=$(ROOT) install -C ncurses-build $(STDOUT);              \
		cd $(ROOT) && ln -s libncursesw.so.6 lib/libncurses.so.6 $(STDOUT);      \
		cd $(ROOT) && ln -s libtinfow.so.6 lib/libtinfo.so.6 $(STDOUT);          \
		mkdir $(ROOT)/etc;                                                       \
		echo "/usr/lib"   | tee    $(ROOT)/etc/ld.so.conf $(STDOUT);             \
		echo "/usr/lib64" | tee -a $(ROOT)/etc/ld.so.conf $(STDOUT);             \
		cd $(ROOT) && ldconfig -v -r ./ $(STDOUT);                               \
	fi

# ------------------------------------------------------------------------------

build_util_linux: create_directories
# "sudo $(MAKE) install" to permit make to change the group of /usr/bin/wall to tty

	@if [ ! -d "util-linux/.git" ]; then                                                   \
		echo "  CLONE   util-linux";                                                       \
		git clone --depth 1 $(GITOUT) https://github.com/util-linux/util-linux util-linux; \
	fi

	@mkdir -p util-linux-build

	@if [ ! -f "util-linux/configure" ]; then    \
		echo "  CONFIG  util-linux-configure";   \
		cd util-linux && ./autogen.sh $(STDOUT); \
	fi

	@if [ ! -f "util-linux-build/Makefile" ]; then                                                                       \
		echo "  CONFIG  util-linux";                                                                                     \
		cd util-linux-build && ../util-linux/configure --without-libmagic --disable-liblastlog2 --prefix=/usr $(STDOUT); \
	fi

	@if [ ! -f "util-linux-build/mount" ]; then                               \
		echo "  BUILD   util-linux";                                          \
		$(MAKE) -j$(NJBS) --no-print-directory -C util-linux-build $(STDOUT); \
	fi

	@if [ ! -f "$(ROOT)/usr/bin/mount" ]; then                               \
		echo "  INSTALL util-linux";                                         \
		sudo $(MAKE) DESTDIR=$(ROOT) install -C util-linux-build  $(STDOUT); \
	fi

# ------------------------------------------------------------------------------

create_directories:
	@echo "  CREATE  $(ROOT)"
	@mkdir -p $(ROOT)
	@mkdir -p $(ROOT)/boot
	@mkdir -p $(ROOT)/dev
	@mkdir -p $(ROOT)/proc
	@mkdir -p $(ROOT)/sys
	@mkdir -p $(ROOT)/usr
	@mkdir -p $(ROOT)/usr/bin
	@mkdir -p $(ROOT)/usr/lib
	@mkdir -p $(ROOT)/usr/lib64
	@mkdir -p $(ROOT)/usr/sbin
	@cd $(ROOT) && ln -f -s usr/bin   bin
	@cd $(ROOT) && ln -f -s usr/lib   lib
	@cd $(ROOT) && ln -f -s usr/lib64 lib64
	@cd $(ROOT) && ln -f -s usr/sbin  sbin

# ------------------------------------------------------------------------------

create_disk: create_disk_1 create_disk_2
# build_disk is split in two to guarantee that all of create_disk_1
# is executed before the $(eval...) in create_disk_2

create_disk_1:
	@echo "  CREATE  $(DISK)"
	@dd if=/dev/zero of=$(DISK) bs=$(DISK_SIZE) count=1 $(STDOUT)

	@echo "  CREATE  $(DISK)/partition"
	@printf "o\nn\np\n1\n\n\na\nw\n"  | fdisk $(DISK) $(STDOUT)

create_disk_2:
# Note that eval is executed here (before all statements)
# The mount has to be on /mnt since creating an own directory fails grub-install
	@echo "  FORMAT  $(DISK)/partition"
	$(eval DEVICE=$(shell sudo losetup -f -P --show $(DISK)))
	@sudo mkfs.ext4 -F $(DEVICE)p1 $(STDOUT)

	@echo "  INSTALL $(DISK)/grub"
	@sudo mount $(DEVICE)p1 /mnt

	@sudo cp --preserve=all --recursive root/* /mnt/
	@sudo find /mnt -user $(USER) -exec chown -h root {} +
	@sudo find /mnt -group $(USER) -exec chown -h :root {} +
	@sudo grub-install --target=i386-pc --root-directory=/mnt --no-floppy --modules="normal part_msdos ext2 multiboot" $(DEVICE) $(STDOUT)
	@sudo mkdir -p /mnt/boot/grub
	@echo "menuentry 'LINUX' {"                    | sudo tee    /mnt/boot/grub/grub.cfg $(STDOUT)
	@echo "	set root='(hd0,1)'"                    | sudo tee -a /mnt/boot/grub/grub.cfg $(STDOUT)
	@echo "	linux /boot/bzImage root=/dev/sda1 rw" | sudo tee -a /mnt/boot/grub/grub.cfg $(STDOUT)
	@echo "}"                                      | sudo tee -a /mnt/boot/grub/grub.cfg $(STDOUT)
	@sudo sync

	@sudo umount $(DEVICE)p1
	@sudo losetup -d $(DEVICE)

# ------------------------------------------------------------------------------

create_init: create_directories

	@if [ ! -f "$(ROOT)/sbin/init" ]; then                                        \
		echo "#!/bin/bash"              | tee    $(ROOT)/usr/sbin/init $(STDOUT); \
		echo ""                         | tee -a $(ROOT)/usr/sbin/init $(STDOUT); \
		echo "mount -t proc none /proc" | tee -a $(ROOT)/usr/sbin/init $(STDOUT); \
		echo "mount -t sysfs none /sys" | tee -a $(ROOT)/usr/sbin/init $(STDOUT); \
		echo ""                         | tee -a $(ROOT)/usr/sbin/init $(STDOUT); \
		echo "exec /bin/bash"           | tee -a $(ROOT)/usr/sbin/init $(STDOUT); \
		sudo chmod +x $(ROOT)/usr/sbin/init;                                      \
	fi

# ------------------------------------------------------------------------------

clean: clean_builds clean_disk clean_downloads clean_root

clean_builds:
	@echo "  CLEAN   builds"
	@rm -rf bash-build
	@rm -rf coreutils-build
	@rm -rf glibc-build
	@rm -rf util-linux-build
	@rm -rf nano-build
	@rm -rf ncurses-build
	@rm -rf util-linux-build

clean_disk:
	@echo "  CLEAN   disk"
	@rm -f $(DISK)

clean_downloads:
	@echo "  CLEAN   downloads"
	@rm -rf kernel
	@rm -rf bash
	@rm -rf coreutils
	@rm -rf glibc
	@rm -rf util-linux
	@rm -rf nano
	@rm -rf ncurses
	@rm -rf util-linux

clean_root:
	@echo "  CLEAN   $(ROOT)"
	@sudo rm -rf $(ROOT)

# ------------------------------------------------------------------------------

help:
	@echo "usage: make [MESSAGES=0 | MESSAGES=1] [gnu-linux | gnu-linux-ext | help | run]"
	@echo " "
	@echo "Download, build and run a minimal non-secure gnu-linux."
	@echo " "
	@echo "options:"
	@echo "  MESSAGES=0      do not show detailed logging"
	@echo "  MESSAGES=1      show detailed logging"
	@echo "  help            show this help message and exit"
	@echo "  gnu-linux       create a minimal system"
	@echo "  gnu-linux-ext   create a system with some extra apps and libs"
	@echo "  run             run the build gnu-linux in qemu"

# ------------------------------------------------------------------------------

run:
	@qemu-system-x86_64 -drive file=$(DISK),format=raw &
