#!/bin/bash
xiv_staging=1
xiv_threads=0
xiv_trampolines=3
xiv_valve=""
xiv_ntsync=0
xiv_protonify=1
xiv_lsteamclient=1
xiv_debug=0
xiv_wineversion=""
xiv_stagingversion=""
xiv_valveversion=""
xiv_topology=0


while getopts ":n9psthCcv:d:T:W:S:V:" flag; do
    case "${flag}" in
        n) xiv_staging=0;;
        v) xiv_valve=${OPTARG};;
        p) xiv_protonify=0;;
        s) xiv_ntsync=1;;
        t) xiv_threads=1;;
        d) xiv_debug=${OPTARG};;
        C) xiv_topology=1;;
        T) xiv_trampolines=${OPTARG};;
        W) xiv_wineversion=${OPTARG};;
        S) xiv_stagingversion=${OPTARG};;
        V) xiv_valveversion=${OPTARG};;
        h)
            echo "usage: xiv-setup.sh [OPTION...]"
            echo ""
            echo "Main flags:"
            echo "  -c      clean up the repo and set it to a default state."
            echo "  -n      disable staging"
            echo "  -v <#>  0: Use Valve wine with latest patches"
            echo "          10: Valve wine v10 patches, pre-GE-Proton10-9 (may not work for everything)"
            echo "          9: Valve wine v9 patches"
            echo "  -p      disable protonify patchset (non-valve wine only)"
            echo "  -s      enable ntsync"
            echo ""
            echo "Extra patches and fixes:"
            echo "  -d <#>  Debug patch for Dalamud. For wine 9.0 to 10.7. Not needed for 10.8+"
            echo "          0: Disable debug patch (default for mainline, staging)"
            echo "          1: Enable debug patch (default for valve wine)"
            echo "  -C      Proton-cpu-topology override patches for Protonify Staging non-ntsync wine 10.0"
            echo "          Only use for 10.0 builds, not for 10.1 and later."
            echo "  -t      use thread priorities patch with staging. Useful for pre-10.1 wine-staging."
            echo "  -T <#>  0: Disable lsteamclient patches and binaries"
            echo "          1: Use lsteamclient_tranpolines patch for wine <= 10.4"
            echo "          2: Use lsteamclient_trampolines patch for wine = 10.5"
            echo "          3: (default) use lsteamclient_trampolines patch for wine >= 10.6"
            echo ""
            echo "Version flags:"
            echo "  -W <version>        set wine version. Must be a valid tag or commit hash (wine-10.1)"
            echo "  -S <version>        set staging version. Must be a valid tag or commit hash (v10.1)"
            echo "  -V <hash> or <tag>  set the valve bleeding edge commit hash or tag"
            echo ""
            echo "Some combinations of flags will be ignored. For example, setting -t or -C when using -s"
            echo " (enable ntsync) does nothing."

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

sed -i 's/_NOLIB32="false"/_NOLIB32="wow64"/' wine-tkg-profiles/advanced-customization.cfg
sed -i 's/LOCAL_PRESET="valve-exp-bleeding"/LOCAL_PRESET=""/' customization.cfg
sed -i 's/_protonify="false"/_protonify="true"/' customization.cfg
if [ -n "$xiv_wineversion" ]; then
    sed -i "s/_plain_version=\"\(.*\)\"/_plain_version=\"${xiv_wineversion}\"/" customization.cfg
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

