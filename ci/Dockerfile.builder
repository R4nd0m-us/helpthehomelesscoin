FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Build and base stuff
RUN apt-get update && apt-get install -y \
    git \
    gcc-10 \
    g++-10 \
    autotools-dev \
    libtool \
    m4 \
    automake \
    autoconf \
    pkg-config \
    zlib1g-dev \
    libssl-dev \
    curl \
    ccache \
    bsdmainutils \
    cmake \
    python3 \
    python3-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set GCC 10 as default
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100

# Python stuff
RUN pip3 install pyzmq

# dash_hash - fix the repository reference
RUN git clone https://github.com/HTHcoin/Help-The-Homeless-Coin-0.14
RUN cd Help-The-Homeless-Coin-0.14 && python3 setup.py install

ARG USER_ID=1000
ARG GROUP_ID=1000

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID}
ENV GROUP_ID ${GROUP_ID}
RUN groupadd -g ${GROUP_ID} HelpTheHomelessCoin
RUN useradd -u ${USER_ID} -g HelpTheHomelessCoin -s /bin/bash -m -d /HelpTheHomelessCoin HelpTheHomelessCoin

# Extra packages
ARG BUILD_TARGET=linux64
ADD matrix.sh /tmp/matrix.sh
RUN . /tmp/matrix.sh && \
  if [ -n "$DPKG_ADD_ARCH" ]; then dpkg --add-architecture "$DPKG_ADD_ARCH" ; fi && \
  if [ -n "$PACKAGES" ]; then apt-get update && apt-get install -y --no-install-recommends --no-upgrade $PACKAGES; fi

# Make sure std::thread and friends is available
# Will fail on non-win builds, but we ignore this
RUN \
  update-alternatives --set i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix; \
  update-alternatives --set i686-w64-mingw32-g++  /usr/bin/i686-w64-mingw32-g++-posix; \
  update-alternatives --set x86_64-w64-mingw32-gcc  /usr/bin/x86_64-w64-mingw32-gcc-posix; \
  update-alternatives --set x86_64-w64-mingw32-g++  /usr/bin/x86_64-w64-mingw32-g++-posix; \
  exit 0

RUN mkdir /Help-The-Homeless-Coin-0.14-src && \
  mkdir -p /cache/ccache && \
  mkdir /cache/depends && \
  mkdir /cache/sdk-sources && \
  chown $USER_ID:$GROUP_ID /HelpTheHomelessCoin-src && \
  chown $USER_ID:$GROUP_ID /cache && \
  chown $USER_ID:$GROUP_ID /cache -R
WORKDIR /HelpTheHomelessCoin-src

USER HelpTheHomelessCoin
