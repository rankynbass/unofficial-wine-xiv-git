#!/bin/bash

sed -i 's/pkgname=wine-tkg/pkgname=unofficial-wine-xiv/' non-makepkg-build.sh
sed -i 's/_use_staging="false"/_use_staging="true"/' customization.cfg

for f in wine-tkg-userpatches/wine/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done