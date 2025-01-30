#!/bin/bash
echo "Setting up environment for Wine-XIV build"
xiv_staging=1
xiv_valve=0
xiv_ntsync=0

while getopts "nvsc" flag; do
    case "${flag}" in
        n) xiv_staging=0;;
        v) xiv_valve=1;;
        s) xiv_ntsync=1;;
        c) 
            rm wine-tkg-userpatches/*.mypatch
            rm wine-tkg-userpatches/*.myrevert
            exit 0;;
    esac
done

sed -i 's/pkgname=wine-tkg/pkgname=unofficial-wine-xiv/' non-makepkg-build.sh

if [ "$xiv_valve" == "1" ]; then
    if [ "$xiv_ntsync" == "1" ]; then
        "Can't use ntsync with valve wine."
        exit 1;
    fi
    sed -i 's/LOCAL_PRESET=""/LOCAL_PRESET="valve-exp-bleeding"/' customization.cfg
    sed -i 's/_NOLIB32="false"/_NOLIB32="wow64"/' wine-tkg-profiles/advanced-customization.cfg
    for f in wine-tkg-userpatches/valvexbe/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
    for f in wine-tkg-userpatches/valvexbe/*.revert; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.revert}).myrevert"; done
    if [ "$xiv_staging" == "1"]; then
        sed -i 's/_use_staging="false"/_use_staging="true"/' customization.cfg
    else
        sed -i 's/_use_staging="true"/_use_staging="false"/' customization.cfg
    fi
else
    if [ "$xiv_staging" == "1" ]; then
        sed -i 's/_use_staging="false"/_use_staging="true"/' customization.cfg
        for f in wine-tkg-userpatches/wine/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
    else
        sed -i 's/pkgname=wine-tkg/pkgname=unofficial-wine-xiv/' non-makepkg-build.sh
        sed -i 's/_use_staging="true"/_use_staging="false"/' customization.cfg
        for f in wine-tkg-userpatches/vanilla/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
    fi
    if [ "$xiv_ntsync" == "1" ]; then
        sed -i 's/_use_ntsync="false"/_use_ntsync="true"/' customization.cfg
        sed -i 's/_use_esync="true"/_use_esync="false"/' customization.cfg
        sed -i 's/_use_fsync="true"/_use_fsync="false"/' customization.cfg
        rm wine-tkg-userpatches/thread-prios-protonify.mypatch
    else
        sed -i 's/_use_esync="false"/_use_esync="true"/' customization.cfg
        sed -i 's/_use_fsync="false"/_use_fsync="true"/' customization.cfg
        sed -i 's/_use_ntsync="true"/_use_ntsync="false"/' customization.cfg
    fi


