FROM ubuntu:25.04

ENV DEBIAN_FRONTEND=noninteractive

# Enable source repos (DEB822 format in Ubuntu 25.04)
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources

# Install build deps for kdeconnect via build-dep
RUN apt-get update -qq && \
    apt-get install -y -qq build-essential cmake extra-cmake-modules git dpkg-dev && \
    apt-get build-dep -y kdeconnect && \
    apt-get install -y -qq libkf6itemmodels-dev libei-dev

# Clone KDE Connect source
RUN git clone --depth 1 https://invent.kde.org/network/kdeconnect-kde.git /kdeconnect-src

# Patch loopback to act as a phone (swap in/out capabilities)
RUN sed -i 's|return KdeConnectConfig::instance().deviceInfo();|DeviceInfo info = KdeConnectConfig::instance().deviceInfo();\n    return DeviceInfo(info.id + QStringLiteral("_loopback"),\n                     info.certificate,\n                     QStringLiteral("Galaxy S25"),\n                     DeviceType::Phone,\n                     info.protocolVersion,\n                     info.outgoingCapabilities,\n                     info.incomingCapabilities);|' \
    /kdeconnect-src/core/backends/loopback/loopbackdevicelink.cpp

# Configure with loopback
RUN mkdir /kdeconnect-build && cd /kdeconnect-build && \
    cmake /kdeconnect-src \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release \
      -DLOOPBACK_ENABLED=ON \
      -DBUILD_TESTING=OFF \
      -DWITH_X11=OFF

# Build
RUN cd /kdeconnect-build && cmake --build . --parallel $(nproc)

# Collect artifacts
RUN cd /kdeconnect-build && DESTDIR=/install cmake --install . && \
    mkdir -p /output && \
    find /install -name "kdeconnectd" -exec cp {} /output/ \; && \
    find /install -name "libkdeconnectcore.so*" -exec cp -a {} /output/ \; && \
    find /install -name "libkdeconnectinterfaces.so*" -exec cp -a {} /output/ \; && \
    echo "=== Build artifacts ===" && ls -la /output/
