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
mkdir -p $PARENT_DIR/$KERNEL_DIR 2>/dev/null;

# Set defaults
SOURCE="$PARENT_DIR/$KERNEL_DIR/source"
CC="$PARENT_DIR/$KERNEL_DIR/clang-r377782b/bin/clang"
CLANG_TRIPLE="$PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android/bin/aarch64-maestro-linux-gnu-"
CROSS_COMPILE="$PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android/bin/aarch64-maestro-linux-gnu-"
CROSS_COMPILE_ARM32="$PARENT_DIR/$KERNEL_DIR/arm-maestro-linux-gnueabi/bin/arm-maestro-linux-gnueabi-"

# Set compiler
git clone https://github.com/TRINKET-ANDROID/clang-r377782b.git -b master $PARENT_DIR/$KERNEL_DIR/clang-r377782b 2>/dev/null;
git clone https://github.com/TheHitMan7/aarch64-linux-android.git -b master $PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android 2>/dev/null;
git clone https://github.com/TheHitMan7/arm-linux-gnueabi.git -b master $PARENT_DIR/$KERNEL_DIR/arm-maestro-linux-gnueabi 2>/dev/null;

# Set kernel source
git clone https://github.com/TheHitMan7/android_kernel_sm8150.git -b mainline $PARENT_DIR/$KERNEL_DIR/source 2>/dev/null;

# Set AnyKernel3
git clone https://github.com/TheHitMan7/AnyKernel3.git -b master $PARENT_DIR/$KERNEL_DIR/AnyKernel3 2>/dev/null;

# Set kernel DTB
dtb() {
  KERN_IMG="$out/arch/arm64/boot/Image.gz-dtb"
  KERN_DTB="$out/arch/arm64/boot/dts/qcom/trinket.dtb"
}

# Build kernel
build() {
  out=$PARENT_DIR/$KERNEL_DIR/out
  rm -rf $out
  SOURCE=$SOURCE
  cd $SOURCE
  export ARCH=arm64
  export SUBARCH=arm64
  export LOCALVERSION=RIGEL
  export KBUILD_BUILD_USER=TheHitMan
  export KBUILD_BUILD_HOST=ILLYRIA
  export KBUILD_COMPILER_STRING="$(${CC} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
  make O=$out ARCH=arm64 vendor/ginkgo-perf_defconfig
  make O=$out ARCH=arm64 \
              CC=$CC \
              CLANG_TRIPLE=$CLANG_TRIPLE \
              CROSS_COMPILE=$CROSS_COMPILE \
              CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
              -j$(nproc --all)
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

# Execute all functions
exec() {
  build;
  dtb;
  zipfile;
}
