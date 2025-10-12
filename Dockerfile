# 依赖构建阶段
FROM node:22-alpine AS deps
WORKDIR /app

# 复制依赖文件
COPY package.json package-lock.json* ./

RUN npm config set registry https://registry.npmmirror.com
# 安装依赖
RUN npm ci

# 构建阶段
FROM node:22-alpine AS builder
WORKDIR /app

# 设置构建参数
ARG HOST_PORT=3000
ARG DATABASE_URL=""
ARG AUTH_SECRET=""
ARG ADMIN_CODE=11223344
ARG NEXTAUTH_URL=http://localhost:3000
ARG AUTH_TRUST_HOST=true
ARG EMAIL_AUTH_STATUS=ON
ARG FEISHU_AUTH_STATUS=OFF
ARG FEISHU_CLIENT_ID=""
ARG FEISHU_CLIENT_SECRET=""
ARG WECOM_AUTH_STATUS=OFF
ARG WECOM_CLIENT_ID=""
ARG WECOM_AGENT_ID=""
ARG WECOM_CLIENT_SECRET=""
ARG DINGDING_AUTH_STATUS=OFF
ARG DINGDING_CLIENT_ID=""
ARG DINGDING_CLIENT_SECRET=""

# 复制依赖和源代码
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 构建应用
RUN npm run build

# 运行阶段（最终镜像）
FROM node:22-alpine AS runner
WORKDIR /app

# 设置环境变量
ENV NODE_ENV=production
ENV IS_DOCKER=true
ENV PUID=1000
ENV PGID=1000

# 复制必要文件
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

RUN apk add --no-cache bash su-exec

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露端口
EXPOSE 3000

# 入口命令
ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "server.js"]