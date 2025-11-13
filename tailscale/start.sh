#!/bin/bash
set -eo pipefail

echo "[redirect_pkg_handler] starting..."
/redirect_pkg_handler -m route &

TAILSCALED_OPTS=${TAILSCALED_OPTS:-""}

[ -n "$TS_TAILSCALED_EXTRA_ARGS" ] && TAILSCALED_OPTS="$TAILSCALED_OPTS $TS_TAILSCALED_EXTRA_ARGS"

[ -n "$TS_STATE_DIR" ] && mkdir -p "$TS_STATE_DIR" && TAILSCALED_OPTS="$TAILSCALED_OPTS --statedir=$TS_STATE_DIR"

[ -n "$TS_SOCKET" ] && TAILSCALED_OPTS="$TAILSCALED_OPTS --socket=$TS_SOCKET"
[ -n "$TS_SOCKS5_SERVER" ] && TAILSCALED_OPTS="$TAILSCALED_OPTS --socks5-server=$TS_SOCKS5_SERVER"
[ -n "$TS_OUTBOUND_HTTP_PROXY_LISTEN" ] && TAILSCALED_OPTS="$TAILSCALED_OPTS --outbound-http-proxy-listen=$TS_OUTBOUND_HTTP_PROXY_LISTEN"

if [ "$TS_USERSPACE" = "true" ]; then
    TAILSCALED_OPTS="$TAILSCALED_OPTS --tun=userspace-networking"
fi

echo "[tailscaled] starting with options: ${TAILSCALED_OPTS}"
tailscaled ${TAILSCALED_OPTS} &

sleep 3

TAILSCALE_UP_OPTS=${TAILSCALE_UP_OPTS:-""}

[ -n "$TS_AUTHKEY" ] && TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --authkey=$TS_AUTHKEY"

[ -n "$TS_EXTRA_ARGS" ] && TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS $TS_EXTRA_ARGS"

[ -n "$TS_HOSTNAME" ] && TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --hostname=$TS_HOSTNAME"

[ -n "$TS_ROUTES" ] && TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --advertise-routes=$TS_ROUTES"

if [ "$TS_ACCEPT_DNS" = "true" ]; then
    TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --accept-dns"
fi

if [ "$TS_AUTH_ONCE" = "true" ]; then
    TAILSCALE_UP_OPTS="$TAILSCALE_UP_OPTS --auth-no-login"
fi

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
