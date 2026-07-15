#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 Pitch Black Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from common PBRP configuration
$(call inherit-product, vendor/pb/config/common.mk)

# Inherit from device configuration
$(call inherit-product, device/motorola/boston/device.mk)

# Device identifier
PRODUCT_DEVICE := boston
PRODUCT_NAME := twrp_boston
PRODUCT_BRAND := motorola
PRODUCT_MODEL := Moto G Stylus 5G 2024
PRODUCT_MANUFACTURER := motorola

# Build fingerprint
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=boston \
    PRODUCT_DEVICE=boston \
    PRODUCT_MODEL="XT2419" \
    PRODUCT_BRAND=motorola \
    PRODUCT_MANUFACTURER=motorola \
    TARGET_DEVICE=boston

# For language and region
PRODUCT_DEFAULT_LANGUAGE := en
PRODUCT_DEFAULT_REGION := US
