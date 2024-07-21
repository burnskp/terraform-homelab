FROM mcr.microsoft.com/devcontainers/base:jammy
ARG TARGETPLATFORM
ARG TERRAFORM_VERSION
ENV DEBIAN_FRONTEND=noninteractive

# Install supporting applications
RUN apt-get update \
    && apt-get -y install \
    curl \
    git \
    gnupg \
    jq \
    make \
    python3 \
    python3-pip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | tee /etc/apt/trusted.gpg.d/hashicorp.asc > /dev/null \
    && echo "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && if [ "${TERRAFORM_VERSION}" = "latest" ]; then \
    && apt-get -y install terraform; else \
    && apt-get -y install terraform=${TERRAFORM_VERSION}; fi \
    && rm -rf /var/lib/apt/lists/*

# Install trivy
RUN curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | tee /etc/apt/trusted.gpg.d/trivy.asc > /dev/null \
    && echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get -y install trivy \
    && rm -rf /var/lib/apt/lists/*

# Install terrascan
RUN case "${TARGETPLATFORM}" in \
    "linux/amd64") \
    curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | jq -r '.assets[] | select(.name | contains("Linux_x86_64")) | .browser_download_url')" -o terrascan.tar.gz \
    ;; \
    "linux/arm64") \
    curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | jq -r '.assets[] | select(.name | contains("Linux_arm64")) | .browser_download_url')" -o terrascan.tar.gz \
    ;; \
    *) \
    echo "Unsupported platform: ${TARGETPLATFORM}" \
    ;; \
    esac \
    && tar -xzf terrascan.tar.gz \
    && mv terrascan /usr/local/bin/terrascan \
    && chmod +x /usr/local/bin/terrascan \
    && rm terrascan.tar.gz

# Install tflint
RUN case "${TARGETPLATFORM}" in \
    "linux/amd64") \
    curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | jq -r '.assets[] | select(.name | contains("linux_amd64.zip")) | .browser_download_url')" -o tflint.zip \
    ;; \
    "linux/arm64") \
    curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | jq -r '.assets[] | select(.name | contains("linux_arm64.zip")) | .browser_download_url')" -o tflint.zip \
    ;; \
    *) \
    echo "Unsupported platform: ${TARGETPLATFORM}" \
    ;; \
    esac \
    && unzip tflint.zip \
    && mv tflint /usr/local/bin/tflint \
    && chmod +x /usr/local/bin/tflint \
    && rm tflint.zip

## Install infracost
RUN case "${TARGETPLATFORM}" in \
    "linux/amd64") \
    curl -L "$(curl -s https://api.github.com/repos/infracost/infracost/releases/latest | jq -r '.assets[] | select(.name | test ("linux-amd64.tar.gz$")) | .browser_download_url')" -o infracost.tar.gz \
    && tar -xzf infracost.tar.gz \
    && mv infracost-linux-amd64 /usr/local/bin/infracost \
    ;; \
    "linux/arm64") \
    curl -L "$(curl -s https://api.github.com/repos/infracost/infracost/releases/latest | jq -r '.assets[] | select(.name | test ("linux-arm64.tar.gz$")) | .browser_download_url')" -o infracost.tar.gz \
    && tar -xzf infracost.tar.gz \
    && mv infracost-linux-arm64 /usr/local/bin/infracost \
    ;; \
    *) \
    echo "Unsupported platform: ${TARGETPLATFORM}" \
    ;; \
    esac \
    && chmod +x /usr/local/bin/infracost \
    && rm infracost.tar.gz

# Install terraform-docs
RUN case "${TARGETPLATFORM}" in \
    "linux/amd64") \
    curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url')" -o terraform-docs.tar.gz \
    ;; \
    "linux/arm64") \
    curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | jq -r '.assets[] | select(.name | contains("linux-arm64")) | .browser_download_url')" -o terraform-docs.tar.gz \
    ;; \
    *) \
    echo "Unsupported platform: ${TARGETPLATFORM}" \
    ;; \
    esac \
    && tar -xzf terraform-docs.tar.gz \
    && mv terraform-docs /usr/local/bin/terraform-docs \
    && chmod +x /usr/local/bin/terraform-docs \
    && rm terraform-docs.tar.gz
