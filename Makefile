#!/bin/bash

export MD := mkdir -p
export RM := rm -rf
export CP := cp -r

export ARCH := riscv
export CROSS_COMPILE := riscv64-unknown-linux-gnu-
export OBJDUMP = ${CROSS_COMPILE}objdump
export GDB := ${CROSS_COMPILE}gdb


.DEFAULT_GOAL: qemu-run
.PHONY: pre-build opensbi opensbi-rebuild linux-config linux-rebuild qemu-run qemu-stop qemu-dbg
#
# Target
#
pre-build:
	${MD} images

opensbi: pre-build
	cd opensbi && make PLATFORM=generic FW_TEXT_START=0x80000000
	cp opensbi/build/platform/generic/firmware/fw_jump.elf ./images
	cd ./images && ${OBJDUMP} -dwx fw_jump.elf > fw_jump.asm

opensbi-rebuild:
	cd opensbi && rm -rf build &&  make PLATFORM=generic FW_TEXT_START=0x80000000
	cp opensbi/build/platform/generic/firmware/fw_jump.elf ./images
	cd ./images && ${OBJDUMP} -dwx fw_jump.elf > fw_jump.asm

linux-config:
	cd linux && cp ../linux-patch/defconfig .config && ${MAKE} menuconfig

linux-rebuild: pre-build
	cd linux && ${MAKE} -j4
	cp linux/vmlinux ./images
	cp linux/arch/riscv/boot/Image ./images

qemu-run:
	qemu-system-riscv64 -M virt \
		-nographic \
		-bios ./images/fw_jump.elf \
		-kernel ./images/Image \
		-append "root=dev/ram0" \
		-initrd rootfs.cpio

qemu-stop:
	qemu-system-riscv64 -M virt \
		-nographic \
		-bios ./images/fw_jump.elf \
		-kernel ./images/Image \
		-append "root=dev/ram0" \
		-initrd rootfs.cpio \
		-s -S

qemu-dbg:
	${GDB} -q \
		-iex "set auto-load safe-path ."
