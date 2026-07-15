# 🚀 PBRP BUILD EXECUTION & DEPLOYMENT

**Build Status:** Ready for Compilation  
**Device:** Motorola Boston (XT2419)  
**Recovery:** TWRP 12.1 / PBRP Android 12.1  
**Branch:** `pbrp-build-setup`  
**Last Updated:** 2026-07-15

---

## ⚡ QUICK START (One Command)

```bash
bash ~/pbrp-build-init.sh
```

**That's it!** The script will:
- ✅ Check system resources
- ✅ Initialize PBRP source
- ✅ Sync all repositories (30-60 min)
- ✅ Clone device/vendor/kernel trees
- ✅ Build recovery image
- ✅ Generate output files & logs

---

## 📋 BUILD CHECKLIST

### Pre-Build Requirements
- [ ] Linux system (Ubuntu 18.04+ recommended)
- [ ] Minimum 8GB RAM (16GB+ recommended)
- [ ] 150GB+ free storage
- [ ] Git, Repo, Python3, Java11 installed
- [ ] Internet connection (for repo sync)

### Build Environment Setup
```bash
# 1. Install dependencies (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install -y \
    build-essential git curl repo python3 python3-dev \
    libssl-dev libffi-dev zip unzip ccache schedtool \
    pngquant imagemagick optipng java-11-openjdk java-11-openjdk-jdk

# 2. Clone this repository (optional - script handles it)
git clone https://github.com/detroit313x/android_device_motorola_boston.git

# 3. Run build script
cd android_device_motorola_boston
bash pbrp-build-init.sh
```

---

## 🏗️ BUILD PROCESS (6 Steps)

### **STEP 1: PRE-BUILD CHECKS** (2-3 minutes)
```
✓ System RAM verification (need 8GB minimum)
✓ Storage space check (need 150GB minimum)
✓ CPU cores detection
✓ Required tools verification (git, repo, python3, java)
```

**What happens if it fails:**
- Low RAM: Warning (may be slow but continues)
- Low storage: Error (build aborted - free up space)
- Missing tools: Error (install requirements)

---

### **STEP 2: INITIALIZE PBRP SOURCE** (1-2 minutes)
```bash
mkdir -p ~/pbrp-build
cd ~/pbrp-build
repo init -u https://github.com/PitchBlackRecoveryProject/manifest \
          -b android-12.1 \
          -g default,-device,-mips,-darwin,-notdefault
```

**Output:**
- Creates `.repo/` directory structure
- Initializes manifest
- Ready for sync

---

### **STEP 3: SYNC SOURCE CODE** (30-60 minutes) ⏳
```bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

**Downloads (~80-100GB):**
- PBRP framework & build system
- Android 12.1 source code
- Device-independent components
- Recovery-specific modules

**Progress shown:**
- Real-time sync percentage
- Project count
- Transfer speed

---

### **STEP 4: CLONE DEVICE TREES** (5-10 minutes)
```bash
# Device tree (REQUIRED)
git clone https://github.com/detroit313x/android_device_motorola_boston.git \
          device/motorola/boston -b pbrp-build-setup

# Vendor tree (OPTIONAL - fallback to defaults if unavailable)
git clone https://github.com/PizzaG/android_vendor_motorola_boston.git \
          vendor/motorola/boston

# Kernel source (OPTIONAL - uses prebuilt if unavailable)
git clone https://github.com/PizzaG/android_kernel_motorola_parrot.git \
          kernel/motorola/parrot
```

---

### **STEP 5: BUILD ENVIRONMENT SETUP** (2-3 minutes)
```bash
source build/envsetup.sh
lunch twrp_boston-user
```

**Configures:**
- Build environment variables
- Device-specific settings
- Compilation flags
- Target architecture (arm64 + arm)
- Output directory

---

### **STEP 6: COMPILE RECOVERY IMAGE** (30-90 minutes) 🔨
```bash
mka recoveryimage -j$(nproc --all)
```

**Build tasks:**
- Compile kernel (if available)
- Build bootloader
- Compile TWRP recovery
- Create recovery ramdisk
- Package recovery image
- Generate boot signatures

---

## 📦 OUTPUT FILES

After successful build, files are at:
```
~/pbrp-build/out/target/product/boston/
```

### **Main Files**
| File | Size | Purpose |
|------|------|---------|
| **recovery.img** | 100-150 MB | Recovery partition image (MAIN FILE) |
| **boot.img** | 50-70 MB | Boot partition image |
| **vendor_boot.img** | 40-60 MB | Vendor boot partition |
| **system.img** | Varies | System partition (if included) |

### **Build Logs**
```
~/pbrp-build/pbrp_build_YYYYMMDD_HHMMSS.log
```

---

## ✅ DEPENDENCY VERIFICATION

The build script validates:

```bash
✓ System requirements (RAM, storage, CPU)
✓ Git repository (installed and accessible)
✓ Repo tool (installed and accessible)
✓ Python3 (version 3.6+)
✓ Java (JDK 11+)
✓ Build-essential tools (gcc, make, etc.)
✓ PBRP manifest (can be re-initialized)
✓ Device tree structure
✓ AndroidProducts.mk existence
✓ BoardConfig.mk configuration
✓ Output directory permissions
```

---

## 🔧 BUILD CONFIGURATION

### **Device Configuration**
```makefile
DEVICE_PATH := device/motorola/boston
TARGET_ARCH := arm64
TARGET_2ND_ARCH := arm
TARGET_BOARD_PLATFORM := parrot
DEVICE_RESOLUTION := 1080x2400
TARGET_SCREEN_DENSITY := 403
```

### **Recovery Configuration**
```makefile
TW_THEME := portrait_hdpi
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
BOARD_AVB_ENABLE := true
TARGET_RECOVERY_QCOM_RTC_FIX := true
```

### **Partition Configuration**
```makefile
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_BOOTIMAGE_PARTITION_SIZE := 134217728
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 134217728
BOARD_SUPER_PARTITION_SIZE := 9126805504
```

---

## 🐛 TROUBLESHOOTING

### **Problem: "Out of virtual memory"**
```bash
# Solution: Reduce parallel jobs
mka recoveryimage -j4  # instead of -j$(nproc --all)

