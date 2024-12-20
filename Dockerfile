# syntax=docker/dockerfile:1

FROM ubuntu:24.04 AS base

# Shell
ENV SHELL=/bin/bash
ENV TERM=xterm-256color
SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

ENV BLAH=123

# Create user
ARG USERNAME=michael
ARG USER_UID=1001
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    # Add sudo support
    && apt update \
    && apt install -y sudo locales \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

ENV USER=${USERNAME}    
ENV HOME=/home/${USERNAME}

# Locale setup
ARG LOCALE_US=en_US.UTF-8
RUN locale-gen ${LOCALE_US}
ENV LANG=${LOCALE_US}
ENV LANGUAGE=${LOCALE_US}
RUN update-locale

# System packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
        apt update && apt-get --no-install-recommends install -y \
            software-properties-common \
            bash-completion \
            ccache \
            wget \
            curl \
            make \
            git \
            7zip \
            fzf

# Install Python build dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
        apt update && apt-get --no-install-recommends install -y \
            build-essential \
            libssl-dev \
            zlib1g-dev \
            libbz2-dev \
            libreadline-dev \
            libsqlite3-dev \
            libncursesw5-dev \
            xz-utils \
            tk-dev \
            libxml2-dev \
            libxmlsec1-dev \
            libffi-dev \
            liblzma-dev

# OpenCV build dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
        apt update && apt-get --no-install-recommends install -y \
            libva-dev \
            libvdpau-dev \
            xkb-data \
            libxau-dev \
            libx11-dev \
            libx11-xcb-dev \
            libfontenc-dev \
            libice-dev \
            libsm-dev \
            libxaw7-dev \
            libxcomposite-dev \
            libxcursor-dev \
            libxdamage-dev \
            libxfixes-dev \
            libxi-dev \
            libxinerama-dev \
            libxkbfile-dev \
            libxmu-dev \
            libxmuu-dev \
            libxpm-dev \
            libxrandr-dev \
            libxres-dev \
            libxt-dev \
            libxtst-dev \
            libxv-dev \
            libxxf86vm-dev \
            libxcb-glx0-dev \
            libxcb-render0-dev \
            libxcb-render-util0-dev \
            libxcb-xkb-dev \
            libxcb-icccm4-dev \
            libxcb-image0-dev \
            libxcb-keysyms1-dev \
            libxcb-randr0-dev \
            libxcb-shape0-dev \
            libxcb-sync-dev \
            libxcb-xfixes0-dev \
            libxcb-xinerama0-dev \
            libxcb-dri3-dev \
            libxcb-cursor-dev \
            libxcb-dri2-0-dev \
            libxcb-dri3-dev \
            libxcb-present-dev \
            libxcb-composite0-dev \
            libxcb-ewmh-dev \
            libxcb-res0-dev \
            libxcb-util-dev \
            libxcb-util0-dev

# Install clang
ARG CLANG_VERSION=19
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
        wget https://apt.llvm.org/llvm.sh &&\
        chmod +x llvm.sh &&\
        ./llvm.sh ${CLANG_VERSION} &&\
        apt update && apt-get --no-install-recommends install -y \
            clang-${CLANG_VERSION} \
            clang-tools-${CLANG_VERSION} \
            clang-format-${CLANG_VERSION} \
            clang-tidy-${CLANG_VERSION} \
            libc++-${CLANG_VERSION}-dev

# Install gcc
ARG GCC_VERSION=14
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
        add-apt-repository ppa:ubuntu-toolchain-r/test &&\
        apt update &&\
        apt install gcc-${GCC_VERSION} g++-${GCC_VERSION} -y

# Cleanup
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 60 --slave /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION}
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 60 --slave /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION}

RUN apt autoremove -y
#RUN chown -R michael:michael .
# User
USER ${USER}
WORKDIR ${HOME}

# Python
RUN curl https://pyenv.run | bash

RUN echo 'alias la="ls -lah"' >> ${HOME}/.bashrc
RUN echo 'eval "$(pyenv init -)"' >> ${HOME}/.bashrc
RUN echo 'eval "$(pyenv virtualenv-init -)"' >> ${HOME}/.bashrc
RUN echo 'eval "$(pyenv init -)"' >> ${HOME}/.profile
RUN echo 'eval "$(pyenv virtualenv-init -)"' >> ${HOME}/.profile

