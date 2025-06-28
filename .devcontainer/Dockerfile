FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04
ENV PYTHON_VERSION_MAJOR=3.12
ENV PYTHON_VERSION_PATCH=11
ENV PYTHON_VERSION=${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_PATCH}

# Install essential tools
RUN apt-get update && apt-get install -y \
    software-properties-common curl wget unzip nano vim htop postgresql-client \
    lsof strace gdb net-tools dnsutils iputils-ping tcpdump nmap unminimize \
    jq git less tree tmux rsync zip unzip lldb gdb cmake build-essential libclang-dev groff \
    pkg-config man man-db manpages manpages-dev manpages-posix manpages-posix-dev info install-info \
    libpq-dev libsqlite3-dev libffi-dev libssl-dev libbz2-dev libexpat1-dev zlib1g-dev \
    && apt-get clean

RUN yes | unminimize

WORKDIR /usr/src

RUN git clone https://github.com/python/cpython.git && \
    cd cpython && \
    git checkout tags/v${PYTHON_VERSION} && \
    git clean -xfd && \
    ./configure --enable-loadable-sqlite-extensions --prefix=/opt/python-${PYTHON_VERSION} \
        --enable-shared --with-computed-gotos --with-system-expat --with-system-ffi \
        --with-dbmliborder=gdbm:ndbm --with-ensurepip=install && \
    make -j$(nproc) && \
    make altinstall && \
    echo "/opt/python-${PYTHON_VERSION}/lib" > /etc/ld.so.conf.d/python.conf && \
    ldconfig

ENV LD_LIBRARY_PATH="/opt/python-${PYTHON_VERSION}/lib:${LD_LIBRARY_PATH}"
ENV PATH="/opt/python-${PYTHON_VERSION}/bin:${PATH}"

RUN ln -sf /opt/python-${PYTHON_VERSION}/bin/python${PYTHON_VERSION_MAJOR} /usr/bin/python3 && \
    ln -sf /opt/python-${PYTHON_VERSION}/bin/python${PYTHON_VERSION_MAJOR} /usr/bin/python

# Bootstrap pip and install Poetry dependencies
RUN python -m ensurepip --default-pip
RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel --root-user-action ignore
RUN python -m pip install --no-cache-dir --root-user-action ignore poetry 

# Install Docker CLI and Compose (without the daemon)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli docker-compose-plugin

# Ensure the vscode user can use Docker CLI (uses host daemon via mounted socket)
RUN groupadd docker && usermod -aG docker vscode


USER 1000:1000
ENV HOME="/home/vscode"
ENV PATH="${HOME}/.local/bin/:${PATH}"
RUN poetry config virtualenvs.in-project true

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="${HOME}/.cargo/bin:${PATH}"

# Install and update Foundry to latest version
RUN curl -L https://foundry.paradigm.xyz | bash && \
    ~/.foundry/bin/foundryup

# Always load variables from .env file located in cwd on shell start
RUN echo "set -a; [[ -f .env ]] && source .env; set +a" >> ${HOME}/.zshrc

RUN git config --global user.email "kirill@ongrid.pro" && \
    git config --global user.name "Kirill Varlamov" && \
    git config --global core.editor "vim" && \
    git config --global init.defaultBranch "main" && \
    git config --global core.hooksPath .githooks  && \
    # less doesn't clear git log output on exit 
    git config --global core.pager 'less -X'