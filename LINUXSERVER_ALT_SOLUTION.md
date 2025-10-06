# LinuxServer 替代方案说明

由于LinuxServer官方镜像仓库中没有Node.js镜像，我们创建了一个替代方案，使用标准镜像但实现LinuxServer的权限管理功能。

## 🔧 替代方案特点

### Dockerfile.linuxserver-alt

**基础镜像**: `node:22-alpine`
**权限管理**: 自定义entrypoint脚本实现PUID/PGID支持

**主要功能**:
1. **多阶段构建**: 优化镜像大小
2. **权限管理脚本**: 自动创建用户和组
3. **环境变量支持**: PUID/PGID动态配置
4. **健康检查**: 内置服务监控

### docker-compose.linuxserver.yml

**数据库镜像**: `postgres:16-alpine`
**权限配置**: 使用`user`字段指定运行用户

## 🚀 使用方法

### 1. 环境变量配置

```bash
# .env 文件配置
PUID=1000
PGID=10
TZ=Asia/Shanghai
DB_PASSWORD=your_secure_password
AUTH_SECRET=your_auth_secret
NEXTAUTH_URL=http://localhost:3000
```

### 2. 部署命令

```bash
# 自动部署
./deploy.sh

# 或手动部署
docker-compose -f docker-compose.linuxserver.yml up -d --build
```

### 3. 验证权限

```bash
# 检查容器内用户
docker-compose -f docker-compose.linuxserver.yml exec app id

# 检查数据目录权限
ls -la data/
```

## 🔍 权限管理原理

### Entrypoint脚本功能

```bash
# 创建用户和组
addgroup -g $PGID -S hivechat
adduser -u $PUID -G hivechat -s /bin/bash -D hivechat

# 设置目录权限
chown -R $PUID:$PGID /app

# 切换到应用用户运行
exec su-exec $PUID:$PGID "$@"
```

### 环境变量支持

- `PUID`: 用户ID，默认为1000
- `PGID`: 组ID，默认为10
- `TZ`: 时区设置

## 📊 与LinuxServer对比

| 特性 | LinuxServer官方 | 替代方案 |
|------|----------------|----------|
| 基础镜像 | 专用镜像 | 标准镜像 |
| 权限管理 | 内置支持 | 自定义脚本 |
| 镜像大小 | 较大 | 较小 |
| 维护性 | 官方维护 | 自定义维护 |
| 兼容性 | 完全兼容 | 基本兼容 |

## 🛠️ 故障排除

### 权限问题

```bash
# 重新设置目录权限
sudo chown -R 1000:10 data/
chmod -R 755 data/

# 重启服务
docker-compose -f docker-compose.linuxserver.yml restart
```

### 用户创建失败

```bash
# 检查容器日志
docker-compose -f docker-compose.linuxserver.yml logs app

# 手动进入容器调试
docker-compose -f docker-compose.linuxserver.yml exec app bash
```

### 数据库连接问题

```bash
# 检查数据库状态
docker-compose -f docker-compose.linuxserver.yml exec db pg_isready -U postgres

# 检查用户权限
docker-compose -f docker-compose.linuxserver.yml exec db id
```

## 🔄 迁移指南

### 从LinuxServer官方迁移

1. **更新Dockerfile引用**:
   ```bash
   # 从
   docker-compose -f docker-compose.linuxserver.yml up -d --build
   
   # 到 (使用新的替代方案)
   # 文件会自动使用 Dockerfile.linuxserver-alt
   ```

2. **验证配置**:
   ```bash
   # 检查环境变量
   cat .env | grep -E "(PUID|PGID)"
   
   # 测试部署
   ./deploy.sh
   ```

## 💡 优势

1. **解决镜像不存在问题**: 使用标准镜像避免拉取失败
2. **保持权限管理**: 实现LinuxServer的PUID/PGID功能
3. **镜像更小**: 基于Alpine Linux，体积更小
4. **更好的兼容性**: 使用官方维护的镜像
5. **灵活配置**: 支持自定义用户权限

## 📞 支持

如果遇到问题：
1. 查看容器日志: `docker-compose -f docker-compose.linuxserver.yml logs -f`
2. 检查权限设置: `ls -la data/`
3. 验证环境变量: `docker-compose -f docker-compose.linuxserver.yml config`
4. 重新部署: `./deploy.sh`
