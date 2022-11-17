FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"

RUN \
  echo "**** install runtime dependencies ****" && \
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null && \
  apt-get install apt-transport-https --yes && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
  apt-get update && \
  apt-get install -y \
    wget \
    helm \
    git \
    jq \
    libatomic1 \
    nano \
    net-tools \
    netcat \
    python3-pip \
    pip \
    sshpass \
    sudo && \
    yes | pip install hvac && \
    yes | pip install pyvmomi && \
    yes | pip install ansible-core==2.13.2 && \
    yes | pip install --upgrade git+https://github.com/vmware/vsphere-automation-sdk-python.git && \
    ansible-galaxy collection install ansible.posix && \
    ansible-galaxy collection install kubernetes.core && \
    ansible-galaxy collection install community.general && \
    ansible-galaxy collection install community.hashi_vault && \
    ansible-galaxy collection install community.kubernetes && \
    ansible-galaxy collection install ansible.posix && \
    ansible-galaxy collection install community.vmware && \
    ansible-galaxy collection install ansible.windows && \
    wget -O docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-20.10.21.tgz && \
    tar --extract --file docker.tgz --strip-components 1 --directory /usr/local/bin/ --no-same-owner 'docker/docker' && \
    rm docker.tgz && \
    docker --version && \
  echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  curl -o \
    /tmp/code-server.tar.gz -L \
    "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C \
    /app/code-server --strip-components=1 && \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /config/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443