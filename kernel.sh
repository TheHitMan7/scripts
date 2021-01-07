#!/bin/bash
#
# Copyright (C) 2020 TheHitMan7 (Kartik Verma)
#
# Kernel Build Script

# Clone this script using following commands
# curl https://raw.githubusercontent.com/TheHitMan7/scripts/master/kernel.sh > kernel.sh
#
# Build kernel using following commands
# chmod +x kernel.sh
# . kernel.sh

# Set PATH
PARENT_DIR=$(pwd)
KERNEL_DIR="kernel"
out=$PARENT_DIR/$KERNEL_DIR/out
mkdir -p $PARENT_DIR/$KERNEL_DIR 2>/dev/null;

function credentials() {
  read -p "Enter user: " user
  read -p "Enter pass: " pass
  read -p "Enter host: " host
}
credentials

function device() {
  read -p "Select device for kernel compile (G)inkgo/(C)urtana ? " answer
  while true
  do
    case $answer in
     [gG]* ) export WHICH_DEVICE=ginkgo
           echo "Device selected : $WHICH_DEVICE" && break;;
     [cC]* ) export WHICH_DEVICE=curtana
           echo "Device selected : $WHICH_DEVICE" && break;;
    esac
  done
}
device

# Set compiler
function compiler() {
  read -p "Do you want to compile kernel with AOSP clang Y/N ? " answer
  while true
  do
    case $answer in
     [yY]* ) export WHICH_CLANG=AOSP
           CC="$PARENT_DIR/$KERNEL_DIR/clang/bin/clang"
           CLANG_TRIPLE="$PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android/bin/aarch64-maestro-linux-gnu-"
           CROSS_COMPILE="$PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android/bin/aarch64-maestro-linux-gnu-"
           CROSS_COMPILE_ARM32="$PARENT_DIR/$KERNEL_DIR/arm-maestro-linux-gnueabi/bin/arm-maestro-linux-gnueabi-"
           echo "Clang compiler : $WHICH_CLANG" && break;;
     [nN]* ) export WHICH_CLANG=PROTON
           CC="$PARENT_DIR/$KERNEL_DIR/proton-clang/bin/clang"
           CROSS_COMPILE="$PARENT_DIR/$KERNEL_DIR/proton-clang/bin/aarch64-linux-gnu-"
           CROSS_COMPILE_ARM32="$PARENT_DIR/$KERNEL_DIR/proton-clang/bin/arm-linux-gnueabi-"
           echo "Clang compiler : $WHICH_CLANG" && break;;
    esac
  done
  if [ "$WHICH_CLANG" = "AOSP" ]; then
    git clone https://github.com/TheHitMan7/clang.git -b master $PARENT_DIR/$KERNEL_DIR/clang 2>/dev/null;
    git clone https://github.com/TheHitMan7/aarch64-maestro-linux-android.git -b master $PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android 2>/dev/null;
    git clone https://github.com/TheHitMan7/arm-maestro-linux-gnueabi.git -b master $PARENT_DIR/$KERNEL_DIR/arm-maestro-linux-gnueabi 2>/dev/null;
  fi
  if [ "$WHICH_CLANG" = "PROTON" ]; then
    git clone https://github.com/kdrag0n/proton-clang.git -b master $PARENT_DIR/$KERNEL_DIR/proton-clang --depth=1 2>/dev/null;
  fi
}
compiler

# Set kernel source
function branch() {
  read -p "Source branch: " BRANCH
}
branch

function kernel_source() {
  SOURCE="$PARENT_DIR/$KERNEL_DIR/${WHICH_DEVICE}"
  read -p "Do you want to delete kernel source Y/N ? " answer
  while true
  do
    case $answer in
     [yY]* ) rm -rf $SOURCE && echo "Kernel source deleted"
           if [ "$WHICH_DEVICE" = "ginkgo" ]; then
             echo "Cloning ginkgo kernel source"
             git clone https://github.com/TheHitMan7/android_kernel_sm6125.git -b ${BRANCH} $SOURCE 2>/dev/null;
           fi;
           if [ "$WHICH_DEVICE" = "curtana" ]; then
             echo "Cloning curtana kernel source"
             git clone https://github.com/TheHitMan7/android_kernel_sm7125.git -b ${BRANCH} $SOURCE 2>/dev/null;
           fi;
           break;;
     [nN]* ) break;;
    esac
  done
}
kernel_source

# Set AnyKernel3
function ak3_source() {
  read -p "Do you want to delete Anykernel ZIP Y/N ? " answer
  while true
  do
    case $answer in
     [yY]* ) rm -rf $PARENT_DIR/$KERNEL_DIR/AnyKernel3 && AK3="true"
           echo "Anykernel ZIP deleted"
           git clone https://github.com/TheHitMan7/AnyKernel3.git -b master $PARENT_DIR/$KERNEL_DIR/AnyKernel3 2>/dev/null;
           break;;
     [nN]* ) AK3="false"
           break;;
    esac
  done
}
ak3_source

