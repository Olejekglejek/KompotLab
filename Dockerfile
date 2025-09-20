ARG base_image=alpine:3.19
FROM --platform=linux/amd64 ${base_image}

# Install system dependencies and Python
RUN apk add --no-cache \
    python3 \
    py3-pip \
    python3-dev \
    openssh-client \
    sshpass \
    git \
    curl \
    rsync \
    sudo \
    bash \
    ca-certificates \
    wget \
    unzip \
    tar \
    gzip \
    jq \
    openssl \
    build-base \
    libffi-dev \
    openssl-dev \
    musl-dev \
    linux-headers

# Create symlinks for python and pip
RUN ln -sf python3 /usr/bin/python && \
    ln -sf pip3 /usr/bin/pip

# Set working directory
WORKDIR /workspace

# Copy requirements and install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip --break-system-packages && \
    pip install --no-cache-dir -r /tmp/requirements.txt --break-system-packages

# Install additional Python tools for validation
RUN pip install --no-cache-dir --break-system-packages \
    flake8 \
    yamllint \
    ansible-lint

# Install Azure CLI
RUN pip install --no-cache-dir azure-cli --break-system-packages

# Install PowerShell Core
RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.4.4/powershell-7.4.4-linux-musl-x64.tar.gz -O /tmp/powershell.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    rm /tmp/powershell.tar.gz

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubelogin (Azure Kubernetes Service login plugin)
RUN wget -q https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip -O /tmp/kubelogin.zip && \
    unzip /tmp/kubelogin.zip -d /tmp && \
    mv /tmp/bin/linux_amd64/kubelogin /usr/local/bin/ && \
    chmod +x /usr/local/bin/kubelogin && \
    rm -rf /tmp/kubelogin.zip /tmp/bin

# Install Bicep CLI
RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64 && \
    chmod +x ./bicep && \
    mv ./bicep /usr/local/bin/bicep

# Install talosctl
RUN wget -q https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-amd64 -O /usr/local/bin/talosctl && \
    chmod +x /usr/local/bin/talosctl

# Copy project files
COPY . /workspace/

# Create directories and set permissions
RUN mkdir -p /root/.ansible /root/.kube /root/.azure && \
    chmod -R 755 /root/.ansible /root/.kube /root/.azure

# Set environment variables
ENV ANSIBLE_STDOUT_CALLBACK=yaml \
    ANSIBLE_CALLBACKS_ENABLED=timer \
    PYTHONUNBUFFERED=1 \
    ANSIBLE_FORCE_COLOR=1 \
    PATH="/usr/local/bin:${PATH}"

# Default command
CMD ["/bin/bash"]
