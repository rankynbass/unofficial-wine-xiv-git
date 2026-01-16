#!/usr/bin/env bash
xiv_lsteamclient=1
xiv_valve_commit=""
xiv_ge_patches=1
xiv_ntsync=1

while getopts ":hlgncV:" flag; do
    case "${flag}" in
        V) xiv_valve_commit=${OPTARG};;
        l) xiv_lsteamclient=0;;
        g) xiv_ge_patches=0;;
        h)
            echo "usage: xiv-valve.sh [OPTION...]"
            echo "For valve-based wine 10 experimental."
            echo ""
            echo "Main flags:"
            echo "  -c              clean up the repo and set it to a default state."
            echo "  -V <commit/tag> set a commit to build. Leave empty for latest commit."
            echo "  -l              disable lsteamclient patches"
            echo "  -g              Disable GE patches (includes NTSync)"
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

sed -i "s/LOCAL_PRESET=\"\(.*\)\"/LOCAL_PRESET=\"valve-exp-bleeding\"/" customization.cfg
sed -i "s/_NOLIB32=\"\(.*\)\"/_NOLIB32=\"wow64\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg

if [ -n "$xiv_valve_commit" ]; then
    sed -i "s/_bleeding_tag=\"\(.*\)\"/_bleeding_tag=\"${xiv_valve_commit}\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
    echo "Setting valve experimental to commit/tag ${xiv_valve_commit}"
else
    sed -i "s/_bleeding_tag=\"\(.*\)\"/_bleeding_tag=\"\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
    echo "Setting valve experimental to latest commit"
fi

if [ "$xiv_ge_patches" == "0" ]; then
    sed -i "s/_GE_WAYLAND=\"\(.*\)\"/_GE_WAYLAND=\"false\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
    echo "Disabling GE Wayland patches"
else
    sed -i "s/_GE_WAYLAND=\"\(.*\)\"/_GE_WAYLAND=\"true\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
    echo "Enabling GE Wayland and NTSync patches"
fi

for f in wine-tkg-userpatches/valvexbe10-latest/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
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
