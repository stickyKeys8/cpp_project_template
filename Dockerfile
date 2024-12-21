# syntax=docker/dockerfile:1

FROM library/ubuntu:24.04@sha256:80dd3c3b9c6cecb9f1667e9290b3bc61b78c2678c02cbdae5f0fea92cc6734ab AS base

# Shell
ENV SHELL=/bin/bash
ENV TERM=xterm-256color
SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

# Create user
RUN userdel -r ubuntu

ARG USERNAME=michael
ARG USER_UID=1000
ARG USER_GID=1000

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
            rsync \
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

# Install clang
ARG CLANG_VERSION=19
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
        wget https://apt.llvm.org/llvm.sh && \
        chmod +x llvm.sh && \
        ./llvm.sh ${CLANG_VERSION} && \
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
        add-apt-repository ppa:ubuntu-toolchain-r/test && \
        apt update && \
        apt install gcc-${GCC_VERSION} g++-${GCC_VERSION} -y

# Cleanup
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 60 --slave /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION}
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 60 --slave /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION}

RUN apt autoremove -y

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
RUN --mount=type=cache,target=${HOME}/.pyenv/cache,sharing=locked,uid=${USER_UID},gid=${USER_GID} \
    pyenv install ${PYTHON_VERSION} && pyenv global ${PYTHON_VERSION}

# Pip
RUN --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked,uid=${USER_UID},gid=${USER_GID} \
    pip install --upgrade pip && pip install wheel

RUN --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked,uid=${USER_UID},gid=${USER_GID} <<__RUN
    pip install cmake==3.31.2 --user
    pip install ninja==1.11.1 --user
    pip install conan==2.10.2 --user
    pip install poetry==1.8.5 --user
__RUN

# Poetry
RUN poetry config virtualenvs.in-project true
RUN poetry config virtualenvs.prefer-active-python true

RUN conan profile detect
ARG CONAN_HOME=${HOME}/.conan2

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

# Create a Conan global config
ARG GLOBAL_CONF=${CONAN_HOME}/global.conf
ARG CONAN_CACHE=${CONAN_HOME}/conan_cache

RUN <<__RUN
    touch ${GLOBAL_CONF}
    echo "tools.cmake.cmaketoolchain:generator=Ninja" >> ${GLOBAL_CONF}
    echo "core:default_profile=gcc" >> ${GLOBAL_CONF}
    echo "core:default_build_profile=gcc" >> ${GLOBAL_CONF}
    echo "core.cache:storage_path=${CONAN_CACHE}/conan_storage" >> ${GLOBAL_CONF}
    echo "core.download:download_cache=${CONAN_CACHE}/conan_downloads" >> ${GLOBAL_CONF}
    echo "core.sources:download_cache=${CONAN_CACHE}/conan_sources" >> ${GLOBAL_CONF}
__RUN

# Install project dependencies
COPY --chown=${USER_UID}:${USER_GID} conanfile.py conanfile.py

RUN --mount=type=cache,target=${CONAN_CACHE},sharing=locked,uid=${USER_UID},gid=${USER_GID} \
        conan install . --build missing --profile=gcc && \
        rsync -rgp ${CONAN_CACHE} ${HOME}

RUN ln -s ${HOME}/conan_cache ${CONAN_CACHE}