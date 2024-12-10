ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS sdk-builder
MAINTAINER Enrique Belarte Luque <ebelarte@redhat.com>
ARG AWS_SDK_CPP_VERSION=1.11.463
# Install packages
RUN INSTALL_PKGS="clang unzip cmake zlib-devel openssl-devel libcurl-devel git p11-kit-devel json-c-devel" \
    && dnf config-manager --set-enabled crb \
    && dnf install -y --setopt=tsflags=nodocs $INSTALL_PKGS \
    && dnf clean all \
    && rm -rf /var/cache/yum
# Install AWS SDK C++ 
RUN curl -o ~/aws-sdk-cpp.tar.gz -L https://github.com/aws/aws-sdk-cpp/archive/$AWS_SDK_CPP_VERSION.tar.gz && \
    mkdir ~/aws-sdk-cpp-src && \
    tar -C ~/aws-sdk-cpp-src --strip-components=1 -zxf ~/aws-sdk-cpp.tar.gz && \
    cd ~/aws-sdk-cpp-src && ./prefetch_crt_dependency.sh && \
    mkdir ~/aws-sdk-cpp-src/sdk_build && \
    cd ~/aws-sdk-cpp-src/sdk_build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_ONLY="kms;acm-pca" -DENABLE_TESTING=OFF -DCMAKE_INSTALL_PREFIX=$HOME/aws-sdk-cpp -DBUILD_SHARED_LIBS=OFF && \
    make && make install 
# Clone PKCS11 implementation to use AWS KMS as backend
RUN git clone https://github.com/JackOfMostTrades/aws-kms-pkcs11.git && \
    cd aws-kms-pkcs11 && \
    AWS_SDK_PATH=~/aws-sdk-cpp make

FROM ${BASE_IMAGE}
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION
ARG AWS_KMS_TOKEN
# Set enviroment variables for AWS auth
ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
ENV AWS_KMS_TOKEN=$AWS_KMS_TOKEN
# Install packages
RUN INSTALL_PKGS="openssl openssl-pkcs11 kernel-devel unzip less" \
    && dnf install -y --setopt=tsflags=nodocs $INSTALL_PKGS \
    && dnf -y clean all \
    && rm -rf /var/cache/yum
# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install
# Copy the library from previous build step
COPY --from=sdk-builder /aws-kms-pkcs11/aws_kms_pkcs11.so /usr/lib64/pkcs11/
# Copy configuration files for aws-kms-pkcs11 library
COPY openssl/config.json openssl/x509.genkey openssl/openssl-pkcs11.conf /etc/aws-kms-pkcs11/
# Copy shell script to update config
COPY --chmod=0755 scripts/configure_pkcs.sh /bin/configure_pkcs.sh