ENV PYTHONUNBUFFERED=1
ENV PYENV_SHELL=bash
ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="$PATH:${HOME}/.local/bin:${PYENV_ROOT}/bin:${PYENV_ROOT}/shims"

ARG PYTHON_VERSION=3.13.0
RUN --mount=type=cache,target=${HOME}/.pyenv/cache,sharing=locked,uid=${USER_UID},gid=${USER_UID} \
    pyenv install ${PYTHON_VERSION} && pyenv global ${PYTHON_VERSION}

# Pip
RUN --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked,uid=${USER_UID},gid=${USER_UID} \
    pip install --upgrade pip && pip install wheel

RUN --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked,uid=${USER_UID},gid=${USER_UID} <<__RUN
    pip install cmake==3.31.2 --user
    pip install ninja==1.11.1 --user
    pip install conan==2.10.2 --user
    pip install poetry==1.8.5 --user
__RUN

# Poetry
RUN poetry config virtualenvs.in-project true
RUN poetry config virtualenvs.prefer-active-python true

# Create Conan profiles for clang and gcc
ARG CONAN_HOME=/home/michael/.conan2
RUN mkdir -p ${CONAN_HOME}/profiles

ARG CLANG_PROFILE=${CONAN_HOME}/profiles/clang
RUN <<__RUN
    touch ${CLANG_PROFILE}
    echo "[settings]" >> ${CLANG_PROFILE}
    echo "os=Linux" >> ${CLANG_PROFILE}
    echo "arch=x86_64" >> ${CLANG_PROFILE}
    echo "build_type=Release" >> ${CLANG_PROFILE}
    echo "compiler=clang" >> ${CLANG_PROFILE}
    echo "compiler.cppstd=gnu23" >> ${CLANG_PROFILE}
    echo "compiler.libcxx=libc++" >> ${CLANG_PROFILE}
    echo "compiler.version=${CLANG_VERSION}" >> ${CLANG_PROFILE}
    echo "[buildenv]" >> ${CLANG_PROFILE}
    echo "CC=/usr/bin/clang" >> ${CLANG_PROFILE}
    echo "CXX=/usr/bin/clang++" >> ${CLANG_PROFILE}
__RUN

ARG GCC_PROFILE=${CONAN_HOME}/profiles/gcc
RUN <<__RUN
    touch ${GCC_PROFILE}
    echo "[settings]" >> ${GCC_PROFILE}
    echo "os=Linux" >> ${GCC_PROFILE}
    echo "arch=x86_64" >> ${GCC_PROFILE}
    echo "build_type=Release" >> ${GCC_PROFILE}
    echo "compiler=gcc" >> ${GCC_PROFILE}
    echo "compiler.cppstd=gnu23" >> ${GCC_PROFILE}
    echo "compiler.libcxx=libstdc++" >> ${GCC_PROFILE}
    echo "compiler.version=${GCC_VERSION}" >> ${GCC_PROFILE}
    echo "[buildenv]" >> ${GCC_PROFILE}
    echo "CC=/usr/bin/gcc" >> ${GCC_PROFILE}
    echo "CXX=/usr/bin/g++" >> ${GCC_PROFILE}
__RUN

RUN mkdir -p /home/michael/.cache/conan

# Create a Conan global config
ARG GLOBAL_CONF=${CONAN_HOME}/global.conf
RUN <<__RUN
    touch ${GLOBAL_CONF}
    echo "tools.cmake.cmaketoolchain:generator=Ninja" >> ${GLOBAL_CONF}
    echo "core:default_profile=gcc" >> ${GLOBAL_CONF}
    echo "core:default_build_profile=gcc" >> ${GLOBAL_CONF}
    echo "core.sources:download_cache=/home/michael/.cache/conan" >> ${GLOBAL_CONF} #TODO
__RUN

VOLUME /home/michael/.cache/conan
#ENV CMAKE_CXX_COMPILER_LAUNCHER=ccache
#ENV CMAKE_C_COMPILER_LAUNCHER=ccache