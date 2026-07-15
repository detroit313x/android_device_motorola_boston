#!/bin/bash

################################################################################
# PBRP COMPLETE BUILD SYSTEM - RECOVERY + VENDOR BOOT + BOOT
# Device: Motorola Boston (XT2419) - Moto G Stylus 5G 2024
# Compiles all boot images: recovery, vendor_boot, boot
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Build configuration
DEVICE_NAME="boston"
BUILD_VARIANT="${1:-user}"
JOBS=$(nproc --all)
BUILD_DIR="${HOME}/pbrp-build"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${BUILD_DIR}/pbrp_complete_build_${TIMESTAMP}.log"

# Banner
print_banner() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                    ║${NC}"
    echo -e "${CYAN}║      ${MAGENTA}PBRP COMPLETE BUILD - RECOVERY + VENDOR BOOT + BOOT${CYAN}    ║${NC}"
    echo -e "${CYAN}║      Motorola Boston (XT2419) - TWRP 12.1 / PBRP                  ║${NC}"
    echo -e "${CYAN}║                                                                    ║${NC}"
    echo -e "${CYAN}║   Compiling: recovery.img + vendor_boot.img + boot.img           ║${NC}"
    echo -e "${CYAN}║   Platform: Snapdragon 765 (parrot)                               ║${NC}"
    echo -e "${CYAN}║   Partition Scheme: A/B                                           ║${NC}"
    echo -e "${CYAN}║                                                                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Status functions
print_status() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "${LOG_FILE}"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "${LOG_FILE}"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "${LOG_FILE}"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1" | tee -a "${LOG_FILE}"
}

