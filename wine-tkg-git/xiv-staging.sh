#!/usr/bin/env bash
xiv_protonify=1
xiv_lsteamclient=1
xiv_stagingversion=""
xiv_esync=0
xiv_fsync=0
xiv_disableicu=0

while getopts ":hcplefiS:" flag; do
    case "${flag}" in
        p) xiv_protonify=0;;
        S) xiv_stagingversion=${OPTARG};;
        l) xiv_lsteamclient=0;;
        e) xiv_esync=1;;
        f) xiv_fsync=1;;
        i) xiv_disableicu=1;;
        h)
            echo "usage: xiv-staging.sh [OPTION...]"
            echo "For wine-staging 10.16 and later. Use xiv-setup.sh for earlier versions or valve wine"
            echo ""
            echo "Main flags:"
            echo "  -c              clean up the repo and set it to a default state."
            echo "  -p              disable protonify patchset"
            echo "  -S <version>    set staging version. Must be a valid tag or commit hash (v10.16)"
            echo "  -l              disable lsteamclient patches"
            echo "  -f              build with esync & fsync instead of ntsync"
            echo "  -e              build with esync instead of ntsync"
            echo "  -i              disable icu to fix dalamud (10.20 thru 11.0-rc1 only)"

            exit 0;;
        c)
            git clean -df
            git restore .
            exit 0;;
        \?) echo "Invalid option: ${OPTARG}"
            exit 1;;
    esac
done

echo "Setting up environment for Wine-XIV build"

rm -f wine-tkg-userpatches/*.mypatch
rm -f wine-tkg-userpatches/*.myrevert

sed -i "s/LOCAL_PRESET=\"\(.*\)\"/LOCAL_PRESET=\"\"/" customization.cfg
sed -i 's/_NOLIB32="false"/_NOLIB32="wow64"/' wine-tkg-profiles/advanced-customization.cfg
if [ "$xiv_protonify" == "0" ]; then
    sed -i "s/_protonify=\"\(.*\)\"/_protonify=\"false\"/" customization.cfg
    echo "Diasbling Protonify patchset"
else
    sed -i "s/_protonify=\"\(.*\)\"/_protonify=\"true\"/" customization.cfg
    echo "Enabling Protonify patchset"
fi
if [ -n "$xiv_stagingversion" ]; then
    sed -i "s/_staging_version=\"\(.*\)\"/_staging_version=\"${xiv_stagingversion}\"/" customization.cfg
    echo "Setting wine-staging version to ${xiv_stagingversion}"
else
    sed -i "s/_staging_version=\"\(.*\)\"/_staging_version=\"\"/" customization.cfg
    echo "No staging version set. Using latest commit"
fi
sed -i "s/_use_staging=\"\(.*\)\"/_use_staging=\"true\"/" customization.cfg
if [ "$xiv_fsync" == "1" ]; then
    echo "Using Fsync patches. This includes Esync, and disabled NTsync."
    sed -i "s/_use_fsync=\"\(.*\)\"/_use_fsync=\"true\"/" customization.cfg
    sed -i "s/_use_esync=\"\(.*\)\"/_use_esync=\"true\"/" customization.cfg
    sed -i "s/_use_ntsync=\"\(.*\)\"/_use_ntsync=\"false\"/" customization.cfg
elif [ "$xiv_esync" == "1" ]; then
    echo "Using Esync patches. This disables NTsync."
    sed -i "s/_use_fsync=\"\(.*\)\"/_use_fsync=\"false\"/" customization.cfg
    sed -i "s/_use_esync=\"\(.*\)\"/_use_esync=\"true\"/" customization.cfg
    sed -i "s/_use_ntsync=\"\(.*\)\"/_use_ntsync=\"false\"/" customization.cfg
else
    echo "Using NTsync. This disables Esync and Fsync."
    sed -i "s/_use_fsync=\"\(.*\)\"/_use_fsync=\"false\"/" customization.cfg
    sed -i "s/_use_esync=\"\(.*\)\"/_use_esync=\"false\"/" customization.cfg
    sed -i "s/_use_ntsync=\"\(.*\)\"/_use_ntsync=\"true\"/" customization.cfg
fi

for f in wine-tkg-userpatches/staging/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
if [ "$xiv_disableicu" == "1" ]; then
    cp "wine-tkg-userpatches/staging/disable-icu-10.20.disabled" "wine-tkg-userpatches/disable-icu.mypatch"
fi
if [ "$xiv_lsteamclient" == "0" ]; then
    echo "Disabling lsteamclient patches and binaries"
    rm -f wine-tkg-userpatches/lsteamclient_*.mypatch
    sed -i 's/_lsteamclient_patches="\(.*\)"/_lsteamclient_patches="false"/' customization.cfg
    sed -i 's/_lsteamclient_patches="\(.*\)"/_lsteamclient_patches="false"/' wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
    sed -i 's/pkgname=wine-tkg$/pkgname=unofficial-wine-xiv-nolsc/' non-makepkg-build.sh
    sed -i 's/pkgname=unofficial-wine-xiv$/pkgname=unofficial-wine-xiv-nolsc/' non-makepkg-build.sh
else
    echo "Enabling lsteamclient patches and binaries"
    sed -i 's/_lsteamclient_patches="\(.*\)"/_lsteamclient_patches="true"/' customization.cfg
    sed -i 's/_lsteamclient_patches="\(.*\)"/_lsteamclient_patches="true"/' wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
    sed -i 's/pkgname=wine-tkg$/pkgname=unofficial-wine-xiv/' non-makepkg-build.sh
    sed -i 's/pkgname=unofficial-wine-xiv-nolsc$/pkgname=unofficial-wine-xiv/' non-makepkg-build.sh
fi