# Set kernel DTB
function dtb() {
  KERN_IMG="$out/arch/arm64/boot/Image.gz-dtb"
  if [ "$WHICH_DEVICE" = "ginkgo" ]; then
    KERN_DTB_TRINKET="$out/arch/arm64/boot/dts/qcom/trinket.dtb"
  fi;
  if [ "$WHICH_DEVICE" = "curtana" ]; then
    KERN_DTB_ATOLL="$out/arch/arm64/boot/dts/qcom/atoll.dtb"
  fi;
}

# Remove out directory
function del() {
  rm -rf $out
  rm -rf $PARENT_DIR/$KERNEL_DIR/RIGEL-X-*.zip
  if [ "$AK3" = "false" ]; then
    rm -rf $PARENT_DIR/$KERNEL_DIR/AnyKernel3/Image.gz-dtb
  fi;
}

# Build kernel
function build() {
  SOURCE=$SOURCE
  cd $SOURCE
  export ARCH=arm64
  export SUBARCH=arm64
  export LOCALVERSION=RIGEL
  export KBUILD_BUILD_USER=TheHitMan
  export KBUILD_BUILD_HOST=ILLYRIA
  export KBUILD_COMPILER_STRING="$(${CC} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
  if [ "$WHICH_CLANG" = "PROTON" ]; then
    export PATH="$PARENT_DIR/$KERNEL_DIR/proton-clang/bin:$PATH"
  fi;
  if [ "$WHICH_DEVICE" = "ginkgo" ]; then
    make O=$out ARCH=arm64 vendor/ginkgo-perf_defconfig
  fi;
  if [ "$WHICH_DEVICE" = "curtana" ]; then
    make O=$out ARCH=arm64 vendor/curtana-perf_defconfig
  fi;
  if [ "$WHICH_CLANG" = "AOSP" ]; then
    make O=$out ARCH=arm64 \
                CC=$CC \
                CLANG_TRIPLE=$CLANG_TRIPLE \
                CROSS_COMPILE=$CROSS_COMPILE \
                CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
                -j$(nproc --all)
  fi;
  if [ "$WHICH_CLANG" = "PROTON" ]; then
    make O=$out ARCH=arm64 \
                CC=$CC \
                LD=ld.lld \
                AR=llvm-ar \
                AS=llvm-as \
                NM=llvm-nm \
                OBJCOPY=llvm-objcopy \
                OBJDUMP=llvm-objdump \
                STRIP=llvm-strip \
                CROSS_COMPILE=$CROSS_COMPILE \
                CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
                -j$(nproc --all)
  fi;
}

# Retry on failed compilation
function ret() {
  if [ "$WHICH_CLANG" = "AOSP" ]; then
    make O=$out ARCH=arm64 \
                CC=$CC \
                CLANG_TRIPLE=$CLANG_TRIPLE \
                CROSS_COMPILE=$CROSS_COMPILE \
                CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
                -j$(nproc --all)
  fi;
  if [ "$WHICH_CLANG" = "PROTON" ]; then
    make O=$out ARCH=arm64 \
                CC=$CC \
                LD=ld.lld \
                AR=llvm-ar \
                AS=llvm-as \
                NM=llvm-nm \
                OBJCOPY=llvm-objcopy \
                OBJDUMP=llvm-objdump \
                STRIP=llvm-strip \
                CROSS_COMPILE=$CROSS_COMPILE \
                CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
                -j$(nproc --all)
  fi;
}

# Create flashable ZIP
function token() {
  read -p "Insert zip file token: " TOKEN
}

function zipfile() {
  date=`date +"%Y%m%d"`
  cp -f $KERN_IMG $PARENT_DIR/$KERNEL_DIR/AnyKernel3/Image.gz-dtb
  cd $PARENT_DIR/$KERNEL_DIR/AnyKernel3
  zip -r9 RIGEL-X.zip *
  mv $PARENT_DIR/$KERNEL_DIR/AnyKernel3/RIGEL-X.zip $PARENT_DIR/$KERNEL_DIR/RIGEL-X-$date-${TOKEN}.zip
  cd ../..
}

# Upload to server
function cf() {
  cd $PARENT_DIR/$KERNEL_DIR
  file="RIGEL-X-$date-$TOKEN.zip"
  scp $file ${user}@${host}:/home/dh_ddbfeb/bitgapps.com/downloads/Android
  cd ../..
}

function mka() {
  del
  build;
  dtb;
  if [ -f "$KERN_IMG" ]; then
    token;
    zipfile;
    cf;
  fi;
}

function retry() {
  ret;
  dtb;
  if [ -f "$KERN_IMG" ]; then
    token;
    zipfile;
    cf;
  fi;
}