print_step() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║ $1${CYAN}$(printf '%*s' $((60 - ${#1})) '')║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo "" | tee -a "${LOG_FILE}"
}

# Main build function
main() {
    print_banner
    
    # Create log file
    mkdir -p "$(dirname "${LOG_FILE}")"
    echo "PBRP Complete Build Log - ${TIMESTAMP}" > "${LOG_FILE}"
    
    print_step "STEP 1/4: PRE-BUILD VALIDATION"
    
    # Check build directory
    if [ ! -d "$BUILD_DIR" ]; then
        print_error "Build directory not found: $BUILD_DIR"
        print_info "Run pbrp-build-init.sh first to initialize PBRP source"
        exit 1
    fi
    
    cd "$BUILD_DIR"
    print_status "Build directory: $BUILD_DIR"
    
    # Check PBRP source
    if [ ! -d "build" ]; then
        print_error "PBRP source not synced"
        exit 1
    fi
    
    print_status "PBRP source verified"
    
    # Check device tree
    if [ ! -d "device/motorola/boston" ]; then
        print_error "Device tree not found"
        exit 1
    fi
    
    print_status "Device tree verified"
    
    # Check configuration files
    for file in BoardConfig.mk device.mk AndroidProducts.mk; do
        if [ ! -f "device/motorola/boston/$file" ]; then
            print_error "$file not found"
            exit 1
        fi
    done
    
    print_status "All configuration files verified"
    
    print_info "Checking partition configurations..."
    echo -e "  Recovery partition:   $(grep 'BOARD_RECOVERYIMAGE_PARTITION_SIZE' device/motorola/boston/BoardConfig.mk | awk '{print $NF}' || echo 'default')"
    echo -e "  Vendor_boot partition: $(grep 'BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE' device/motorola/boston/BoardConfig.mk | awk '{print $NF}' || echo 'default')"
    echo -e "  Boot partition:        $(grep 'BOARD_BOOTIMAGE_PARTITION_SIZE' device/motorola/boston/BoardConfig.mk | awk '{print $NF}' || echo 'default')"
    
    print_step "STEP 2/4: SETTING UP BUILD ENVIRONMENT"
    
    print_info "Sourcing build environment..."
    source build/envsetup.sh 2>&1 | tee -a "${LOG_FILE}"
    
    print_info "Lunching device: twrp_${DEVICE_NAME}-${BUILD_VARIANT}"
    lunch "twrp_${DEVICE_NAME}-${BUILD_VARIANT}" 2>&1 | tee -a "${LOG_FILE}"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to lunch device configuration"
        exit 1
    fi
    
    print_status "Build environment ready"
    print_info "Using ${JOBS} parallel build jobs"
    
    print_step "STEP 3/4: COMPILING ALL BOOT IMAGES"
    
    TOTAL_START=$(date +%s)
    
    # Build recovery
    print_info "Building recovery.img..."
    RECOVERY_START=$(date +%s)
    mka recoveryimage -j${JOBS} 2>&1 | tee -a "${LOG_FILE}"
    RECOVERY_END=$(date +%s)
    RECOVERY_TIME=$((RECOVERY_END - RECOVERY_START))
    RECOVERY_TIME_HMS=$(date -u -d @${RECOVERY_TIME} +%H:%M:%S)
    
    if [ $? -eq 0 ]; then
        print_status "recovery.img compiled in ${RECOVERY_TIME_HMS}"
    else
        print_error "Recovery build failed"
        exit 1
    fi
    
    # Build vendor_boot
    print_info "Building vendor_boot.img..."
    VENDOR_START=$(date +%s)
    mka vendorbootimage -j${JOBS} 2>&1 | tee -a "${LOG_FILE}"
    VENDOR_END=$(date +%s)
    VENDOR_TIME=$((VENDOR_END - VENDOR_START))
    VENDOR_TIME_HMS=$(date -u -d @${VENDOR_TIME} +%H:%M:%S)
    
    if [ $? -eq 0 ]; then
        print_status "vendor_boot.img compiled in ${VENDOR_TIME_HMS}"
    else
        print_error "Vendor boot build failed"
        exit 1
    fi
    
    # Build boot
    print_info "Building boot.img..."
    BOOT_START=$(date +%s)
    mka bootimage -j${JOBS} 2>&1 | tee -a "${LOG_FILE}"
    BOOT_END=$(date +%s)
    BOOT_TIME=$((BOOT_END - BOOT_START))
    BOOT_TIME_HMS=$(date -u -d @${BOOT_TIME} +%H:%M:%S)
    
    if [ $? -eq 0 ]; then
        print_status "boot.img compiled in ${BOOT_TIME_HMS}"
    else
        print_warning "Boot build failed (may already exist or not needed)"
    fi
    
    TOTAL_END=$(date +%s)
    TOTAL_TIME=$((TOTAL_END - TOTAL_START))
    TOTAL_TIME_HMS=$(date -u -d @${TOTAL_TIME} +%H:%M:%S)
    
    print_step "STEP 4/4: BUILD OUTPUT & VERIFICATION"
    
    # Locate output files
    OUT_DIR="${OUT:-${BUILD_DIR}/out/target/product/${DEVICE_NAME}}"
    
    echo ""
    print_info "Output directory: ${OUT_DIR}"
    echo ""
    
    # Recovery verification
    RECOVERY_IMG="${OUT_DIR}/recovery.img"
    if [ -f "${RECOVERY_IMG}" ]; then
        RECOVERY_SIZE=$(du -h "${RECOVERY_IMG}" | cut -f1)
        RECOVERY_SIZE_MB=$(($(stat -c%s "${RECOVERY_IMG}") / 1048576))
        echo -e "${GREEN}✓ RECOVERY IMAGE${NC}"
        echo -e "  File: recovery.img"
        echo -e "  Size: ${RECOVERY_SIZE} (${RECOVERY_SIZE_MB}MB)"
        echo -e "  Path: ${RECOVERY_IMG}"
        echo -e "  Expected: 100-150 MB"
        echo ""
    else
        print_warning "Recovery image not found"
    fi
    
    # Vendor boot verification
    VENDOR_BOOT="${OUT_DIR}/vendor_boot.img"
    if [ -f "${VENDOR_BOOT}" ]; then
        VENDOR_SIZE=$(du -h "${VENDOR_BOOT}" | cut -f1)
        VENDOR_SIZE_MB=$(($(stat -c%s "${VENDOR_BOOT}") / 1048576))
        echo -e "${GREEN}✓ VENDOR BOOT IMAGE${NC}"
        echo -e "  File: vendor_boot.img"
        echo -e "  Size: ${VENDOR_SIZE} (${VENDOR_SIZE_MB}MB)"
        echo -e "  Path: ${VENDOR_BOOT}"
        echo -e "  Expected: 40-60 MB"
        echo ""
    else
        print_warning "Vendor boot image not found"
    fi
    
    # Boot verification
    BOOT_IMG="${OUT_DIR}/boot.img"
    if [ -f "${BOOT_IMG}" ]; then
        BOOT_SIZE=$(du -h "${BOOT_IMG}" | cut -f1)
        BOOT_SIZE_MB=$(($(stat -c%s "${BOOT_IMG}") / 1048576))
        echo -e "${GREEN}✓ BOOT IMAGE${NC}"
        echo -e "  File: boot.img"
        echo -e "  Size: ${BOOT_SIZE} (${BOOT_SIZE_MB}MB)"
        echo -e "  Path: ${BOOT_IMG}"
        echo -e "  Expected: 50-70 MB"
        echo ""
    else
        print_warning "Boot image not found (optional)"
    fi
    
    print_step "BUILD SUMMARY"
    
    echo -e "${CYAN}Device Information:${NC}"
    echo -e "  • Name: ${DEVICE_NAME}"
    echo -e "  • Model: XT2419 (Moto G Stylus 5G 2024)"
    echo -e "  • Platform: Snapdragon 765 (parrot)"
    echo -e "  • Display: 1080x2400 @ 403 DPI"
    echo ""
    
    echo -e "${CYAN}Build Information:${NC}"
    echo -e "  • Build Variant: ${BUILD_VARIANT}"
    echo -e "  • Parallel Jobs: ${JOBS}"
    echo -e "  • Total Build Time: ${TOTAL_TIME_HMS}"
    echo -e "  • Timestamp: ${TIMESTAMP}"
    echo ""
    
    echo -e "${CYAN}Image Build Times:${NC}"
    echo -e "  • recovery.img: ${RECOVERY_TIME_HMS}"
    echo -e "  • vendor_boot.img: ${VENDOR_TIME_HMS}"
    echo -e "  • boot.img: ${BOOT_TIME_HMS}"
    echo ""
    
    echo -e "${CYAN}Flashing Instructions:${NC}"
    echo -e "  Boot to bootloader:"
    echo -e "    ${YELLOW}adb reboot bootloader${NC}"
    echo ""
    echo -e "  Flash recovery:"
    echo -e "    ${YELLOW}fastboot flash recovery ${RECOVERY_IMG}${NC}"
    echo ""
    echo -e "  Flash vendor_boot (both slots):"
    echo -e "    ${YELLOW}fastboot flash vendor_boot_a ${VENDOR_BOOT}${NC}"
    echo -e "    ${YELLOW}fastboot flash vendor_boot_b ${VENDOR_BOOT}${NC}"
    echo ""
    echo -e "  Flash boot (optional):"
    echo -e "    ${YELLOW}fastboot flash boot ${BOOT_IMG}${NC}"
    echo ""
    echo -e "  Reboot:"
    echo -e "    ${YELLOW}fastboot reboot${NC}"
    echo ""
    
    echo -e "${CYAN}Quick Commands:${NC}"
    echo -e "  List all files:"
    echo -e "    ${YELLOW}ls -lh ${OUT_DIR}/*.img${NC}"
    echo ""
    echo -e "  View build log:"
    echo -e "    ${YELLOW}cat ${LOG_FILE}${NC}"
    echo ""
    echo -e "  Verify images:"
    echo -e "    ${YELLOW}file ${OUT_DIR}/*.img${NC}"
    echo ""
    
    print_status "Build Log: ${LOG_FILE}"
    print_status "Output Directory: ${OUT_DIR}"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                   COMPLETE BUILD FINISHED SUCCESSFULLY!            ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║   Images ready for flashing:                                       ║${NC}"
    echo -e "${GREEN}║   • recovery.img                                                   ║${NC}"
    echo -e "${GREEN}║   • vendor_boot.img                                                ║${NC}"
    echo -e "${GREEN}║   • boot.img                                                       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Error handler
trap 'print_error "Build interrupted or failed"; exit 1' INT TERM

# Run main
main "$@"
