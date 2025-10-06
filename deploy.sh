#!/bin/bash

# HiveChat LinuxServer 部署脚本
# 用于简化 Docker Compose 部署过程

set -e

echo "🚀 HiveChat LinuxServer 部署脚本"
echo "=================================="

# 检查 Docker 和 Docker Compose 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 检查是否存在 .env 文件
if [ ! -f ".env" ]; then
    echo "⚠️  未找到 .env 文件"
    if [ -f "env.example" ]; then
        echo "📋 从 env.example 创建 .env 文件..."
        cp env.example .env
        echo "✅ 已创建 .env 文件，请编辑其中的配置"
        echo "📝 重要：请至少修改以下配置："
        echo "   - AUTH_SECRET: 设置一个至少32位的随机字符串"
        echo "   - DB_PASSWORD: 设置数据库密码"
        echo "   - NEXTAUTH_URL: 设置你的域名或IP地址"
        read -p "按 Enter 键继续，或 Ctrl+C 退出编辑配置..."
    else
        echo "❌ 未找到 env.example 文件，请手动创建 .env 文件"
        exit 1
    fi
fi

# 初始化数据目录
echo "📁 初始化数据目录..."
if [ -f "./init-dirs.sh" ]; then
    ./init-dirs.sh
else
    echo "⚠️  未找到 init-dirs.sh，手动创建目录..."
    mkdir -p data/postgres data/hivechat
    chmod -R 755 data/
fi

# 停止现有容器
echo "🛑 停止现有容器..."
docker-compose -f docker-compose.linuxserver.yml down 2>/dev/null || true

# 构建和启动服务
echo "🔨 构建并启动服务..."
docker-compose -f docker-compose.linuxserver.yml up -d --build

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "📊 检查服务状态..."
docker-compose -f docker-compose.linuxserver.yml ps

# 显示日志
echo "📋 显示最近日志..."
docker-compose -f docker-compose.linuxserver.yml logs --tail=20

echo ""
echo "✅ 部署完成！"
echo "🌐 应用访问地址: http://localhost:3000"
echo "📊 查看日志: docker-compose -f docker-compose.linuxserver.yml logs -f"
echo "🛑 停止服务: docker-compose -f docker-compose.linuxserver.yml down"
echo ""
echo "💡 提示："
echo "   - 首次启动可能需要几分钟时间"
echo "   - 确保防火墙已开放 3000 端口"
echo "   - 查看详细日志了解启动状态"
