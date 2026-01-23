FROM debian:bookworm

RUN apt-get update && apt-get install -y wireguard iproute2 iptables openresolv tcpdump iputils-ping \
    && rm -rf /var/lib/apt/lists/*

COPY ./redirect_pkg_handler /redirect_pkg_handler
RUN chmod +x /redirect_pkg_handler

COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
