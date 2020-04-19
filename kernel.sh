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

# Compiler Version
AOSP_CLANG="10.0.6"
PROTON_CLANG="11.0.0"
GCC="10.0.1"

# Set defaults
SOURCE="$PARENT_DIR/$KERNEL_DIR/source"

# Set clang compile
compiler() {
  read -p "Do you want to compile kernel with AOSP clang Y/N ? " answer
  while true
  do
    case $answer in
     [yY]* ) export WHICH_CLANG=AOSP
           CC="$PARENT_DIR/$KERNEL_DIR/clang/bin/clang"
           CLANG_TRIPLE="$PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android/bin/aarch64-maestro-linux-gnu-"
           CROSS_COMPILE="$PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android/bin/aarch64-maestro-linux-gnu-"
           CROSS_COMPILE_ARM32="$PARENT_DIR/$KERNEL_DIR/arm-maestro-linux-gnueabi/bin/arm-maestro-linux-gnueabi-"
           AOSP="true"
           echo "Clang compiler : $WHICH_CLANG" && break;;
     [nN]* ) export WHICH_CLANG=PROTON
           CC="$PARENT_DIR/$KERNEL_DIR/proton-clang/bin/clang"
           CROSS_COMPILE="$PARENT_DIR/$KERNEL_DIR/proton-clang/bin/aarch64-linux-gnu-"
           CROSS_COMPILE_ARM32="$PARENT_DIR/$KERNEL_DIR/proton-clang/bin/arm-linux-gnueabi-"
           PROTON="true"
           echo "Clang compiler : $WHICH_CLANG" && break;;
    esac
  done
}
compiler;

# Set compiler
git clone https://github.com/TheHitMan7/clang.git -b master $PARENT_DIR/$KERNEL_DIR/clang 2>/dev/null;
git clone https://github.com/TheHitMan7/aarch64-maestro-linux-android.git -b master $PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android 2>/dev/null;
git clone https://github.com/TheHitMan7/arm-maestro-linux-gnueabi.git -b master $PARENT_DIR/$KERNEL_DIR/arm-maestro-linux-gnueabi 2>/dev/null;
git clone https://github.com/kdrag0n/proton-clang.git -b master $PARENT_DIR/$KERNEL_DIR/proton-clang --depth=1 2>/dev/null;

# Set kernel source
src() {
  read -p "Do you want to delete kernel source Y/N ? " answer
  while true
  do
    case $answer in
     [yY]* ) rm -rf $SOURCE
           echo "Kernel source deleted"
           break;;
     [nN]* ) break;;
    esac
  done
}
src;
git clone https://github.com/TheHitMan7/android_kernel_sm8150.git -b mainline $PARENT_DIR/$KERNEL_DIR/source 2>/dev/null;

# Set AnyKernel3
ak3_src() {
  read -p "Do you want to delete Anykernel ZIP Y/N ? " answer
  while true
  do
    case $answer in
     [yY]* ) rm -rf $PARENT_DIR/$KERNEL_DIR/AnyKernel3 && AK3="true"
           echo "Anykernel ZIP deleted"
           break;;
     [nN]* ) AK3="false"
           break;;
    esac
  done
}
ak3_src;
git clone https://github.com/TheHitMan7/AnyKernel3.git -b master $PARENT_DIR/$KERNEL_DIR/AnyKernel3 2>/dev/null;

# Set kernel DTB
dtb() {
  KERN_IMG="$out/arch/arm64/boot/Image.gz-dtb"
  KERN_DTB="$out/arch/arm64/boot/dts/qcom/trinket.dtb"
}

# Remove out directory
del() {
  rm -rf $out
  rm -rf $PARENT_DIR/$KERNEL_DIR/RIGEL-X-*.zip
  if [ "$AK3" = "false" ]; then
    rm -rf $PARENT_DIR/$KERNEL_DIR/AnyKernel3/Image.gz-dtb
  fi;
}
del;

# Build kernel
build() {
  SOURCE=$SOURCE
  cd $SOURCE
  export ARCH=arm64
  export SUBARCH=arm64
  export LOCALVERSION=RIGEL
  export KBUILD_BUILD_USER=TheHitMan
  export KBUILD_BUILD_HOST=ILLYRIA
  export KBUILD_COMPILER_STRING="$(${CC} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
  make O=$out ARCH=arm64 vendor/ginkgo-perf_defconfig
  if [ "$AOSP" = "true" ]; then
    make O=$out ARCH=arm64 \
                CC=$CC \
                CLANG_TRIPLE=$CLANG_TRIPLE \
                CROSS_COMPILE=$CROSS_COMPILE \
                CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
                -j$(nproc --all)
  fi;
  if [ "$PROTON" = "true" ]; then
    make O=$out ARCH=arm64 \
                CC=$CC \
                CROSS_COMPILE=$CROSS_COMPILE \
                CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
                -j$(nproc --all)
  fi;
}

# Retry on failed compilation
ret() {
  if [ "$AOSP" = "true" ]; then
    make O=$out ARCH=arm64 \
                CC=$CC \
                CLANG_TRIPLE=$CLANG_TRIPLE \
                CROSS_COMPILE=$CROSS_COMPILE \
                CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
                -j$(nproc --all)
  fi;
  if [ "$PROTON" = "true" ]; then
    make O=$out ARCH=arm64 \
                CC=$CC \
                CROSS_COMPILE=$CROSS_COMPILE \
                CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
                -j$(nproc --all)
  fi;
}

# Create flashable ZIP
zipfile() {
  date=`date +"%Y%m%d"`
  cp -f $KERN_IMG $PARENT_DIR/$KERNEL_DIR/AnyKernel3/Image.gz-dtb
  cd $PARENT_DIR/$KERNEL_DIR/AnyKernel3
  zip -r9 RIGEL-X.zip *
  mv $PARENT_DIR/$KERNEL_DIR/AnyKernel3/RIGEL-X.zip $PARENT_DIR/$KERNEL_DIR/RIGEL-X-$date.zip
  cd ../..
}

# Upload build to sourceforge
sf() {
  file="$PARENT_DIR/$KERNEL_DIR/*.zip"
  scp $file codex7@frs.sourceforge.net:/home/frs/project/rigel-kernel-android/Ginkgo
}

mka() {
  build;
  dtb;
  if [ -f "$KERN_IMG" ]; then
    zipfile;
    sf;
  fi;
}

retry() {
  ret;
  dtb;
  if [ -f "$KERN_IMG" ]; then
    zipfile;
    sf;
  fi;
}
