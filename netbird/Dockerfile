FROM debian:bookworm

# 1. 安装基础依赖
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg libelf1 iproute2 tcpdump && \
    rm -rf /var/lib/apt/lists/*

# 2. 添加 NetBird APT 仓库
RUN curl -sSL https://pkgs.netbird.io/debian/public.key | \
        gpg --dearmor -o /usr/share/keyrings/netbird-archive-keyring.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main' \
        > /etc/apt/sources.list.d/netbird.list

# 3. 更新并安装 netbird
RUN apt-get update && \
    apt-get install -y netbird && \
    rm -rf /var/lib/apt/lists/*

COPY ./redirect_pkg_handler /redirect_pkg_handler
RUN chmod +x /redirect_pkg_handler

ENV \
    NETBIRD_BIN="/usr/bin/netbird" \
    NB_LOG_FILE="console,/var/log/netbird/client.log" \
    NB_DAEMON_ADDR="unix:///var/run/netbird.sock" \
    NB_ENTRYPOINT_SERVICE_TIMEOUT="5" \
    NB_ENTRYPOINT_LOGIN_TIMEOUT="5"

COPY ./netbird-entrypoint.sh /usr/local/bin/netbird-entrypoint.sh
RUN chmod +x /usr/local/bin/netbird-entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/netbird-entrypoint.sh" ]