#!/bin/bash

# 定义基础路径，确保在 wrt/package/ 目录下执行时逻辑清晰
PKG_PATH="$GITHUB_WORKSPACE/wrt/package"
FEED_PATH="$GITHUB_WORKSPACE/wrt/feeds"

# 1. 修改 NSS 相关组件启动顺序以优化性能
# 修复 qca-nss-drv
NSS_DRV="$FEED_PATH/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then
    sed -i 's/START=.*/START=85/g' "$NSS_DRV"
    echo "qca-nss-drv fixed"
else
    echo "Warning: qca-nss-drv.init not found at $NSS_DRV"
fi

# 修复 qca-nss-pbuf (通常位于 kernel 路径下)
NSS_PBUF="$PKG_PATH/kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then
    sed -i 's/START=.*/START=86/g' "$NSS_PBUF"
    echo "qca-nss-pbuf fixed"
fi

# 2. 修复 Rust 编译环境
# 使用更稳健的查找方式定位 rust Makefile
RUST_FILE=$(find "$FEED_PATH/packages/" -maxdepth 3 -type f -wholename "*/rust/Makefile" 2>/dev/null)
if [ -f "$RUST_FILE" ]; then
    sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE"
    echo "Rust compilation fix applied"
fi

# 3. 修复 DiskMan 及其文件系统依赖
# 确保匹配到正确目录下的 Makefile
DM_FILE="$PKG_PATH/luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then
    sed -i 's/fs-ntfs/fs-ntfs3/g' "$DM_FILE"
    sed -i '/ntfs-3g-utils /d' "$DM_FILE"
    echo "Diskman dependencies fixed"
    
    # 额外修复：确保 automount 使用 ntfs3
    AUTOMOUNT_FILE="$PKG_PATH/automount/files/15-automount"
    if [ -f "$AUTOMOUNT_FILE" ]; then
        sed -i 's/ntfs/ntfs3/g' "$AUTOMOUNT_FILE"
        echo "Automount ntfs3 fix applied"
    fi
fi
