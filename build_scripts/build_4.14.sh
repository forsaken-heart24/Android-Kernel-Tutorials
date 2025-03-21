#!/bin/bash

echo -e "\n[INFO]: BUILD STARTED..!\n"

#init submodules
git submodule init && git submodule update

export RDIR="$(pwd)"
export ARCH=arm64
export KBUILD_BUILD_USER="@ravindu644"

# Install the requirements for building the kernel when running the script for the first time
if [ ! -f ".requirements" ]; then
    sudo apt update && sudo apt install -y git device-tree-compiler lz4 xz-utils zlib1g-dev openjdk-17-jdk gcc g++ python3 python-is-python3 p7zip-full android-sdk-libsparse-utils erofs-utils \
        default-jdk git gnupg flex bison gperf build-essential zip curl libc6-dev libncurses-dev libx11-dev libreadline-dev libgl1 libgl1-mesa-dev \
        python3 make sudo gcc g++ bc grep tofrodos python3-markdown libxml2-utils xsltproc zlib1g-dev python-is-python3 libc6-dev libtinfo6 \
        make repo cpio kmod openssl libelf-dev pahole libssl-dev libarchive-tools zstd libyaml-dev --fix-missing && wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb && sudo dpkg -i libtinfo5_6.3-2ubuntu0.1_amd64.deb && touch .requirements
fi

# Create necessary directories
mkdir -p "${RDIR}/out" "${RDIR}/build" "${HOME}/toolchains"

# init clang-r383902b
if [ ! -d "${HOME}/toolchains/clang-r383902b" ]; then
    echo -e "\n[INFO] Cloning clang-r383902b...\n"
    mkdir -p "${HOME}/toolchains/clang-r383902b" && cd "${HOME}/toolchains/clang-r383902b"
    curl -LO "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/0e9e7035bf8ad42437c6156e5950eab13655b26c/clang-r383902b.tar.gz"
    tar -xf clang-r383902b.tar.gz && rm clang-r383902b.tar.gz
    cd "${RDIR}"
fi

# init aarch64-linux-android-4.9
if [ ! -d "${HOME}/toolchains/aarch64-linux-android-4.9-Linux-5.4" ]; then
    echo -e "\n[INFO] Cloning aarch64-linux-android-4.9...\n"
    mkdir -p "${HOME}/toolchains/aarch64-linux-android-4.9-Linux-5.4" && cd "${HOME}/toolchains/aarch64-linux-android-4.9-Linux-5.4"
    curl -LO "https://github.com/ravindu644/Android-Kernel-Tutorials/releases/download/toolchains/aarch64-linux-android-4.9-Linux-5.4.tar.gz"
    tar -xf aarch64-linux-android-4.9-Linux-5.4.tar.gz && rm aarch64-linux-android-4.9-Linux-5.4.tar.gz
    cd "${RDIR}"
fi

# Export toolchain paths
export PATH="${PATH}:${HOME}/toolchains/clang-r383902b/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOME}/clang-r383902b/lib:${HOME}/clang-r383902b/lib64"

# Set cross-compile environment variables
export BUILD_CROSS_COMPILE="${HOME}/toolchains/aarch64-linux-android-4.9-Linux-5.4/bin/aarch64-linux-android-"
export BUILD_CC="${HOME}/toolchains/clang-r383902b/bin/clang"

# Build options for the kernel
export BUILD_OPTIONS="
HOSTLDLIBS="-lyaml"
-C ${RDIR} \
O=${RDIR}/out \
-j$(nproc) \
ARCH=arm64 \
CROSS_COMPILE=${BUILD_CROSS_COMPILE} \
CC=${BUILD_CC} \
CLANG_TRIPLE=aarch64-linux-gnu- \
"

build_kernel(){
    # Make default configuration.
    # Replace 'your_defconfig' with the name of your kernel's defconfig
    make ${BUILD_OPTIONS} your_defconfig

    # Configure the kernel (GUI)
    make ${BUILD_OPTIONS} menuconfig

    # Build the kernel
    make ${BUILD_OPTIONS} Image || exit 1

    # Copy the built kernel to the build directory
    cp "${RDIR}/out/arch/arm64/boot/Image" "${RDIR}/build"

    echo -e "\n[INFO]: BUILD FINISHED..!"
}
build_kernel
