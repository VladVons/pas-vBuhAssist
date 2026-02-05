#!/bin/bash
# Created: 2026.02.02
# Vladimir Vons, VladVons@gmail.com


Install()
{
  apt update
  apt dist-upgrade

  apt install --no-install-recommends \
    binutils build-essential libgcc-s1

  # https://sourceforge.net/projects/lazarus/files/Lazarus%20Linux%20amd64%20DEB/
  dpkg -i \
    fpc-src_3.2.2-210709_amd64.deb \
    fpc-laz_3.2.2-210709_amd64.deb \
    lazarus-project_4.4.0-0_amd64.deb

  dpkg -l | grep fpc
  apt -f install
  apt autoremove
}

HTTP_SSL()
{
  apt install --no-install-recommends \ 
    libssl3 openssl

  ln -s /usr/lib/x86_64-linux-gnu/libssl.so.3 /usr/lib/x86_64-linux-gnu/libssl.so
  ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so.3 /usr/lib/x86_64-linux-gnu/libcrypto.so
  ldconfig
}

#Install
#HTTP_SSL
