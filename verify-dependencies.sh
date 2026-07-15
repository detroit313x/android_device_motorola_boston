#!/bin/bash

################################################################################
# PBRP BUILD DEPENDENCY VERIFICATION SCRIPT
# Device: Motorola Boston (XT2419) - Moto G Stylus 5G 2024
# Verifies all dependencies are present before compilation
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Build directory
BUILD_DIR="${HOME}/pbrp-build"

# Functions
print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                    ║${NC}"
    echo -e "${CYAN}║      ${BLUE}PBRP BUILD DEPENDENCY VERIFICATION${CYAN}                         ║${NC}"
    echo -e "${CYAN}║      Motorola Boston (XT2419) - TWRP 12.1 / PBRP                  ║${NC}"
    echo -e "${CYAN}║                                                                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_pass() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}[✗]${NC} $1"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
    ((CHECKS_WARNING++))
}

print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Main verification
main() {
    print_header
    
    # System Requirements
    print_section "SYSTEM REQUIREMENTS"
    
    # OS Check
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE=$(lsb_release -ds 2>/dev/null || echo "Linux")
        check_pass "Operating System: $OS_TYPE"
    else
        check_fail "Operating System: Not Linux ($OSTYPE)"
    fi
    
    # RAM Check
    TOTAL_RAM=$(free -g | awk 'NR==2 {print $2}')
    if [ "$TOTAL_RAM" -ge 8 ]; then
        check_pass "RAM: ${TOTAL_RAM}GB (Required: 8GB minimum)"
    elif [ "$TOTAL_RAM" -ge 4 ]; then
        check_warn "RAM: ${TOTAL_RAM}GB (Recommended: 16GB for faster builds)"
    else
        check_fail "RAM: ${TOTAL_RAM}GB (Need at least 8GB)"
    fi
    
    # Storage Check
    AVAILABLE_SPACE=$(df -BG "${HOME}" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
    if [ "$AVAILABLE_SPACE" -ge 150 ]; then
        check_pass "Storage: ${AVAILABLE_SPACE}GB available (Required: 150GB minimum)"
    else
        check_fail "Storage: ${AVAILABLE_SPACE}GB available (Need at least 150GB)"
    fi
    
    # CPU Cores
    CPU_CORES=$(nproc --all)
    if [ "$CPU_CORES" -ge 4 ]; then
        check_pass "CPU Cores: $CPU_CORES (Recommended: 4+ cores)"
    else
        check_warn "CPU Cores: $CPU_CORES (Build may be slow)"
    fi
    
    # Build Tools
    print_section "BUILD TOOLS & DEPENDENCIES"
    
    # Git
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | awk '{print $3}')
        check_pass "Git: $GIT_VERSION"
    else
        check_fail "Git: NOT INSTALLED"
    fi
    
    # Repo
    if command -v repo &> /dev/null; then
        check_pass "Repo: $(command -v repo)"
    else
        check_fail "Repo: NOT INSTALLED - Install with: curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo"
    fi
    
    # Python3
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        check_pass "Python3: $PYTHON_VERSION"
    else
        check_fail "Python3: NOT INSTALLED"
    fi
    
    # Java
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | grep 'version' | awk '{print $3}' | sed 's/"//g' || echo "11+")
        check_pass "Java: $JAVA_VERSION"
    else
        check_fail "Java: NOT INSTALLED - Install: sudo apt-get install openjdk-11-jdk"
    fi
    
    # GCC
    if command -v gcc &> /dev/null; then
        GCC_VERSION=$(gcc --version | head -n1 | awk '{print $3}')
        check_pass "GCC: $GCC_VERSION"
    else
        check_fail "GCC: NOT INSTALLED"
    fi
    
    # Make
    if command -v make &> /dev/null; then
        check_pass "Make: $(make --version | head -n1 | awk '{print $3}')"
    else
        check_fail "Make: NOT INSTALLED"
    fi
    
    # Ccache
    if command -v ccache &> /dev/null; then
        CCACHE_VERSION=$(ccache --version | head -n1 | awk '{print $3}')
        check_pass "Ccache: $CCACHE_VERSION (speeds up rebuilds)"
    else
        check_warn "Ccache: NOT INSTALLED (optional but recommended)"
    fi
    
    # Development Libraries
    print_section "DEVELOPMENT LIBRARIES"
    
    # libssl-dev
    if dpkg -l | grep -q libssl-dev; then
        check_pass "libssl-dev: Installed"
    else
        check_warn "libssl-dev: NOT INSTALLED - sudo apt-get install libssl-dev"
    fi
    
    # libffi-dev
    if dpkg -l | grep -q libffi-dev; then
        check_pass "libffi-dev: Installed"
    else
        check_warn "libffi-dev: NOT INSTALLED - sudo apt-get install libffi-dev"
    fi
    
    # zip/unzip
    if command -v zip &> /dev/null && command -v unzip &> /dev/null; then
        check_pass "zip/unzip: Installed"
    else
        check_warn "zip/unzip: NOT INSTALLED - sudo apt-get install zip unzip"
    fi
    
    # PBRP Source & Device Tree
    print_section "PBRP SOURCE & DEVICE TREE"
    
    # Build directory
    if [ -d "$BUILD_DIR" ]; then
        check_pass "Build Directory: $BUILD_DIR exists"
    else
        check_warn "Build Directory: $BUILD_DIR does not exist (will be created)"
    fi
    
    # PBRP Repo
    if [ -d "$BUILD_DIR/.repo" ]; then
        check_pass "PBRP Repo: Initialized at $BUILD_DIR/.repo"
        REPO_SIZE=$(du -sh "$BUILD_DIR/.repo" 2>/dev/null | awk '{print $1}' || echo "unknown")
        echo -e "  └─ Size: $REPO_SIZE"
    else
        check_warn "PBRP Repo: Not initialized (will initialize during build)"
    fi
    
    # Source code
    if [ -d "$BUILD_DIR/build" ]; then
        check_pass "Source Code: Synced (build system present)"
        SOURCE_SIZE=$(du -sh "$BUILD_DIR" 2>/dev/null | awk '{print $1}' || echo "unknown")
        echo -e "  └─ Total Size: $SOURCE_SIZE"
    else
        check_warn "Source Code: Not synced (will sync during build)"
    fi
    
    # Device Tree
    if [ -d "$BUILD_DIR/device/motorola/boston" ]; then
        check_pass "Device Tree: Present at device/motorola/boston"
        if [ -f "$BUILD_DIR/device/motorola/boston/BoardConfig.mk" ]; then
            check_pass "BoardConfig.mk: Found"
        else
            check_fail "BoardConfig.mk: Missing"
        fi
        if [ -f "$BUILD_DIR/device/motorola/boston/AndroidProducts.mk" ]; then
            check_pass "AndroidProducts.mk: Found"
        else
            check_fail "AndroidProducts.mk: Missing"
        fi
        if [ -f "$BUILD_DIR/device/motorola/boston/device.mk" ]; then
            check_pass "device.mk: Found"
        else
            check_fail "device.mk: Missing"
        fi
        if [ -f "$BUILD_DIR/device/motorola/boston/twrp_boston.mk" ]; then
            check_pass "twrp_boston.mk: Found"
        else
            check_warn "twrp_boston.mk: Not found (PBRP config)"
        fi
    else
        check_warn "Device Tree: Not cloned (will clone during build)"
    fi
    
    # Vendor Tree
    if [ -d "$BUILD_DIR/vendor/motorola/boston" ]; then
        check_pass "Vendor Tree: Present"
        VENDOR_SIZE=$(du -sh "$BUILD_DIR/vendor/motorola/boston" 2>/dev/null | awk '{print $1}' || echo "unknown")
        echo -e "  └─ Size: $VENDOR_SIZE"
    else
        check_warn "Vendor Tree: Not present (optional, will use defaults)"
    fi
    
    # Kernel
    if [ -d "$BUILD_DIR/kernel/motorola/parrot" ]; then
        check_pass "Kernel Source: Present"
    else
        check_warn "Kernel Source: Not present (will use prebuilt kernel)"
    fi
    
    # Build Configurations
    print_section "BUILD CONFIGURATION VERIFICATION"
    
    if [ -f "$BUILD_DIR/device/motorola/boston/BoardConfig.mk" ]; then
        echo -e "${BLUE}BoardConfig.mk settings:${NC}"
        
        # Check key variables
        ARCH=$(grep "^TARGET_ARCH :=" "$BUILD_DIR/device/motorola/boston/BoardConfig.mk" | awk '{print $NF}')
        [ -n "$ARCH" ] && check_pass "  • TARGET_ARCH: $ARCH" || check_fail "  • TARGET_ARCH not set"
        
        PLATFORM=$(grep "^TARGET_BOARD_PLATFORM :=" "$BUILD_DIR/device/motorola/boston/BoardConfig.mk" | awk '{print $NF}')
        [ -n "$PLATFORM" ] && check_pass "  • TARGET_BOARD_PLATFORM: $PLATFORM" || check_fail "  • TARGET_BOARD_PLATFORM not set"
        
        RECOVERY_VARIANT=$(grep "^RECOVERY_VARIANT :=" "$BUILD_DIR/device/motorola/boston/BoardConfig.mk" | awk '{print $NF}')
        [ -n "$RECOVERY_VARIANT" ] && check_pass "  • RECOVERY_VARIANT: $RECOVERY_VARIANT" || check_fail "  • RECOVERY_VARIANT not set"
    fi
    
    # Build Scripts
    print_section "BUILD SCRIPTS"
    
    if [ -f "$BUILD_DIR/device/motorola/boston/pbrp-build-init.sh" ]; then
        check_pass "pbrp-build-init.sh: Found"
        if [ -x "$BUILD_DIR/device/motorola/boston/pbrp-build-init.sh" ]; then
            check_pass "pbrp-build-init.sh: Executable"
        else
            check_warn "pbrp-build-init.sh: Not executable (will fix with chmod +x)"
        fi
    else
        check_fail "pbrp-build-init.sh: Not found"
    fi
    
    if [ -f "$BUILD_DIR/device/motorola/boston/PBRP-BUILD.sh" ]; then
        check_pass "PBRP-BUILD.sh: Found"
    else
        check_warn "PBRP-BUILD.sh: Not found"
    fi
    
    # Documentation
    print_section "DOCUMENTATION"
    
    [ -f "$BUILD_DIR/device/motorola/boston/PBRP-SETUP.md" ] && \
        check_pass "PBRP-SETUP.md: Setup guide found" || \
        check_warn "PBRP-SETUP.md: Not found"
    
    [ -f "$BUILD_DIR/device/motorola/boston/PBRP-BUILD-EXECUTION.md" ] && \
        check_pass "PBRP-BUILD-EXECUTION.md: Execution guide found" || \
        check_warn "PBRP-BUILD-EXECUTION.md: Not found"
    
    [ -f "$BUILD_DIR/device/motorola/boston/prebuilt/QUICK-START.txt" ] && \
        check_pass "QUICK-START.txt: Quick reference found" || \
        check_warn "QUICK-START.txt: Not found"
    
    # Summary
    print_section "VERIFICATION SUMMARY"
    
    TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))
    
    echo -e "Total Checks: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "  ${GREEN}Passed: $CHECKS_PASSED${NC}"
    echo -e "  ${YELLOW}Warnings: $CHECKS_WARNING${NC}"
    echo -e "  ${RED}Failed: $CHECKS_FAILED${NC}"
    echo ""
    
    if [ $CHECKS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ BUILD READY${NC}"
        echo ""
        echo "All critical dependencies verified!"
        echo "You can now proceed with building:"
        echo ""
        echo -e "  ${CYAN}bash ~/pbrp-build-init.sh${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ BUILD NOT READY${NC}"
        echo ""
        echo "Please resolve the failed checks above before building."
        echo ""
        return 1
    fi
}

# Run verification
main "$@"
