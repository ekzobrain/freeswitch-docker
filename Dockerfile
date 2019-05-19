FROM debian:stretch

# Allow to pass user uid/gid at build time
ARG USER_UID="999"
ARG USER_GID="999"

# Add FreeSwitch repo
RUN apt-get update \
    && apt-get install -y gnupg2 wget \
    && wget -O - https://files.freeswitch.org/repo/deb/freeswitch-1.8/fsstretch-archive-keyring.asc | apt-key add - \
    && echo "deb http://files.freeswitch.org/repo/deb/freeswitch-1.8/ stretch main" > /etc/apt/sources.list.d/freeswitch.list \
    && echo "deb-src http://files.freeswitch.org/repo/deb/freeswitch-1.8/ stretch main" >> /etc/apt/sources.list.d/freeswitch.list

# Explicitly set user/group IDs
RUN groupadd -r freeswitch --gid=$USER_GID \
    && useradd -r -g freeswitch --uid=$USER_UID freeswitch

# Make the "en_US.UTF-8" locale so freeswitch will be utf-8 enabled by default
RUN apt-get update \
    && apt-get install -y locales \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Install FreeSwitch
RUN apt-get update \
    && apt-get install -y freeswitch-meta-all \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Disable IPv6 bindings, enable Event Socket connections from outside container
RUN rm /etc/freeswitch/sip_profiles/*-ipv6.xml \
    && sed -i 's/value="::"/value="0.0.0.0"/g' /etc/freeswitch/autoload_configs/event_socket.conf.xml \
    && sed -i 's/<!--<param name="apply-inbound-acl" value="loopback.auto"\/>-->/<param name="apply-inbound-acl" value="any_v4.auto"\/>/g' /etc/freeswitch/autoload_configs/event_socket.conf.xml

# Limits Configuration
COPY build/freeswitch.limits.conf /etc/security/limits.d/

# SIP ports
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp 5061/tcp 5061/udp 5081/tcp 5081/udp

# WebRTC ports
EXPOSE 5066/tcp 7443/tcp

# EventSocket port
EXPOSE 8021/tcp

# RTP ports
EXPOSE 64535-65535/udp

# allow to override config files and tmp dir to get core dumps in case of crash
VOLUME ["/etc/freeswitch", "/tmp"]

CMD ["freeswitch", "-c", "-nonat", "-u", "freeswitch", "-g", "freeswitch"]
