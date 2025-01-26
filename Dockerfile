FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-aarch64-linux-gnu \
    libncurses-dev \
    bison \
    flex \
    libssl-dev \
    bc \
    qemu-utils \
    wget \
    git \
    cpio \
    python3 \
    debootstrap \
    systemd \
    initramfs-tools \
    e2fsprogs \
    parted \
    dosfstools \
    uuid-runtime \
    grub-efi-arm64 \
    xz-utils \
    kmod \
    sudo \
    netplan.io \
    debian-archive-keyring \
    curl \
    ca-certificates \
    gnupg \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy custom kernel config
COPY kernel-config /build/kernel-config