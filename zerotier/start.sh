#!/bin/sh
set -e

# 启动你的程序（后台运行）
echo "[redirect_pkg_handler] starting..."
/redirect_pkg_handler -m route &

# 调用原本的 entrypoint.sh 并传递所有参数
echo "[zerotier entrypoint] starting..."
exec /entrypoint.sh "$@"
