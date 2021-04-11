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

case $1 in
  --help) echo "usage: kernel.sh <command>"; exit 1
esac

# Set PATH
PARENT_DIR=$(pwd)
KERNEL_DIR="kernel"
CODENAME="ginkgo"
SOURCE=$PARENT_DIR/$KERNEL_DIR/$CODENAME
OUT=$PARENT_DIR/$KERNEL_DIR/out
mkdir -p $PARENT_DIR/$KERNEL_DIR/$CODENAME 2>/dev/null;

# Set Toolchain defaults
export CC="$PARENT_DIR/$KERNEL_DIR/clang/bin/clang"
export CLANG_TRIPLE="$PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android/bin/aarch64-maestro-linux-gnu-"
export CROSS_COMPILE="$PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android/bin/aarch64-maestro-linux-gnu-"
export CROSS_COMPILE_ARM32="$PARENT_DIR/$KERNEL_DIR/arm-maestro-linux-gnueabi/bin/arm-maestro-linux-gnueabi-"

# Set defaults
export CREDENTIALS="$1"
export CLONE="$1"
export COMPILE="$1"
export ANYKERNEL="$1"
export SERVER="$1"

# Set server credentials
if [ "$CREDENTIALS" == "creds" ]; then
  read -p "Enter user: " user
  read -p "Enter pass: " pass
  read -p "Enter host: " host
fi

# Clone sources
if [ "$CLONE" == "src" ]; then
  # Clone Toolchain Source
  git clone https://github.com/TheHitMan7/clang.git -b master $PARENT_DIR/$KERNEL_DIR/clang 2>/dev/null;
  git clone https://github.com/TheHitMan7/aarch64-maestro-linux-android.git -b master $PARENT_DIR/$KERNEL_DIR/aarch64-maestro-linux-android 2>/dev/null;
  git clone https://github.com/TheHitMan7/arm-maestro-linux-gnueabi.git -b master $PARENT_DIR/$KERNEL_DIR/arm-maestro-linux-gnueabi 2>/dev/null;
  # Clone Kernel Source
  read -p "Set Repository : " REPOSITORY && read -p "Set Branch     : " BRANCH
  git clone https://github.com/TheHitMan7/${REPOSITORY}.git -b ${BRANCH} $SOURCE 2>/dev/null;
  git clone https://github.com/TheHitMan7/AnyKernel3.git -b master $PARENT_DIR/$KERNEL_DIR/AnyKernel3 2>/dev/null;
fi

# Build kernel
if [ "$COMPILE" == "build" ]; then
  SOURCE=$SOURCE
  cd $SOURCE
  export ARCH=arm64
  export SUBARCH=arm64
  export LOCALVERSION=
  export KBUILD_BUILD_USER=TheHitMan
  export KBUILD_BUILD_HOST=ILLYRIA
  export KBUILD_COMPILER_STRING="$(${CC} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
  make O=$OUT ARCH=arm64 vendor/ginkgo-perf_defconfig
  make O=$OUT ARCH=arm64 \
              CC=$CC \
              CLANG_TRIPLE=$CLANG_TRIPLE \
              CROSS_COMPILE=$CROSS_COMPILE \
              CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
              -j$(nproc --all)
fi

# Re-build kernel
if [ "$COMPILE" == "ret" ]; then
  make O=$OUT ARCH=arm64 \
              CC=$CC \
              CLANG_TRIPLE=$CLANG_TRIPLE \
              CROSS_COMPILE=$CROSS_COMPILE \
              CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
              -j$(nproc --all)
fi

# Create AnyKernel ZIP
if [ "$ANYKERNEL" == "ak" ]; then
  cd $PARENT_DIR/$KERNEL_DIR
  KERN_IMG="out/arch/arm64/boot/Image.gz-dtb"
  read -p "Insert Zip File Token: " TOKEN
  date=`date +"%Y%m%d"`
  cp -f $KERN_IMG $PARENT_DIR/$KERNEL_DIR/AnyKernel3/Image.gz-dtb
  cd $PARENT_DIR/$KERNEL_DIR/AnyKernel3
  zip -r9 RIGEL-X.zip *
  mv $PARENT_DIR/$KERNEL_DIR/AnyKernel3/RIGEL-X.zip $PARENT_DIR/$KERNEL_DIR/RIGEL-X-$date-${TOKEN}.zip
  cd ../..
fi

# Upload to server
if [ "$SERVER" == "dh" ]; then
  cd $PARENT_DIR/$KERNEL_DIR
  file="RIGEL-X-$date-$TOKEN.zip"
  curl -T $file "ftp://${user}:${pass}@${host}/bitgapps.com/downloads/Android"
  cd ../..
fi
