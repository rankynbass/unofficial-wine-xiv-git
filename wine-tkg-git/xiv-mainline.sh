#!/bin/bash

sed -i 's/pkgname=wine-tkg/pkgname=unofficial-wine-xiv/' non-makepkg-build.sh
sed -i 's/_use_staging="true"/_use_staging="false"/' customization.cfg

for f in wine-tkg-userpatches/vanilla/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done