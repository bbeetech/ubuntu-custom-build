# Stage 1: Build environment
FROM debian:12 AS builder

# Install required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    kernel-package \
    linux-source \
    libncurses-dev \
    flex \
    bison \
    openssl \
    libssl-dev \
    libelf-dev \
    debootstrap \
    xorriso \
    isolinux \
    syslinux-utils \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Extract kernel source
WORKDIR /usr/src
RUN tar xf linux-source-*.tar.xz

# Configure kernel
WORKDIR /usr/src/linux-source-*
COPY kernel_config .config

# Add your kernel configurations
RUN echo "CONFIG_ANDROID_BINDER_IPC=y" >> .config && \
    echo "CONFIG_ANDROID_BINDERFS=y" >> .config && \
    echo 'CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"' >> .config

# Build kernel
RUN make olddefconfig && \
    make -j$(nproc) deb-pkg

# Stage 2: Create ISO
FROM debian:12 AS iso-builder

# Copy kernel packages from builder
COPY --from=builder /usr/src/*.deb /tmp/

# Install required packages for ISO creation
RUN apt-get update && apt-get install -y \
    debootstrap \
    xorriso \
    isolinux \
    syslinux-utils \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /iso-build

# Create minimal Debian system
RUN debootstrap --arch=amd64 bookworm /iso-build/chroot

# Install custom kernel in chroot
RUN chroot /iso-build/chroot apt-get update && \
    dpkg -i /tmp/*.deb && \
    apt-get clean

# Create ISO structure
RUN mkdir -p /iso-build/iso/boot/grub && \
    cp /iso-build/chroot/boot/vmlinuz-* /iso-build/iso/boot/ && \
    cp /iso-build/chroot/boot/initrd.img-* /iso-build/iso/boot/

# Create GRUB configuration
RUN echo 'set timeout=5' > /iso-build/iso/boot/grub/grub.cfg && \
    echo 'set default=0' >> /iso-build/iso/boot/grub/grub.cfg && \
    echo '' >> /iso-build/iso/boot/grub/grub.cfg && \
    echo 'menuentry "Debian 12 Custom Kernel" {' >> /iso-build/iso/boot/grub/grub.cfg && \
    echo '    linux /boot/vmlinuz-* root=/dev/sda1 ro' >> /iso-build/iso/boot/grub/grub.cfg && \
    echo '    initrd /boot/initrd.img-*' >> /iso-build/iso/boot/grub/grub.cfg && \
    echo '}' >> /iso-build/iso/boot/grub/grub.cfg

# Create ISO
RUN grub-mkrescue -o /custom-debian.iso /iso-build/iso

# Final stage: Export ISO
FROM scratch
COPY --from=iso-builder /custom-debian.iso /