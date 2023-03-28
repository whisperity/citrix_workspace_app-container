FROM ubuntu:22.04
MAINTAINER Eduard A. <github-mail@container42.de>

ENV DEBIAN_FRONTEND noninteractive

RUN echo 'Package: firefox*'                 >> /etc/apt/preferences.d/no-snap-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/no-snap-firefox && \
    echo 'Pin-Priority: 501'                 >> /etc/apt/preferences.d/no-snap-firefox

# Need to run the 'add-apt-repository' twice because otherwise the GPG command
# will simply break. Sounds like a weird bug...
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y wget curl gpg software-properties-common && \
      (add-apt-repository --yes ppa:mozillateam/ppa || true) && \
      add-apt-repository --yes ppa:mozillateam/ppa && \
      apt-get update && \
    apt-get purge -y software-properties-common && \
    apt-get install -y vim firefox apt-utils xdg-utils libwebkit2gtk-4.0-37 libgtk2.0-0 libxmu6 libxpm4 dbus-x11 xauth libcurl4 openssh-server && \
    mkdir /var/run/sshd && \
      echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config && \
      echo "AddressFamily inet"       >> /etc/ssh/sshd_config && \
    sed -i '1iauth sufficient pam_permit.so' /etc/pam.d/sshd && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*

RUN wget $(wget -O - https://www.citrix.com/downloads/workspace-app/linux/workspace-app-for-linux-latest.html | sed -ne '/icaclient_.*deb/ s/<a .* rel="\(.*\)" id="downloadcomponent">/https:\1/p' | sed -e 's/\r//g') -O /tmp/icaclient.deb && \
    apt-get update && \
    apt-get install --no-install-recommends -y -f /tmp/icaclient.deb && \
    rm /tmp/icaclient.deb && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* && \
    cd /opt/Citrix/ICAClient/keystore/cacerts/ && \
      ln -s /usr/share/ca-certificates/mozilla/* /opt/Citrix/ICAClient/keystore/cacerts/ && \
      c_rehash /opt/Citrix/ICAClient/keystore/cacerts/

RUN useradd -m -s /bin/bash receiver && \
    echo "pref(\"browser.tabs.warnOnClose\", false);"                       >> /usr/lib/firefox/browser/defaults/preferences/syspref.js && \
    echo "pref(\"browser.startup.homepage\", \"https://duckduckgo.com/\");" >> /usr/lib/firefox/browser/defaults/preferences/syspref.js

USER receiver
WORKDIR /home/receiver
RUN mkdir -p .local/share/applications .config && \
    xdg-mime default wfica.desktop application/x-ica

USER root
CMD ["/usr/sbin/sshd", "-D"]
