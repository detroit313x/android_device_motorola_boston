#!/bin/bash

################################################################################
# PBRP VENDOR BOOT BUILD SCRIPT - FIXED VERSION
# Device: Motorola Boston (XT2419) - Moto G Stylus 5G 2024
# Compiles vendor_boot image for A/B partition scheme
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
LOG_FILE="${BUILD_DIR}/vendor_boot_build_${TIMESTAMP}.log"

# Banner
print_banner() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                    ║${NC}"
    echo -e "${CYAN}║   ${MAGENTA}PBRP VENDOR BOOT BUILD - MOTOROLA BOSTON${CYAN}                    ║${NC}"
    echo -e "${CYAN}║                                                                    ║${NC}"
    echo -e "${CYAN}║   Device: Motorola Moto G Stylus 5G 2024 (XT2419)                 ║${NC}"
    echo -e "${CYAN}║   Partition: vendor_boot (100 MB, A/B slots)                      ║${NC}"
    echo -e "${CYAN}║   Platform: Snapdragon 765 (parrot)                               ║${NC}"
    echo -e "${CYAN}║   Recovery: TWRP 12.1 / PBRP                                      ║${NC}"
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
    echo "PBRP Vendor Boot Build Log - ${TIMESTAMP}" > "${LOG_FILE}"
    
    print_step "STEP 1/6: PRE-BUILD VALIDATION"
    
    # Check build directory
    if [ ! -d "$BUILD_DIR" ]; then
        print_error "Build directory not found: $BUILD_DIR"
        print_info "Run pbrp-build-init.sh first to initialize PBRP source"
        exit 1
    fi
    
    cd "$BUILD_DIR"
    print_status "Build directory verified: $BUILD_DIR"
    
    # Check PBRP source
    if [ ! -d "build" ]; then
        print_error "PBRP source not synced. Run pbrp-build-init.sh first"
        exit 1
    fi
    
    print_status "PBRP source verified"
    
    # Check device tree
    if [ ! -d "device/motorola/boston" ]; then
        print_error "Device tree not found"
        exit 1
    fi
    
    print_status "Device tree verified"
    
    # Check BoardConfig.mk
    if [ ! -f "device/motorola/boston/BoardConfig.mk" ]; then
        print_error "BoardConfig.mk not found"
        exit 1
    fi
    
    print_status "BoardConfig.mk verified"
    
    print_step "STEP 2/6: SYSTEM RESOURCE CHECK"
    
    # Check RAM
    TOTAL_RAM=$(free -g 2>/dev/null | awk 'NR==2 {print $2}' || echo "0")
    print_info "System RAM: ${TOTAL_RAM}GB"
    
    # Check storage
    AVAILABLE_SPACE=$(df -BG "${BUILD_DIR}" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
    print_info "Available storage: ${AVAILABLE_SPACE}GB"
    
    if [ "$AVAILABLE_SPACE" -lt 20 ]; then
        print_warning "Low storage space available (${AVAILABLE_SPACE}GB)"
    else
        print_status "Sufficient storage available"
    fi
    
    print_info "Using $JOBS parallel jobs"
    
    print_step "STEP 3/6: BUILD ENVIRONMENT SETUP"
    
    print_info "Sourcing build environment..."
    if ! source build/envsetup.sh 2>&1 | tee -a "${LOG_FILE}"; then
        print_error "Failed to source build environment"
        exit 1
    fi
    
    print_info "Lunching device: twrp_${DEVICE_NAME}-${BUILD_VARIANT}"
    if ! lunch "twrp_${DEVICE_NAME}-${BUILD_VARIANT}" 2>&1 | tee -a "${LOG_FILE}"; then
        print_error "Failed to lunch device"
        exit 1
    fi
    
    print_status "Build environment ready"
    
    print_step "STEP 4/6: VENDOR BOOT COMPILATION"
    
    print_info "Starting vendor_boot image compilation..."
    print_info "Build variant: ${BUILD_VARIANT}"
    print_info "Parallel jobs: ${JOBS}"
    print_info "Device: ${DEVICE_NAME} (boston)"
    print_info "Estimated time: 5-15 minutes"
    echo ""
    
    BUILD_START=$(date +%s)
    
    # Build vendor_boot
    if ! mka vendorbootimage -j${JOBS} 2>&1 | tee -a "${LOG_FILE}"; then
        print_error "Vendor boot build failed"
        exit 1
    fi
    
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    BUILD_TIME_HMS=$(date -u -d @${BUILD_TIME} +%H:%M:%S)
    
    echo ""
    print_status "Vendor boot image compiled successfully in ${BUILD_TIME_HMS}"
    
    print_step "STEP 5/6: OUTPUT VERIFICATION"
    
    # Locate output files
    OUT_DIR="${OUT:-${BUILD_DIR}/out/target/product/${DEVICE_NAME}}"
    VENDOR_BOOT="${OUT_DIR}/vendor_boot.img"
    
    echo ""
    
    if [ -f "${VENDOR_BOOT}" ]; then
        VENDOR_SIZE=$(du -h "${VENDOR_BOOT}" | cut -f1)
        VENDOR_SIZE_BYTES=$(stat -c%s "${VENDOR_BOOT}" 2>/dev/null || stat -f%z "${VENDOR_BOOT}")
        VENDOR_SIZE_MB=$((VENDOR_SIZE_BYTES / 1048576))
        
        print_status "Vendor Boot Image Created"
        echo -e "  📂 Location: ${VENDOR_BOOT}"
        echo -e "  📊 Size: ${VENDOR_SIZE} (${VENDOR_SIZE_MB}MB)"
        echo -e "  ✓ Expected: 40-60 MB"
        
        # Verify file format
        if file "${VENDOR_BOOT}" | grep -q "Android"; then
            print_status "File format verified as Android image"
        fi
        
        # Verify size is reasonable
        if [ "$VENDOR_SIZE_MB" -ge 30 ] && [ "$VENDOR_SIZE_MB" -le 200 ]; then
            print_status "Vendor boot size verified"
        else
            print_warning "Vendor boot size unusual: ${VENDOR_SIZE_MB}MB (expected 40-60MB)"
        fi
    else
        print_error "Vendor boot image not found at: ${VENDOR_BOOT}"
        echo "Searching for vendor boot images..."
        find "${OUT_DIR}" -name "vendor_boot*.img" 2>/dev/null || echo "  No vendor_boot images found"
        exit 1
    fi
    
    echo ""
    
    print_step "STEP 6/6: BUILD SUMMARY & NEXT STEPS"
    
    echo -e "${CYAN}Device Information:${NC}"
    echo -e "  🔹 Name: ${DEVICE_NAME}"
    echo -e "  🔹 Model: XT2419 (Moto G Stylus 5G 2024)"
    echo -e "  🔹 Platform: Snapdragon 765 (parrot)"
    echo -e "  🔹 Display: 1080x2400 @ 403 DPI"
    echo ""
    
    echo -e "${CYAN}Build Information:${NC}"
    echo -e "  🔹 Image Type: vendor_boot"
    echo -e "  🔹 Partition: vendor_boot (100 MB)"
    echo -e "  🔹 Slots: A/B (dual slots)"
    echo -e "  🔹 Build Variant: ${BUILD_VARIANT}"
    echo -e "  🔹 Build Time: ${BUILD_TIME_HMS}"
    echo -e "  🔹 Timestamp: ${TIMESTAMP}"
    echo ""
    
    echo -e "${CYAN}Output Files:${NC}"
    echo -e "  📦 Vendor Boot: ${VENDOR_BOOT}"
    echo -e "  📋 Build Log: ${LOG_FILE}"
    echo -e "  📂 Output Dir: ${OUT_DIR}"
    echo ""
    
    echo -e "${CYAN}Flashing Instructions:${NC}"
    echo -e "  1️⃣ Connect device via USB"
    echo -e "  2️⃣ Boot to bootloader: ${YELLOW}adb reboot bootloader${NC}"
    echo -e "  3️⃣ Flash vendor_boot: ${YELLOW}fastboot flash vendor_boot_a ${VENDOR_BOOT}${NC}"
    echo -e "  4️⃣ Flash slot B: ${YELLOW}fastboot flash vendor_boot_b ${VENDOR_BOOT}${NC}"
    echo -e "  5️⃣ Reboot: ${YELLOW}fastboot reboot${NC}"
    echo ""
    
    echo -e "${CYAN}Verification Commands:${NC}"
    echo -e "  ${YELLOW}fastboot getvar vendor_boot_size${NC}"
    echo -e "  ${YELLOW}adb shell getprop ro.vendor.boot.serialno${NC}"
    echo ""
    
    print_status "Build log: ${LOG_FILE}"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║               ✅ VENDOR BOOT BUILD COMPLETED! ✅                   ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║   vendor_boot.img is ready for flashing!                           ║${NC}"
    echo -e "${GREEN}║   Size: ${VENDOR_SIZE} | Time: ${BUILD_TIME_HMS}                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Error handler
trap 'print_error "Build interrupted or failed"; exit 1' INT TERM

# Run main
main "$@"
