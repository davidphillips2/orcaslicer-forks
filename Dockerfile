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
    NO_GAMEPAD=true 

RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/orcaslicer-logo.png && \
  echo "**** install packages ****" && \
  add-apt-repository ppa:xtradeb/apps && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    firefox \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    libgstreamer-plugins-bad1.0 \
    libmspack0 \
    libwebkit2gtk-4.1-0 \
    libwx-perl && \

  echo "**** fetching from ${REPO} ****" && \
  DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/${REPO}/releases" | jq -r --arg PATTERN "$PATTERN" '.[0].assets[] | select(.name | test($PATTERN)) | .browser_download_url' | head -n 1) && \
  \
  if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then echo "ERROR: Could not find a download matching $PATTERN in $REPO"; exit 1; fi && \
  \
  cd /tmp && \
  curl -o \
    /tmp/orca.app -L \
    "${DOWNLOAD_URL}" && \
  chmod +x /tmp/orca.app && \
  ./orca.app --appimage-extract && \
  mv squashfs-root /opt/orcaslicer && \
  localedef -i en_GB -f UTF-8 en_GB.UTF-8 && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /config/.launchpadlib \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3001
VOLUME /config
