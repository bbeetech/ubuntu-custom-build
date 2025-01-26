# Base image with required tools
FROM ubuntu:22.04

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
    python3

# Set working directory
WORKDIR /build

# Copy custom kernel config (if available)
COPY kernel-config /build/kernel-config
