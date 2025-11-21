#!/bin/bash
set -eo pipefail

echo "[redirect_pkg_handler] starting..."
/redirect_pkg_handler -m route &

# 初始化 TAILSCALED_OPTS
TAILSCALED_OPTS=""

# 添加额外参数（如果存在）
if [ -n "$TS_TAILSCALED_EXTRA_ARGS" ]; then
    echo "[config] TS_TAILSCALED_EXTRA_ARGS: $TS_TAILSCALED_EXTRA_ARGS"
    TAILSCALED_OPTS="$TAILSCALED_OPTS $TS_TAILSCALED_EXTRA_ARGS"
fi

# 配置 state 目录
if [ -n "$TS_STATE_DIR" ]; then
    echo "[config] TS_STATE_DIR: $TS_STATE_DIR"
    mkdir -p "$TS_STATE_DIR"
    TAILSCALED_OPTS="$TAILSCALED_OPTS --statedir=$TS_STATE_DIR"
fi

# 配置 socket
if [ -n "$TS_SOCKET" ]; then
    echo "[config] TS_SOCKET: $TS_SOCKET"
    TAILSCALED_OPTS="$TAILSCALED_OPTS --socket=$TS_SOCKET"
fi

# 配置 SOCKS5 服务器
if [ -n "$TS_SOCKS5_SERVER" ]; then
    echo "[config] TS_SOCKS5_SERVER: $TS_SOCKS5_SERVER"
    TAILSCALED_OPTS="$TAILSCALED_OPTS --socks5-server=$TS_SOCKS5_SERVER"
fi

# 配置出站 HTTP 代理
if [ -n "$TS_OUTBOUND_HTTP_PROXY_LISTEN" ]; then
    echo "[config] TS_OUTBOUND_HTTP_PROXY_LISTEN: $TS_OUTBOUND_HTTP_PROXY_LISTEN"
    TAILSCALED_OPTS="$TAILSCALED_OPTS --outbound-http-proxy-listen=$TS_OUTBOUND_HTTP_PROXY_LISTEN"
fi

# 配置用户空间模式
if [ "$TS_USERSPACE" = "true" ]; then
    echo "[config] Using userspace networking"
    TAILSCALED_OPTS="$TAILSCALED_OPTS --tun=userspace-networking"
fi

# 去除首尾空格
TAILSCALED_OPTS=$(echo "$TAILSCALED_OPTS" | xargs)

# 启动 tailscaled
echo "[tailscaled] starting with options: ${TAILSCALED_OPTS}"
if [ -n "$TAILSCALED_OPTS" ]; then
    tailscaled ${TAILSCALED_OPTS} &
else
    tailscaled &
fi

# 等待 tailscaled 启动
sleep 3

# 初始化 TAILSCALE_UP_OPTS
TAILSCALE_UP_OPTS=""

# 添加认证密钥
if [ -n "$TS_AUTHKEY" ]; then
    echo "[config] Using auth key"
    TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --authkey=$TS_AUTHKEY"
fi

# 添加额外的 up 参数
if [ -n "$TS_EXTRA_ARGS" ]; then
    echo "[config] TS_EXTRA_ARGS: $TS_EXTRA_ARGS"
    TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS $TS_EXTRA_ARGS"
fi

# 配置主机名
if [ -n "$TS_HOSTNAME" ]; then
    echo "[config] TS_HOSTNAME: $TS_HOSTNAME"
    TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --hostname=$TS_HOSTNAME"
fi

# 配置路由广播
if [ -n "$TS_ROUTES" ]; then
    echo "[config] TS_ROUTES: $TS_ROUTES"
    TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --advertise-routes=$TS_ROUTES"
fi

# 配置 DNS 接受
if [ "$TS_ACCEPT_DNS" = "true" ]; then
    echo "[config] Accepting DNS"
    TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --accept-dns"
fi

# 配置一次性认证
if [ "$TS_AUTH_ONCE" = "true" ]; then
    echo "[config] Using auth-once mode"
    TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --auth-once"
fi

# 去除首尾空格
TAILSCALE_UP_OPTS=$(echo "$TAILSCALE_UP_OPTS" | xargs)

# 执行 tailscale up
if [ -n "$TAILSCALE_UP_OPTS" ]; then
    echo "[tailscale up] options: ${TAILSCALE_UP_OPTS}"
    for i in {1..5}; do
        if tailscale up ${TAILSCALE_UP_OPTS}; then
            echo "[tailscale up] success"
            break
        else
            echo "[tailscale up] failed, retry ($i/5)..."
            sleep 2
        fi
    done
else
    echo "[tailscale up] no options provided, skipping..."
fi

echo "[startup] complete, waiting for processes..."
wait