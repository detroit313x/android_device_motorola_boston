#!/bin/bash

################################################################################
# PBRP COMPLETE BUILD INITIALIZATION & COMPILATION SCRIPT
# Device: Motorola Boston (XT2419) - Moto G Stylus 5G 2024
# Recovery: Pitch Black Recovery Project (PBRP) Android 12.1
# Platform: Snapdragon 765 (parrot)
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
PBRP_BRANCH="android-12.1"
BUILD_VARIANT="${1:-user}"
JOBS=$(nproc --all)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/pbrp-build"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${BUILD_DIR}/pbrp_build_${TIMESTAMP}.log"

# Banner
print_banner() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                    ║${NC}"
    echo -e "${CYAN}║   ${MAGENTA}PITCH BLACK RECOVERY PROJECT - MOTOROLA BOSTON BUILD${CYAN}       ║${NC}"
    echo -e "${CYAN}║                                                                    ║${NC}"
    echo -e "${CYAN}║   Device: Motorola Moto G Stylus 5G 2024 (XT2419)                 ║${NC}"
    echo -e "${CYAN}║   Platform: Snapdragon 765 (parrot)                               ║${NC}"
    echo -e "${CYAN}║   Android: 12.1 | Recovery: TWRP 12.1                             ║${NC}"
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
    echo "PBRP Build Log - ${TIMESTAMP}" > "${LOG_FILE}"
    
    print_step "STEP 1/6: PRE-BUILD CHECKS"
    
    # Check system resources
    print_info "Checking system specifications..."
    
    TOTAL_RAM=$(free -g | awk 'NR==2 {print $2}')
    AVAILABLE_SPACE=$(df -BG "${HOME}" | awk 'NR==2 {print $4}' | sed 's/G//')
    CPU_CORES=$(nproc --all)
    
    echo -e "  • Total RAM: ${TOTAL_RAM}GB"
    echo -e "  • Available Storage: ${AVAILABLE_SPACE}GB"
    echo -e "  • CPU Cores: ${CPU_CORES}"
    echo ""
    
    if [ "${TOTAL_RAM}" -lt 8 ]; then
        print_warning "System has less than 8GB RAM. Build may be slow or fail."
    else
        print_status "Sufficient RAM detected (${TOTAL_RAM}GB)"
    fi
    
    if [ "${AVAILABLE_SPACE}" -lt 150 ]; then
        print_error "Insufficient storage! Need at least 150GB. Available: ${AVAILABLE_SPACE}GB"
        exit 1
    else
        print_status "Sufficient storage available (${AVAILABLE_SPACE}GB)"
    fi
    
    # Check required commands
    print_info "Checking required tools..."
    for cmd in git repo python3 java; do
        if command -v "$cmd" &> /dev/null; then
            VERSION=$($cmd --version 2>&1 | head -n1)
            print_status "$cmd: Found ($VERSION)"
        else
            print_error "$cmd: NOT FOUND - Please install it"
            exit 1
        fi
    done
    
    print_step "STEP 2/6: INITIALIZING PBRP SOURCE REPOSITORY"
    
    if [ ! -d "${BUILD_DIR}" ]; then
        print_info "Creating build directory: ${BUILD_DIR}"
        mkdir -p "${BUILD_DIR}"
    else
        print_info "Build directory already exists: ${BUILD_DIR}"
    fi
    
    cd "${BUILD_DIR}"
    
    if [ -d ".repo" ]; then
        print_warning "PBRP repository already initialized"
        print_info "Skipping re-initialization"
    else
        print_info "Initializing PBRP manifest for Android 12.1..."
        repo init -u https://github.com/PitchBlackRecoveryProject/manifest \
                  -b ${PBRP_BRANCH} \
                  -g default,-device,-mips,-darwin,-notdefault \
                  2>&1 | tee -a "${LOG_FILE}"
        
        if [ $? -eq 0 ]; then
            print_status "PBRP manifest initialized successfully"
        else
            print_error "Failed to initialize PBRP manifest"
            exit 1
        fi
    fi
    
    print_step "STEP 3/6: SYNCING PBRP SOURCE CODE"
    
    print_info "This may take 30-60 minutes on first sync..."
    print_info "Syncing with ${JOBS} parallel jobs"
    
    repo sync -c -j${JOBS} --force-sync --no-clone-bundle --no-tags 2>&1 | tee -a "${LOG_FILE}"
    
    if [ $? -eq 0 ]; then
        print_status "Source code synced successfully"
    else
        print_error "Failed to sync source code"
        exit 1
    fi
    
    print_step "STEP 4/6: CLONING DEVICE TREES"
    
    # Device tree
    print_info "Cloning device tree..."
    if [ -d "device/motorola/boston" ]; then
        print_warning "Device tree already exists - skipping clone"
    else
        git clone https://github.com/detroit313x/android_device_motorola_boston.git \
                  device/motorola/boston -b pbrp-build-setup 2>&1 | tee -a "${LOG_FILE}"
        
        if [ $? -eq 0 ]; then
            print_status "Device tree cloned successfully"
        else
            print_error "Failed to clone device tree"
            exit 1
        fi
    fi
    
    # Vendor tree (optional)
    print_info "Attempting to clone vendor tree..."
    if [ -d "vendor/motorola/boston" ]; then
        print_warning "Vendor tree already exists - skipping clone"
    else
        git clone https://github.com/PizzaG/android_vendor_motorola_boston.git \
                  vendor/motorola/boston 2>&1 | tee -a "${LOG_FILE}" || \
        print_warning "Vendor tree not found - using defaults"
    fi
    
    # Kernel (optional)
    print_info "Attempting to clone kernel source..."
    if [ -d "kernel/motorola/parrot" ]; then
        print_warning "Kernel already exists - skipping clone"
    else
        git clone https://github.com/PizzaG/android_kernel_motorola_parrot.git \
                  kernel/motorola/parrot 2>&1 | tee -a "${LOG_FILE}" || \
        print_warning "Kernel source not found - using prebuilt kernel"
    fi
    
    print_step "STEP 5/6: SETTING UP BUILD ENVIRONMENT"
    
    print_info "Sourcing build environment..."
    source build/envsetup.sh 2>&1 | tee -a "${LOG_FILE}"
    
    print_info "Lunching device: twrp_${DEVICE_NAME}-${BUILD_VARIANT}"
    lunch "twrp_${DEVICE_NAME}-${BUILD_VARIANT}" 2>&1 | tee -a "${LOG_FILE}"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to lunch device configuration"
        exit 1
    fi
    
    print_status "Build environment ready"
    
    print_step "STEP 6/6: COMPILING RECOVERY IMAGE"
    
    print_info "Starting recovery image compilation..."
    print_info "Build variant: ${BUILD_VARIANT}"
    print_info "Parallel jobs: ${JOBS}"
    print_info "Device: ${DEVICE_NAME} (boston)"
    echo ""
    
    BUILD_START=$(date +%s)
    
    mka recoveryimage -j${JOBS} 2>&1 | tee -a "${LOG_FILE}"
    
    BUILD_EXIT=$?
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    BUILD_TIME_HMS=$(date -u -d @${BUILD_TIME} +%H:%M:%S)
    
    echo ""
    
    if [ ${BUILD_EXIT} -eq 0 ]; then
        print_status "Recovery image compiled successfully!"
    else
        print_error "Build failed with exit code ${BUILD_EXIT}"
        echo ""
        print_error "Check the log file for details:"
        print_error "  ${LOG_FILE}"
        exit 1
    fi
    
    print_step "BUILD COMPLETE - OUTPUT FILES"
    
    # Locate output files
    OUT_DIR="${OUT:-${BUILD_DIR}/out/target/product/${DEVICE_NAME}}"
    RECOVERY_IMG="${OUT_DIR}/recovery.img"
    BOOT_IMG="${OUT_DIR}/boot.img"
    VENDOR_BOOT="${OUT_DIR}/vendor_boot.img"
    
    echo ""
    
    if [ -f "${RECOVERY_IMG}" ]; then
        RECOVERY_SIZE=$(du -h "${RECOVERY_IMG}" | cut -f1)
        RECOVERY_SIZE_BYTES=$(stat -f%z "${RECOVERY_IMG}" 2>/dev/null || stat -c%s "${RECOVERY_IMG}")
        RECOVERY_SIZE_MB=$((RECOVERY_SIZE_BYTES / 1048576))
        
        print_status "Recovery Image"
        echo -e "  Location: ${RECOVERY_IMG}"
        echo -e "  Size: ${RECOVERY_SIZE} (${RECOVERY_SIZE_MB}MB)"
    else
        print_warning "Recovery image not found at: ${RECOVERY_IMG}"
    fi
    
    if [ -f "${BOOT_IMG}" ]; then
        BOOT_SIZE=$(du -h "${BOOT_IMG}" | cut -f1)
        print_status "Boot Image"
        echo -e "  Location: ${BOOT_IMG}"
        echo -e "  Size: ${BOOT_SIZE}"
    fi
    
    if [ -f "${VENDOR_BOOT}" ]; then
        VENDOR_SIZE=$(du -h "${VENDOR_BOOT}" | cut -f1)
        print_status "Vendor Boot Image"
        echo -e "  Location: ${VENDOR_BOOT}"
        echo -e "  Size: ${VENDOR_SIZE}"
    fi
    
    echo ""
    
    print_step "BUILD SUMMARY"
    
    echo -e "${CYAN}Device Information:${NC}"
    echo -e "  • Name: ${DEVICE_NAME}"
    echo -e "  • Model: XT2419 (Moto G Stylus 5G 2024)"
    echo -e "  • Platform: Snapdragon 765 (parrot)"
    echo -e "  • Display: 1080x2400 @ 403 DPI"
    echo ""
    
    echo -e "${CYAN}Build Information:${NC}"
    echo -e "  • Recovery Type: TWRP 12.1 / PBRP"
    echo -e "  • Build Variant: ${BUILD_VARIANT}"
    echo -e "  • Android Version: 12.1"
    echo -e "  • Build Time: ${BUILD_TIME_HMS}"
    echo -e "  • Timestamp: ${TIMESTAMP}"
    echo -e "  • Build Directory: ${BUILD_DIR}"
    echo ""
    
    echo -e "${CYAN}Quick Commands:${NC}"
    echo -e "  • Flash recovery:"
    echo -e "    ${YELLOW}adb reboot bootloader${NC}"
    echo -e "    ${YELLOW}fastboot flash recovery ${RECOVERY_IMG}${NC}"
    echo -e "    ${YELLOW}fastboot reboot${NC}"
    echo ""
    echo -e "  • View build log:"
    echo -e "    ${YELLOW}cat ${LOG_FILE}${NC}"
    echo ""
    echo -e "  • Rebuild recovery (faster):"
    echo -e "    ${YELLOW}cd ${BUILD_DIR} && source build/envsetup.sh${NC}"
    echo -e "    ${YELLOW}lunch twrp_${DEVICE_NAME}-${BUILD_VARIANT}${NC}"
    echo -e "    ${YELLOW}mka recoveryimage -j${JOBS}${NC}"
    echo ""
    
    print_status "Build Log: ${LOG_FILE}"
    print_status "PBRP compilation finished successfully!"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                     BUILD COMPLETED SUCCESSFULLY!                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Error handler
trap 'print_error "Build interrupted or failed"; exit 1' INT TERM

# Run main
main "$@"