# Or enable ccache
export USE_CCACHE=1
export CCACHE_SIZE=50G
```

### **Problem: "Could not find lunch combo"**
```bash
# Solution: Verify device tree
ls device/motorola/boston/AndroidProducts.mk
source build/envsetup.sh
lunch twrp_boston-user
```

### **Problem: "Permission denied" on output**
```bash
# Solution: Fix ownership
sudo chown -R $USER:$USER ~/pbrp-build/out/
```

### **Problem: Repo sync timeout**
```bash
# Solution: Resume sync
cd ~/pbrp-build
repo sync -c -j4 --force-sync
```

### **Problem: "Not enough space"**
```bash
# Solution: Free up storage
df -h  # Check available space
rm -rf ~/pbrp-build/out/  # Clean build artifacts (keep source)
```

---

## 📊 BUILD STATISTICS

| Metric | Value |
|--------|-------|
| **First Build Time** | 1-3 hours |
| **Rebuild Time** | 30-90 minutes |
| **Source Size** | 80-100 GB |
| **Build Output** | 5-10 GB |
| **RAM Required** | 8 GB minimum |
| **Storage Required** | 150 GB minimum |
| **CPU Cores** | 4+ recommended |

---

## 🔄 CONTINUOUS BUILDS

After first successful build, faster rebuilds:

```bash
cd ~/pbrp-build
source build/envsetup.sh
lunch twrp_boston-user
mka recoveryimage -j$(nproc --all)  # Much faster (~30-45 min)
```

Or use the build script again:
```bash
bash ~/pbrp-build-init.sh
```

---

## 📱 FLASHING RECOVERY

### **Via ADB/Fastboot**
```bash
# Connect device with USB debugging enabled
adb reboot bootloader

# Flash recovery
fastboot flash recovery ~/pbrp-build/out/target/product/boston/recovery.img

# Reboot
fastboot reboot
```

### **Via EDL Mode**
- Device supports Emergency Download Mode
- Use device-specific EDL tools
- PBRP supports EDL flashing

---

## 📝 BUILD LOGS

Each build generates detailed logs:

```bash
# View build log
cat ~/pbrp-build/pbrp_build_YYYYMMDD_HHMMSS.log

# Extract errors
grep -i "error" ~/pbrp-build/pbrp_build_YYYYMMDD_HHMMSS.log

# Full build log
less ~/pbrp-build/out/verbose.log
```

---

## 🔗 REPOSITORY STRUCTURE

```
pbrp-build-setup/
├── AndroidProducts.mk         # Product definitions
├── BoardConfig.mk             # Board configuration
├── device.mk                  # Device configuration
├── twrp_boston.mk            # PBRP product config
├── PBRP-BUILD.sh             # Simple build script
├── PBRP-SETUP.md             # Detailed setup guide
├── pbrp-build-init.sh        # Complete build init script
├── prebuilt/
│   ├── QUICK-START.txt       # Quick reference
│   └── kernel               # Prebuilt kernel
└── recovery/                 # Recovery configuration
    └── root/
        └── system/etc/recovery.fstab
```

---

## ✨ FEATURES

### **Device Support**
- ✅ Motorola Moto G Stylus 5G 2024 (XT2419)
- ✅ Snapdragon 765 (parrot platform)
- ✅ 1080x2400 display @ 403 DPI
- ✅ A/B partition scheme
- ✅ File-Based Encryption (FBE)

### **Recovery Features**
- ✅ Full backup/restore support
- ✅ Advanced partitioning
- ✅ ADB sideload
- ✅ FastbootD support
- ✅ USB mass storage
- ✅ EDL mode support
- ✅ Multiple filesystems (F2FS, EROFS, EXT4)

---

## 🎯 NEXT STEPS AFTER BUILD

1. **Verify Output**
   ```bash
   ls -lh ~/pbrp-build/out/target/product/boston/recovery.img
   file ~/pbrp-build/out/target/product/boston/recovery.img
   ```

2. **Backup Original Recovery**
   ```bash
   adb pull /dev/block/by-name/recovery ./recovery.img.bak
   ```

3. **Flash Recovery**
   ```bash
   adb reboot bootloader
   fastboot flash recovery ~/pbrp-build/out/target/product/boston/recovery.img
   fastboot reboot
   ```

4. **Boot into Recovery**
   - Power off device
   - Hold Power + Volume Up
   - Select Recovery from menu

---

## 📞 SUPPORT

**Issue with build?**
- Check: [detroit313x/android_device_motorola_boston/issues](https://github.com/detroit313x/android_device_motorola_boston/issues)
- Contact: PizzaG (tree maintainer)

**PBRP specific issues?**
- Visit: [PBRP GitHub](https://github.com/PitchBlackRecoveryProject)

**General Android?**
- Check: [AOSP Documentation](https://source.android.com)

---

## 🎉 BUILD COMPLETE!

Your PBRP recovery image is ready for flashing!

**Remember:**
- Test in safe environment first
- Keep backups of original recovery
- Follow device-specific flashing procedures
- Join PBRP community for support

Good luck! 🚀

---

**Build prepared by:** detroit313x  
**Device tree maintainer:** PizzaG  
**Recovery:** TWRP 12.1 / PBRP  
**Last updated:** 2026-07-15