if [ "$xiv_valve" != "" ]; then
    case "$xiv_valve" in
        9)  echo "Using Valve Wine with 9.0 patchset"
            sed -i 's/LOCAL_PRESET=""/LOCAL_PRESET="valve-exp-bleeding"/' customization.cfg
            sed -i "s/_plain_version=\"\(.*\)\"/_plain_version=\"experimental_9.0\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            sed -i "s/_proton_branch=\"\(.*\)\"/_proton_branch=\"experimental_9.0\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            sed -i "s/_staging_version=\"\(.*\)\"/_staging_version=\"cab93f47b8d095eb968bb3c7debf9117a91307ce\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            sed -i "s/_GE_WAYLAND=\"\(.*\)\"/_GE_WAYLAND=\"false\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            echo '_wayland_driver="true"' >> wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg

            for f in wine-tkg-userpatches/valvexbe9/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
            for f in wine-tkg-userpatches/valvexbe9/*.revert; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.revert}).myrevert"; done
            if [ "$xiv_staging" == "1" ]; then
                echo "Using Staging patches"
                sed -i 's/_use_staging="false"/_use_staging="true"/' customization.cfg
            else
                echo "Disabling Staging patches"
                sed -i 's/_use_staging="true"/_use_staging="false"/' customization.cfg
                rm -f wine-tkg-userpatches/ds*
            fi
            if [ "$xiv_ntsync" == "1" ]; then
                echo "Using ntsync valve patches. Known to work with commit b561e8d5d8a86062ca783296cb28ffe6e2be593"
                cp wine-tkg-userpatches/valvexbe9/xiv-ntsync-patches.disabled wine-tkg-userpatches/xiv-ntsync-patches.mypatch
                sed -i 's/_use_esync="true"/_use_esync="false"/' customization.cfg
                sed -i 's/_use_fsync="true"/_use_fsync="false"/' customization.cfg
            fi
            if [ "$xiv_debug" == "0" ]; then
                echo "Disabling debug patch"
                rm -f wine-tkg-userpatches/portable-pdb.mypatch
            fi
            ;;
        10) echo "Using Valve Wine with old 10.0 patchset"
            sed -i 's/LOCAL_PRESET=""/LOCAL_PRESET="valve-exp-bleeding"/' customization.cfg
            sed -i "s/_plain_version=\"\(.*\)\"/_plain_version=\"experimental_10.0\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            sed -i "s/_proton_branch=\"\(.*\)\"/_proton_branch=\"experimental_10.0\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            sed -i "s/_staging_version=\"\(.*\)\"/_staging_version=\"05bc4b822fdb1898777b08a8597639ad851f5601\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            sed -i "s/_GE_WAYLAND=\"\(.*\)\"/_GE_WAYLAND=\"true\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            for f in wine-tkg-userpatches/valvexbe10/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
            if [ "$xiv_staging" == "1" ]; then
                echo "Using Staging patches"
                sed -i 's/_use_staging="false"/_use_staging="true"/' customization.cfg
            else
                echo "Disabling Staging patches"
                sed -i 's/_use_staging="true"/_use_staging="false"/' customization.cfg
                rm -f wine-tkg-userpatches/ds*
            fi
            if [ "$xiv_ntsync" == "1" ]; then
                echo "Using ntsync valve patches. Known to work with commit b561e8d5d8a86062ca783296cb28ffe6e2be593"
                cp wine-tkg-userpatches/valvexbe10/xiv-ntsync-patches.disabled wine-tkg-userpatches/xiv-ntsync-patches.mypatch
                sed -i 's/_use_esync="true"/_use_esync="false"/' customization.cfg
                sed -i 's/_use_fsync="true"/_use_fsync="false"/' customization.cfg
            fi
            if [ "$xiv_debug" == "0" ]; then
                echo "Disabling debug patch"
                rm -f wine-tkg-userpatches/portable-pdb.mypatch
            fi
            ;;
        *) echo "Using Valve Wine with new 10.0 patchset"
            sed -i 's/LOCAL_PRESET=""/LOCAL_PRESET="valve-exp-bleeding"/' customization.cfg
            sed -i "s/_plain_version=\"\(.*\)\"/_plain_version=\"experimental_10.0\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            sed -i "s/_proton_branch=\"\(.*\)\"/_proton_branch=\"experimental_10.0\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            sed -i "s/_staging_version=\"\(.*\)\"/_staging_version=\"05bc4b822fdb1898777b08a8597639ad851f5601\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            sed -i "s/_GE_WAYLAND=\"\(.*\)\"/_GE_WAYLAND=\"true\"/" wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
            for f in wine-tkg-userpatches/valvexbe10-ntsync/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
            if [ "$xiv_staging" == "1" ]; then
                echo "Using Staging patches"
                sed -i 's/_use_staging="false"/_use_staging="true"/' customization.cfg
            else
                echo "Disabling Staging patches"
                sed -i 's/_use_staging="true"/_use_staging="false"/' customization.cfg
                rm -f wine-tkg-userpatches/ds*
            fi
            ;;
    esac
else
    if [ "$xiv_staging" == "1" ]; then
        echo "Using Wine Staging"
        sed -i 's/_use_staging="false"/_use_staging="true"/' customization.cfg
        for f in wine-tkg-userpatches/staging/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
        if [ "$xiv_ntsync" == "1" ] || [ "$xiv_protonify" != "1" ]; then
            xiv_topology=0
            xiv_threads=0
        fi
        if [ "$xiv_threads" == "1" ]; then
            echo "Enabling thread-prios-protonify patch"
            cp wine-tkg-userpatches/staging/thread-prios-protonify.disabled wine-tkg-userpatches/thread-prios-protonify.mypatch
        fi
        if [ "$xiv_debug" == "1" ]; then
            echo "Enabling debug patch"
            cp wine-tkg-userpatches/staging/portable-pdb.disabled wine-tkg-userpatches/portable-pdb.mypatch
        fi
        if [ "$xiv_topology" == "1" ]; then
            echo "Using proton-cpu-topology-overrides-fix for 10.0"
            cp wine-tkg-userpatches/staging/proton-cpu-topology-overrides-fix-10.0.disabled wine-tkg-userpatches/proton-cpu-topology-overrides-fix-10.0.mypatch
        fi
        case "$xiv_trampolines" in
            0)  ;;
            1)  echo "Using lsteamclient_trampolines 10.4 patch."
                rm -f wine-tkg-userpatches/lsteamclient_trampolines.mypatch
                cp wine-tkg-userpatches/staging/lsteamclient_trampolines_10.4.disabled wine-tkg-userpatches/lsteamclient_trampolines_10.4.mypatch
                ;;
            2)  echo "Using lsteamclient_trampolines 10.5 patch."
                rm -f wine-tkg-userpatches/lsteamclient_trampolines.mypatch
                cp wine-tkg-userpatches/staging/lsteamclient_trampolines_10.5.disabled wine-tkg-userpatches/lsteamclient_trampolines_10.5.mypatch
                ;;
            *)  echo "Using default lsteamclient_trampolines patch for 10.6+"
                ;;
        esac
    else
        echo "Using Wine without Staging patches"
        sed -i 's/_use_staging="true"/_use_staging="false"/' customization.cfg
        for f in wine-tkg-userpatches/mainline/*.patch; do cp "$f" "wine-tkg-userpatches/$(basename ${f%.patch}).mypatch"; done
        if [ "$xiv_debug" == 1 ]; then
            echo "Enabling debug patch"
            cp wine-tkg-userpatches/staging/portable-pdb.disabled wine-tkg-userpatches/portable-pdb.mypatch
        fi
        case "$xiv_trampolines" in
            0)  ;;
            1)  echo "Using lsteamclient_trampolines 10.4 patch."
                rm -f wine-tkg-userpatches/lsteamclient_trampolines.mypatch
                cp wine-tkg-userpatches/mainline/lsteamclient_trampolines_10.4.disabled wine-tkg-userpatches/lsteamclient_trampolines_10.4.mypatch
                ;;
            2)  echo "Using lsteamclient_trampolines 10.5 patch."
                rm -f wine-tkg-userpatches/lsteamclient_trampolines.mypatch
                cp wine-tkg-userpatches/mainline/lsteamclient_trampolines_10.5.disabled wine-tkg-userpatches/lsteamclient_trampolines_10.5.mypatch
                ;;
            *)  echo "Using default lsteamclient_trampolines patch for 10.6+"
                ;;
        esac
    fi
    if [ "$xiv_protonify" == "0" ]; then
        echo "Disabling protonify patchset"
        sed -i 's/_protonify="true"/_protonify="false"/' customization.cfg
        rm -f wine-tkg-userpatches/thread-prios-protonify.mypatch
        rm -f wine-tkg-userpatches/proton-cpu-topology-overrides-fix-*.mypatch
    fi
    if [ "$xiv_ntsync" == "1" ]; then
        echo "Using NTSync patches. Requires compatible kernel headers to compile."
        sed -i 's/_use_ntsync="false"/_use_ntsync="true"/' customization.cfg
        sed -i 's/_use_esync="true"/_use_esync="false"/' customization.cfg
        sed -i 's/_use_fsync="true"/_use_fsync="false"/' customization.cfg
        rm -f wine-tkg-userpatches/thread-prios-protonify.mypatch
        rm -f wine-tkg-userpatches/proton-cpu-topology-overrides-fix-*.mypatch
    else
        echo "Using ESync and FSync patches"
        sed -i 's/_use_esync="false"/_use_esync="true"/' customization.cfg
        sed -i 's/_use_fsync="false"/_use_fsync="true"/' customization.cfg
        sed -i 's/_use_ntsync="true"/_use_ntsync="false"/' customization.cfg
    fi
fi
if [ "$xiv_trampolines" == "0" ]; then
    echo "Disabling lsteamclient patches and binaries"
    rm -f wine-tkg-userpatches/lsteamclient_*.mypatch
    sed -i 's/_lsteamclient_patches="\(.*\)"/_lsteamclient_patches="false"/' customization.cfg
    sed -i 's/_lsteamclient_patches="\(.*\)"/_lsteamclient_patches="false"/' wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
    sed -i 's/pkgname=wine-tkg$/pkgname=unofficial-wine-xiv-nolsc/' non-makepkg-build.sh
    sed -i 's/pkgname=unofficial-wine-xiv$/pkgname=unofficial-wine-xiv-nolsc/' non-makepkg-build.sh
else
    sed -i 's/_lsteamclient_patches="\(.*\)"/_lsteamclient_patches="true"/' customization.cfg
    sed -i 's/_lsteamclient_patches="\(.*\)"/_lsteamclient_patches="true"/' wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
    sed -i 's/pkgname=wine-tkg$/pkgname=unofficial-wine-xiv/' non-makepkg-build.sh
    sed -i 's/pkgname=unofficial-wine-xiv-nolsc$/pkgname=unofficial-wine-xiv/' non-makepkg-build.sh
fi