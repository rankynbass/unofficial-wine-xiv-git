#!/bin/bash
xiv_staging=1
xiv_threads=0
xiv_valve=0
xiv_ntsync=0
xiv_protonify=1
xiv_wineversion=""
xiv_stagingversion=""
xiv_valveversion=""


while getopts ":nvpsthcW:S:V:" flag; do
    case "${flag}" in
        n) xiv_staging=0;;
        v) xiv_valve=1;;
        p) xiv_protonify=0;;
        s) xiv_ntsync=1;;
        t) xiv_threads=1;;
        W) xiv_wineversion=${OPTARG};;
        S) xiv_stagingversion=${OPTARG};;
        V) xiv_valveversion=${OPTARG};;
        h)
            echo "usage: xiv-setup.sh [OPTION...]"
            echo ""
            echo "Main flags:"
            echo "  -c      clean up the repo and set it to a default state."
            echo "  -n      disable staging"
            echo "  -v      use valve wine"
            echo "  -p      disable protonify patchset (non-valve wine only)"
            echo "  -s      enable ntsync"
            echo ""
            echo "Extra patches and fixes:"
            echo "  -t      use thread priorities patch with staging. Useful for pre-10.1 wine-staging."
            echo ""
            echo "Version flags:"
            echo "  -W <version>        set wine version. Must be a valid tag or commit hash (wine-10.1)"
            echo "  -S <version>        set staging version. Must be a valid tag or commit hash (v10.1)"
            echo "  -V <hash> or <tag>  set the valve bleeding edge commit hash or tag"

            exit 0;;
        c)
            git clean -xdf
            git restore .
            exit 0;;
        \?) echo "Invalid option: ${OPTARG}"
            echo "Use -n to disable staging, -v to use valve wine, -p to disable protonify patchset (non-valve wine only), and -s to enable ntsync."
            exit 1;;
    esac
done

# echo "xiv_staging=${xiv_staging}"
# echo "xiv_valve=${xiv_valve}"
# echo "xiv_protonify=${xiv_protonify}"
# echo "xiv_ntsync=${xiv_ntsync}"
# echo "xiv_threads=${xiv_threads}"
# echo "xiv_wineversion=${xiv_wineversion}"
# echo "xiv_stagingversion=${xiv_stagingversion}"

echo "Setting up environment for Wine-XIV build"

rm -f wine-tkg-userpatches/*.mypatch
rm -f wine-tkg-userpatches/*.myrevert

sed -i 's/pkgname=wine-tkg/pkgname=unofficial-wine-xiv/' non-makepkg-build.sh
sed -i 's/_NOLIB32="false"/_NOLIB32="wow64"/' wine-tkg-profiles/advanced-customization.cfg
sed -i 's/LOCAL_PRESET="valve-exp-bleeding"/LOCAL_PRESET=""/' customization.cfg
sed -i 's/_protonify="false"/_protonify="true"/' customization.cfg
if [ -n "$xiv_wineversion" ]; then
    sed -i "s/_plain_version=\"\(.\)\"/_plain_version=\"${xiv_wineversion}\"/" customization.cfg
    echo "Setting plain wine version to ${xiv_wineversion}"
fi
if [ -n "$xiv_stagingversion" ]; then
    sed -i "s/_staging_version=\"\(.*\)\"/_staging_version=\"${xiv_stagingversion}\"/" customization.cfg
    echo "Setting wine-staging version to ${xiv_stagingversion}"
fi
if [ -n "$xiv_valveversion" ]; then
    sed -i "s/_bleeding_tag=\"\(.*\)\"/_bleeding_tag=\"${xiv_valveversion}\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
    echo "Setting valve experimental to commit/tag ${xiv_valveversion}"
fi



if [ "$xiv_valve" == "1" ]; then
    echo "Using Valve Wine."
    sed -i 's/LOCAL_PRESET=""/LOCAL_PRESET="valve-exp-bleeding"/' customization.cfg
    for f in wine-tkg-userpatches/valvexbe/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
    for f in wine-tkg-userpatches/valvexbe/*.revert; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.revert}).myrevert"; done
    if [ "$xiv_staging" == "1" ]; then
        echo "Using Staging patches"
        sed -i 's/_use_staging="false"/_use_staging="true"/' customization.cfg
    else
        echo "Disabling Staging patches"
        sed -i 's/_use_staging="true"/_use_staging="false"/' customization.cfg
        rm -f wine-tkg-userpatches/ds*
    fi
    if [ "$xiv_ntsync" == "1" ]; then
        sed -i "s/_bleeding_tag=\"\(.*\)\"/_bleeding_tag=\"b561e8d5d8a86062ca783296cb28ffe6e2be5938\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
        cp wine-tkg-userpatches/valvexbe/ntsync-latest.disabled wine-tkg-userpatches/ntsync-latest.mypatch
        rm -f wine-tkg-userpatches/*.myrevert
        rm -f wine-tkg-userpatches/0003-ntdll-Downgrade-using-kernel-write-watches-from-MESS.mypatch
        rm -f wine-tkg-userpatches/proton-fshack-AMD-FSR-complete.mypatch
    fi
else
    if [ "$xiv_staging" == "1" ]; then
        echo "Using Wine Staging"
        sed -i 's/_use_staging="false"/_use_staging="true"/' customization.cfg
        for f in wine-tkg-userpatches/staging/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
        if [ "$xiv_threads" == "1" ]; then
            cp wine-tkg-userpatches/staging/thread-prios-protonify.disabled wine-tkg-userpatches/thread-prios-protonify.mypatch
        fi
    else
        echo "Using Wine without Staging patches"
        sed -i 's/_use_staging="true"/_use_staging="false"/' customization.cfg
        for f in wine-tkg-userpatches/mainline/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
    fi
    if [ "$xiv_protonify" == "0" ]; then
        echo "Disabling protonify patchset"
        sed -i 's/_protonify="true"/_protonify="false"/' customization.cfg
        rm -f wine-tkg-userpatches/thread-prios-protonify.mypatch
    fi
    if [ "$xiv_ntsync" == "1" ]; then
        echo "Using NTSync patches. Requires compatible kernel headers to compile."
        sed -i 's/_use_ntsync="false"/_use_ntsync="true"/' customization.cfg
        sed -i 's/_use_esync="true"/_use_esync="false"/' customization.cfg
        sed -i 's/_use_fsync="true"/_use_fsync="false"/' customization.cfg
        rm -f wine-tkg-userpatches/thread-prios-protonify.mypatch
    else
        echo "Using ESync and FSync patches"
        sed -i 's/_use_esync="false"/_use_esync="true"/' customization.cfg
        sed -i 's/_use_fsync="false"/_use_fsync="true"/' customization.cfg
        sed -i 's/_use_ntsync="true"/_use_ntsync="false"/' customization.cfg
    fi
fi