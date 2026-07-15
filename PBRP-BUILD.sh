#!/bin/bash

# PBRP Build Script for Motorola Boston
# Device: Motorola Moto G Stylus 5G 2024
# Recovery: Pitch Black Recovery Project

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build configuration
DEVICE_NAME="boston"
RECOVERY_TYPE="pbrp"
BUILD_VARIANT="user"
JOBS=$(nproc --all)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}PBRP Build Script - Motorola Boston${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if in PBRP root directory
if [ ! -f "build/envsetup.sh" ]; then
    print_error "Not in PBRP root directory!"
    print_error "Please run this script from the PBRP source root"
    exit 1
fi

print_status "Setting up build environment..."

# Source build environment
source build/envsetup.sh

print_status "Lunching device: ${DEVICE_NAME}"
lunch twrp_${DEVICE_NAME}-${BUILD_VARIANT}

if [ $? -ne 0 ]; then
    print_error "Failed to lunch device!"
    exit 1
fi

print_status "Starting recovery image compilation..."
print_status "Using ${JOBS} parallel jobs"
echo ""

# Build recovery image
mka recoveryimage -j${JOBS}

if [ $? -ne 0 ]; then
    print_error "Build failed!"
    exit 1
fi

print_status "Recovery image compiled successfully!"
echo ""

# Locate output files
OUT_DIR="${OUT:-out/target/product/${DEVICE_NAME}}"
RECOVERY_IMG="${OUT_DIR}/recovery.img"
BOOT_IMG="${OUT_DIR}/boot.img"

if [ -f "${RECOVERY_IMG}" ]; then
    print_status "Recovery image location: ${RECOVERY_IMG}"
    print_status "Size: $(du -h ${RECOVERY_IMG} | cut -f1)"
else
    print_warning "Recovery image not found at expected location"
fi

if [ -f "${BOOT_IMG}" ]; then
    print_status "Boot image location: ${BOOT_IMG}"
    print_status "Size: $(du -h ${BOOT_IMG} | cut -f1)"
fi

echo ""
print_status "Build completed at: $(date)"
print_status "Build time: $(date -u -d @$(($SECONDS)) +%H:%M:%S)"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Build Summary${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "Device:         ${DEVICE_NAME}"
echo -e "Recovery Type:  ${RECOVERY_TYPE}"
echo -e "Build Variant:  ${BUILD_VARIANT}"
echo -e "Timestamp:      ${TIMESTAMP}"
echo -e "${GREEN}================================${NC}"
echo ""
print_status "PBRP compilation finished successfully!"
