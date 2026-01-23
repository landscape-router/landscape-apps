#!/bin/bash
set -eo pipefail

echo "[redirect_pkg_handler] starting..."
/redirect_pkg_handler -m route &

WG_CONF="/etc/wireguard/wg0.conf"

if [ ! -f "$WG_CONF" ]; then
    echo "[config] $WG_CONF not found, checking environment variables..."
    
    if [ -n "$WG_INTERFACE_PRIVATE_KEY" ] && [ -n "$WG_INTERFACE_ADDRESS" ]; then
        echo "[config] Generating $WG_CONF from environment variables..."
        
        cat <<EOF > "$WG_CONF"
[Interface]
PrivateKey = $WG_INTERFACE_PRIVATE_KEY
Address = $WG_INTERFACE_ADDRESS
EOF

        if [ -n "$WG_INTERFACE_DNS" ]; then
             echo "DNS = $WG_INTERFACE_DNS" >> "$WG_CONF"
        fi
        if [ -n "$WG_INTERFACE_POST_UP" ]; then
             echo "PostUp = $WG_INTERFACE_POST_UP" >> "$WG_CONF"
        fi
        if [ -n "$WG_INTERFACE_POST_DOWN" ]; then
             echo "PostDown = $WG_INTERFACE_POST_DOWN" >> "$WG_CONF"
        fi

        if [ -n "$WG_PEER_PUBLIC_KEY" ] && [ -n "$WG_PEER_ALLOWED_IPS" ] && [ -n "$WG_PEER_ENDPOINT" ]; then
            echo "[config] Adding peer configuration..."
            cat <<EOF >> "$WG_CONF"

[Peer]
PublicKey = $WG_PEER_PUBLIC_KEY
AllowedIPs = $WG_PEER_ALLOWED_IPS
Endpoint = $WG_PEER_ENDPOINT
EOF
            if [ -n "$WG_PEER_PRESHARED_KEY" ]; then
                 echo "PresharedKey = $WG_PEER_PRESHARED_KEY" >> "$WG_CONF"
            fi
            if [ -n "$WG_PEER_PERSISTENT_KEEPALIVE" ]; then
                 echo "PersistentKeepalive = $WG_PEER_PERSISTENT_KEEPALIVE" >> "$WG_CONF"
            fi
        fi
        
        echo "[config] Configuration generated successfully."
    else
        echo "[config] Environment variables missing or incomplete. Waiting for manual configuration..."
    fi
else
    echo "[config] Found existing $WG_CONF"
fi

# Ensure the config exists or wait/fail
if [ -f "$WG_CONF" ]; then
    echo "[wireguard] starting wg-quick up wg0..."
    wg-quick up wg0
    
    # Keep the container running
    # Utilizing a trap to handle shutdown gracefully could be better, but for now simple sleep/tail
    trap "wg-quick down wg0; exit" TERM INT
    
    echo "[wireguard] started. Interface info:"
    wg show
    
    sleep infinity &
    wait
else
    echo "[wireguard] No configuration found. Sleeping..."
    sleep infinity
fi
