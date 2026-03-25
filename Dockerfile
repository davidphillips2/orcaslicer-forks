# syntax=docker/dockerfile:1
FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

# Build Arguments to switch between forks
ARG REPO="Snapmaker/OrcaSlicer"
ARG PATTERN="Ubuntu2404.*AppImage"
ARG TITLE="OrcaSlicer"

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

ENV TITLE=${TITLE} \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NO_GAMEPAD=true

RUN \
  echo "**** install packages ****" && \
  add-apt-repository ppa:xtradeb/apps && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    firefox gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 \
    gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 gstreamer1.0-tools gstreamer1.0-x libgstreamer-plugins-bad1.0 \
    libmspack0 libwebkit2gtk-4.1-0 libwx-perl && \
  \
  echo "**** fetching from ${REPO} ****" && \
  ORCA_TAG=$(curl -sX GET "https://api.github.com/repos/${REPO}/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
  DOWNLOAD_URL=$(curl -sX GET "https://api.github.com/repos/${REPO}/releases/tags/${ORCA_TAG}" \
    | awk "/browser_download_url.*${PATTERN}/{print \$4;exit}" FS='[""]') && \
  \
  cd /tmp && \
  curl -o /tmp/orca.app -L "${DOWNLOAD_URL}" && \
  chmod +x /tmp/orca.app && \
  ./orca.app --appimage-extract && \
  mv squashfs-root /opt/orcaslicer && \
  localedef -i en_GB -f UTF-8 en_GB.UTF-8 && \
  \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf /var/lib/apt/lists/* /tmp/*

EXPOSE 3001
VOLUME /config
