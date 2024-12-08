#!/bin/bash

mkdir -p images

export CROSS_COMPILE=riscv64-unknown-linux-gnu-
export ARCH=riscv

OBJDUMP=${CROSS_COMPILE}objdump
GDB=${CROSS_COMPILE}gdb

target=$1
case $target in
    "opensbi")
        cd opensbi
        make PLATFORM=generic FW_TEXT_START=0x80000000
        cp build/platform/generic/firmware/fw_jump.elf ../images
        cd ../images
        ${OBJDUMP} -dwx fw_jump.elf > fw_jump.asm
        ;;
    "opensbi-rebuild")
        cd opensbi
        rm build -rf
        make PLATFORM=generic FW_TEXT_START=0x80000000
        cp build/platform/generic/firmware/fw_jump.elf ../images
        cd ../images
        ${OBJDUMP} -dwx fw_jump.elf > fw_jump.asm
        ;;
    "linux-config")
        cd linux
        make defconfig
        make menuconfig
        ;;
    "linux-rebuild")
        cd linux
        make -j$(nproc)
        cp vmlinux ../images
        cp arch/riscv/boot/Image ../images
        ;;
    "qemu-run")
        qemu-system-riscv64 -M virt \
            -nographic \
            -bios ./images/fw_jump.elf
        ;;
    "qemu-stop")
        qemu-system-riscv64 -M virt \
            -nographic \
            -bios ./images/fw_jump.elf \
            -s -S
        ;;
    "qemu-dbg")
        ${GDB} -q \
            -iex "set auto-load safe-path ."
        ;;
    *)
        echo "ERROR Invalid target name"
        ;;
esac
