# syntax=docker/dockerfile:1
FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

# These ARGs are populated by your GitHub Workflow matrix
ARG REPO
ARG PATTERN
ARG TITLE

LABEL maintainer="davidphillips2"

# WEBKIT_DISABLE_COMPOSITING_MODE prevents flickering in KasmVNC/Selkies
ENV TITLE=${TITLE} \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NO_GAMEPAD=true \
    LC_ALL=en_GB.UTF-8 \
    WEBKIT_DISABLE_COMPOSITING_MODE=1

RUN \
  echo "**** install initial dependencies ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    software-properties-common locales curl jq && \
  \
  echo "**** add PPA and install packages ****" && \
  add-apt-repository -y ppa:xtradeb/apps && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    firefox gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 \
    gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 gstreamer1.0-tools gstreamer1.0-x libgstreamer-plugins-bad1.0 \
    libmspack0 libwebkit2gtk-4.1-0 libwx-perl libfuse2 && \
  \
  echo "**** fetching from ${REPO} ****" && \
  DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/${REPO}/releases" | jq -r --arg PATTERN "$PATTERN" '.[0].assets[] | select(.name | test($PATTERN)) | .browser_download_url' | head -n 1) && \
  \
  if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then echo "ERROR: Could not find a download matching $PATTERN in $REPO"; exit 1; fi && \
  \
  cd /tmp && \
  curl -o /tmp/orca.app -L "${DOWNLOAD_URL}" && \
  chmod +x /tmp/orca.app && \
  ./orca.app --appimage-extract && \
  mv squashfs-root /opt/orcaslicer && \
  \
  echo "**** generate locale ****" && \
  locale-gen en_GB.UTF-8 && \
  \
  echo "**** set permissions for the abc user ****" && \
  chown -R abc:abc /opt/orcaslicer && \
  \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf /var/lib/apt/lists/* /tmp/*

# Standard ports and volumes
EXPOSE 3001
VOLUME /config

# 1. Force the app to use /config for its internal profiles/settings
# 2. Disable the built-in auto-updater which often causes the 'ota' crash
ENV HOME=/config \
    XDG_CONFIG_HOME=/config \
    APPIMAGE_EXIT_AFTER_EXTRACT=1 \
    I_STILL_WANT_TO_RUN_AS_ROOT=false

WORKDIR /opt/orcaslicer

# Ensure the extracted files are writable by the user running the app
RUN chown -R abc:abc /opt/orcaslicer /config

USER abc

# Pass the config-dir flag directly to OrcaSlicer to force it to use the volume
CMD ["./AppRun", "--no-sandbox", "--config-dir", "/config"]
