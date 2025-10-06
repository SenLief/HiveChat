#!/bin/bash

# HiveChat 目录初始化脚本
# 自动创建所需的数据目录并设置正确的权限

set -e

echo "🚀 HiveChat 目录初始化脚本"
echo "=============================="

# 获取配置
DATA_PATH=${DATA_PATH:-./data}
PUID=${PUID:-1000}
PGID=${PGID:-10}

echo "📋 配置信息："
echo "  数据目录: ${DATA_PATH}"
echo "  用户ID: ${PUID}"
echo "  组ID: ${PGID}"
echo ""

# 创建数据目录
echo "📁 创建数据目录..."
mkdir -p "${DATA_PATH}/postgres"
mkdir -p "${DATA_PATH}/hivechat"

# 设置目录权限
echo "🔐 设置目录权限..."
chown -R ${PUID}:${PGID} "${DATA_PATH}" 2>/dev/null || {
    echo "⚠️  无法设置目录所有者，可能需要 sudo 权限"
    echo "   请手动运行: sudo chown -R ${PUID}:${PGID} ${DATA_PATH}"
}
chmod -R 755 "${DATA_PATH}"

echo "✅ 目录初始化完成！"
echo ""
echo "📁 创建的目录："
echo "  - ${DATA_PATH}/postgres (数据库数据)"
echo "  - ${DATA_PATH}/hivechat (应用数据)"
echo ""
echo "🔐 权限设置："
echo "  - 所有者: ${PUID}:${PGID}"
echo "  - 权限: 755"
echo ""
echo "💡 现在可以运行: docker-compose -f docker-compose.linuxserver.yml up -d --build"
