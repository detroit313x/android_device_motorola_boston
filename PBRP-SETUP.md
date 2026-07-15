# PBRP Build Guide - Motorola Boston

**Device:** Motorola Moto G Stylus 5G 2024 (boston)  
**Recovery:** Pitch Black Recovery Project (PBRP)  
**Android Version:** 12.1  
**Platform:** Snapdragon 765 (parrot)

---

## Prerequisites

### System Requirements
- **OS:** Linux (Ubuntu 18.04 LTS or newer recommended)
- **RAM:** Minimum 8GB (16GB+ recommended)
- **Storage:** At least 150GB free space
- **Python:** Python 3.6 or later
- **Git:** Latest version

### Required Packages
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    curl \
    repo \
    python3 \
    python3-dev \
    libssl-dev \
    libffi-dev \
    zip \
    unzip \
    ccache \
    schedtool \
    pngquant \
    imagemagick \
    optipng \
    java-11-openjdk \
    java-11-openjdk-jdk
```

---

## Setup Instructions

### 1. Initialize PBRP Source Repository

```bash
# Create working directory
mkdir -p ~/pbrp-build
cd ~/pbrp-build

# Initialize PBRP manifest (Android 12.1)
repo init -u https://github.com/PitchBlackRecoveryProject/manifest -b android-12.1 -g default,-device,-mips,-darwin,-notdefault

# Sync repository (this takes time - 30-60 minutes)
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

### 2. Clone Device Tree

```bash
# Clone into proper location
git clone https://github.com/detroit313x/android_device_motorola_boston.git \
    device/motorola/boston -b pbrp-build-setup
```

### 3. Clone Vendor Tree (if available)

```bash
# You may need vendor blobs
# Check if upstream has vendor tree
git clone https://github.com/PizzaG/android_vendor_motorola_boston.git \
    vendor/motorola/boston 2>/dev/null || echo "Vendor tree not found - will use defaults"
```

### 4. Clone Kernel Source (if available)

```bash
# Check if kernel source exists
git clone https://github.com/PizzaG/android_kernel_motorola_parrot.git \
    kernel/motorola/parrot 2>/dev/null || echo "Kernel source not available - using prebuilt"
```

---

## Build Steps

### Option 1: Using Build Script (Recommended)

```bash
# Make script executable
chmod +x device/motorola/boston/PBRP-BUILD.sh

# Run the build script
cd ~/pbrp-build
./device/motorola/boston/PBRP-BUILD.sh
```

### Option 2: Manual Build Steps

```bash
cd ~/pbrp-build

# Source environment
source build/envsetup.sh

# Lunch device
lunch twrp_boston-user
# For debug build: lunch twrp_boston-userdebug
# For engineering build: lunch twrp_boston-eng

# Build recovery image
mka recoveryimage -j$(nproc --all)

# Full PBRP build (optional)
# mka pbrp -j$(nproc --all)
```

---

## Build Output

After successful compilation, find images at:

```
out/target/product/boston/recovery.img      # Recovery image
out/target/product/boston/boot.img          # Boot image
out/target/product/boston/vendor_boot.img   # Vendor boot image
```

### File Sizes (Typical)
- **recovery.img:** ~100-150 MB
- **boot.img:** ~50-70 MB
- **vendor_boot.img:** ~40-60 MB

---

## Device Configuration Summary

### Hardware Specs
- **Device Name:** boston
- **Model:** XT2419 (Moto G Stylus 5G 2024)
- **SoC:** Snapdragon 765 (parrot)
- **RAM:** Typically 6-8GB
- **Storage:** 128-256GB

### Recovery Features
- **Bootloader:** UEFI-based
- **Encryption:** Full FBE support
- **A/B Partitions:** Yes
- **Display:** 1080x2400 (403 DPI)
- **USB:** FastbootD + Mass Storage
- **Theme:** Portrait HDPI

### Partition Layout
```
/boot                  - Boot partition
/recovery              - Recovery partition
/system                - System partition (EROFS/EXT4)
/product               - Product partition (EROFS/EXT4)
/system_ext            - System Extension (EROFS/EXT4)
/vendor                - Vendor partition (EROFS/EXT4)
/vendor_dlkm           - Vendor DLKM (EROFS/EXT4)
/vendor_boot           - Vendor Boot
/data                  - User data (F2FS)
/metadata              - Metadata
/persist               - Persist partition
/misc                  - Misc partition (EMMC)
/modem                 - Modem firmware
/dsp                   - DSP firmware
/bluetooth             - Bluetooth firmware
/fsg                   - FSG (Firmware Security Group)
```

---

## Troubleshooting

### Build Fails at Lunch

**Error:** `Could not find lunch combo twrp_boston-user`

**Solution:**
```bash
# Ensure device tree is in correct location
ls -la device/motorola/boston/

# Check AndroidProducts.mk exists
ls -la device/motorola/boston/AndroidProducts.mk

# Re-source environment
source build/envsetup.sh
```

### Out of Memory

**Error:** `cc1plus: out of virtual memory` or similar

**Solution:**
```bash
# Reduce parallel jobs
mka recoveryimage -j4    # Use 4 jobs instead of $(nproc --all)

# Or enable ccache
export USE_CCACHE=1
export CCACHE_SIZE=50G  # Adjust as needed
```

### Missing Vendor Files

**Error:** Build fails with missing vendor partition errors

**Solution:**
```bash
# These may be handled by PBRP's recovery updater
# Device tree includes proper partition mapping
# Vendor files may not be needed for recovery-only build
```

### Permission Denied on Output

**Error:** `Permission denied` when accessing recovery.img

**Solution:**
```bash
sudo chown -R $USER:$USER out/
```

---

## Flashing the Recovery

### Using ADB (Requires enabled USB Debugging)
```bash
adb reboot bootloader
fastboot flash recovery out/target/product/boston/recovery.img
fastboot reboot
```

### Using EDL Mode (Emergency Download Mode)
```bash
# Device supports EDL mode
# Use appropriate EDL tool or PBRP's edl_mode feature
```

---

## Additional Resources

- [PBRP Official GitHub](https://github.com/PitchBlackRecoveryProject)
- [Device Tree Upstream](https://github.com/PizzaG/android_device_motorola_boston)
- [Android Recovery Documentation](https://source.android.com/devices/bootloader/recovery-mode)
- [TWRP Device Requirements](https://twrp.me/devices/)

---

## Build Statistics

- **Device:** Motorola Boston (XT2419)
- **Tree Maintainer:** PizzaG
- **Recovery Version:** TWRP 12.1
- **Device Tree Version:** 0.1
- **Last Updated:** 2024

---

## Notes

1. First build may take 1-3 hours depending on system specs
2. Subsequent builds are faster due to ccache
3. Ensure secure boot is properly configured
4. Test in safe environment before flashing to device
5. Keep backups of original recovery before flashing

---

## Support

For issues specific to:
- **Device Tree:** File issues in [detroit313x/android_device_motorola_boston](https://github.com/detroit313x/android_device_motorola_boston)
- **PBRP:** Visit [PBRP GitHub](https://github.com/PitchBlackRecoveryProject)
- **General Android:** Check [AOSP Documentation](https://source.android.com)

Good luck with your build! 🚀
