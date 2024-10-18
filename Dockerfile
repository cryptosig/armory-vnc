FROM ubuntu:18.04
MAINTAINER cryptosig <http://github.com/cryptosig>

# Install LXDE, VNC server, Twisted, SWIG and Qt
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y lxde-core lxterminal tightvncserver curl gnupg g++ libcrypto++-dev swig python-dev python-twisted libqtcore4 libqt4-dev python-qt4 pyqt4-dev-tools python-psutil xdg-utils

# Download bitcoin
RUN mkdir /bitcoin
WORKDIR /bitcoin
ENV BITCOIN_VERSION 27.0
ARG BITCOIN_CORE_SIGNATURE=71A3B16735405025D447E8F274810B012346C9A6

RUN curl -SLO "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" \
 && curl -SLO "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc" \
 && curl -SLO "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS"

RUN gpg --keyserver hkps://keys.openpgp.org --refresh-keys \
 && gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ${BITCOIN_CORE_SIGNATURE}
 
# Verify and install download
COPY laanwj-releases.asc /bitcoin
RUN gpg --import laanwj-releases.asc \
 && gpg --verify --status-fd 1 SHA256SUMS.asc SHA256SUMS 2>/dev/null | grep "^\[GNUPG:\] VALIDSIG.*${BITCOIN_CORE_SIGNATURE}\$" \
 && grep "bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" SHA256SUMS | sha256sum -c - \
 && tar -xzf "bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" -C /usr --strip-components=1 \
 && rm "bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" SHA256SUMS.asc SHA256SUMS  

RUN ln -s /bitcoin /root/.bitcoin

# Download armory
RUN mkdir /armory
WORKDIR /armory
ENV ARMORY_VERSION 0.96.5
RUN curl -SLO "https://github.com/goatpig/BitcoinArmory/releases/download/v${ARMORY_VERSION}/armory_${ARMORY_VERSION}_amd64_gcc7.2.deb"
RUN curl -SLO "https://github.com/goatpig/BitcoinArmory/releases/download/v${ARMORY_VERSION}/sha256sum.txt.asc"

# Verify and install download
COPY goatpig-signing-key.asc /armory
RUN gpg --import goatpig-signing-key.asc \
 && gpg --verify --trust-model=always sha256sum.txt.asc \
 && gpg --decrypt --output sha256sum.txt sha256sum.txt.asc \
 && grep "armory_${ARMORY_VERSION}_amd64_gcc7.2.deb" sha256sum.txt | sha256sum -c - \
 && dpkg -i "armory_${ARMORY_VERSION}_amd64_gcc7.2.deb" \
 && rm "armory_${ARMORY_VERSION}_amd64_gcc7.2.deb" sha256sum.txt.asc sha256sum.txt

RUN ln -s /armory /root/.armory

# Set user for VNC server (USER is only for build)
ENV USER root
# Set default password
COPY password.txt .
RUN cat password.txt password.txt | vncpasswd \
 && rm password.txt

# Expose VNC port
EXPOSE 5901


# Copy VNC script that handles restarts
COPY run.sh /opt/
CMD ["/opt/run.sh"]
