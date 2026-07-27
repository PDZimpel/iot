ARG CUDA_IMAGE=12.6.3-devel-ubuntu20.04
FROM nvidia/cuda:${CUDA_IMAGE}

ARG CMAKE_VERSION=4.3.4
ARG GCC_VERSION=15
ARG NINJA_VERSION=1.13.2

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      software-properties-common \
      ca-certificates \
      curl \
      wget \
      git \
      zip \
      unzip \
      tar \
      pkg-config \
      autoconf \
      automake \
      autoconf-archive \
      libtool \
      m4 \
      bison \
      flex \
      gperf \
      perl \
      python3 \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update && apt-get install -y --no-install-recommends \
      gcc-${GCC_VERSION} \
      g++-${GCC_VERSION} \
    && rm -rf /var/lib/apt/lists/*

ENV CC=/usr/bin/gcc-${GCC_VERSION}
ENV CXX=/usr/bin/g++-${GCC_VERSION}

RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
         amd64) CMAKE_ARCH=x86_64 ;; \
         arm64) CMAKE_ARCH=aarch64 ;; \
         *) echo "unsupported architecture: $ARCH" >&2; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.tar.gz" \
       -o /tmp/cmake.tar.gz \
    && tar -xzf /tmp/cmake.tar.gz -C /opt \
    && rm /tmp/cmake.tar.gz \
    && ln -s /opt/cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH} /opt/cmake

RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
         amd64) NINJA_ARCH=linux ;; \
         arm64) NINJA_ARCH=linux-aarch64 ;; \
         *) echo "unsupported architecture: $ARCH" >&2; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-${NINJA_ARCH}.zip" \
       -o /tmp/ninja.zip \
    && unzip -o /tmp/ninja.zip -d /opt/ninja \
    && rm /tmp/ninja.zip \
    && chmod +x /opt/ninja/ninja
ENV PATH=/opt/ninja:/opt/cmake/bin:${PATH}
ENV VCPKG_ROOT=/opt/vcpkg
RUN git clone --depth 1 https://github.com/microsoft/vcpkg.git ${VCPKG_ROOT} \
    && ${VCPKG_ROOT}/bootstrap-vcpkg.sh -disableMetrics
ENV PATH=${VCPKG_ROOT}:${PATH}
ENV VCPKG_BINARY_SOURCES="clear;files,/opt/vcpkg-cache,readwrite"
RUN mkdir -p /opt/vcpkg-cache

WORKDIR /workspace
CMD ["bash", "./docker/build.sh"]
