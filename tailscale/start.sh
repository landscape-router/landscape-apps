#!/bin/bash
set -eo pipefail

# tailscaled 启动参数，可通过环境变量传入
TAILSCALED_OPTS=${TAILSCALED_OPTS:-""}

# tailscale up 参数，可通过环境变量传入，默认空
TAILSCALE_UP_OPTS=${TAILSCALE_UP_OPTS:-""}

# 启动自定义程序
echo "[redirect_pkg_handler] starting..."
/redirect_pkg_handler -m route &

# 启动 tailscaled
echo "[tailscaled] starting with options: ${TAILSCALED_OPTS}"
tailscaled ${TAILSCALED_OPTS} &

sleep 3

# 执行 tailscale up（如果提供了参数）
if [ -n "$TAILSCALE_UP_OPTS" ]; then
    echo "[tailscale up] options: ${TAILSCALE_UP_OPTS}"
    for i in {1..5}; do
        if tailscale up ${TAILSCALE_UP_OPTS}; then
            echo "tailscale up success"
            break
        else
            echo "tailscale up failed, retry ($i)..."
            sleep 2
        fi
    done
else
    echo "[tailscale up] no options provided, skipping..."
fi

wait
