FROM ubuntu:22.04

ARG S6_OVERLAY_VERSION=v3.1.5.0
ARG S6_OVERLAY_ARCH=x86_64
ARG PLEX_BUILD=linux-x86_64
ARG PLEX_DISTRO=debian
ARG DEBIAN_FRONTEND="noninteractive"
ARG INTEL_NEO_VERSION=20.48.18558
ARG INTEL_IGC_VERSION=1.0.5699
ARG INTEL_GMMLIB_VERSION=20.3.2

RUN \
# Update and get dependencies
    apt-get update && \
    apt-get install -y \
      tzdata \
      curl \
      xz-utils \
      xmlstarlet \
      uuid-runtime \
      unrar \
      cron \
    && \
    \
# Fetch and extract S6 overlay
    curl -L -s \
        "https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" | tar Jxpf - -C / \
    && \
    curl -L -s \
        "https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz" | tar Jxpf - -C / \
    && \
    \
# Add user
    useradd -U -d /config -s /bin/false plex && \
    usermod -G users plex && \
    \
# Setup directories
    mkdir -p \
      /config \
      /transcode \
      /data \
    && \
    \
# Cleanup
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

EXPOSE 32400/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode

ARG AUTOUPDATE=false
ARG TAG=beta
ARG URL=

ENV TAG=${TAG} \
    CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config" \
    \
    TERM="xterm" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    \
    S6_KEEP_ENV=1 \
    S6_SERVICES_GRACETIME=10000 \
    S6_KILL_GRACETIME=5000 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY root/ /

RUN \
# Save version and install
    /installBinary.sh

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1

ENTRYPOINT ["/init"]
