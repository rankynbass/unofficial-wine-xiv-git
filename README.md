# Wine to rule Eorzea (Unofficially)!

Build Scripts | [Arch Linux](https://github.com/rankynbass/unofficial-wine-xiv-git/actions/workflows/wine-arch.yml) | [Fedora](https://github.com/rankynbass/unofficial-wine-xiv-git/actions/workflows/wine-fedora.yml) | [Ubuntu](https://github.com/rankynbass/unofficial-wine-xiv-git/actions/workflows/wine-ubuntu.yml) | [Valve Bleeding Edge](https://github.com/rankynbass/unofficial-wine-xiv-git/actions/workflows/wine-valvexbe.yml) |
-------------|--------|--------|-------|-------|

## PLEASE DO NOT REPORT BUGS ENCOUNTERED WITH THIS AT WINEHQ OR VALVESOFTWARE, REPORT HERE INSTEAD !
Unofficial-wine-xiv is based on wine-tkg and builds wine with several patches to improve the experience of FFXIV on Linux machines. Wine-tkg is a build-system aiming at easier custom wine builds creation.

I've set up a custom script to make building wine on your own machine a bit easier. I recommend compiling in a [Distrobox container](https://distrobox.it/), unless you are building for ntsync. If you want to build ntsync, you'll need to compile on your base system or set up a full VM with an ntsync-enabled kernel and kernel headers. I use [Vagrant](https://www.vagrantup.com/) with arch linux and cachyos repos for this.

If you are going to use a distrobox, create/enter it now and make sure that `git` and any additional required dev packages are installed.

Arch: Make sure multilib is enabled in /etc/pacman.conf
```
sudo pacman -Syu --no-confirm git base-devel
```

Fedora:
```
sudo dnf install git
```

Ubuntu:
```
sudo dpkg --add-architecture i386 && sudo apt update
sudo apt install aptitude
sudo aptitude remove -y '?narrow(?installed,?version(deb.sury.org))'
sudo apt install libxkbregistry0 libxkbregistry-dev
```

After you've set up your build environment, simply clone the repo, cd into the directory, and run the following command to see your options:
```
git clone https://github.com/rankynbass/unofficial-wine-xiv-git
cd unofficial-wine-xiv-git/wine-tkg
./xiv-setup.sh -h
```

That will give you the following output:
```
Use -n to disable staging, -v to use valve wine, -p to disable protonify patchset (non-valve wine only), and -s to enable ntsync.
Use -t to use thread priorities patch with staging. Useful for pre-10.1 wine-staging.
Use -W <version> to set wine version. Must be a valid tag or commit hash (wine-10.1)
Use -S <version> to set staging version. Must be a valid tag or commit hash (v10.1)
Use -V <hash> or <tag> to set the valve bleeding edge commit hash or tag
Use -c to clean up the repo and set it to a default state.
```
Then run it again with the appropriate flags to set up the patches and configuration files. 
* If you do not set a version flag, it will use whatever is already in the customization.cfg or wine-tkg-exp-bleeding.cfg files.
* If you set the version flag to `""` it will use the latest commit instead of a specific version.
* `-t` should only be used on non-ntsync wine-staging builds prior to 10.1. I've tested it as far back as 8.21, but it may work on earlier versions as well. 

Run `yes | ./non-makepkg-build.sh` to build. I usually use `yes | ./non-makepkg-build.sh 2>&1 | tee buildfile.log` so that the output is piped to the console and to a file.

***WARNING for NTSYNC builds***
If you are using arch with cachyos repos (and not cachyos from its own installer), the above command *will* fail and get stuck in a loop due to having multiple repos. The first time you will have to
babysit the install. Just run `./non-makepkg-build.sh` and be prepared to hit enter a bunch of times until it starts compiling.

**Example 1: Do a basic staging build**

This will build staging 10.1 and output the build info to the console and the staging-10.1.log file.
```
./xiv-setup.sh -S v10.1
yes | ./non-makepkg-build.sh 2>&1 | tee staging-10.1.log
```
For 10.0 and earlier, add the -t flag to enable the thread priorities patch (included in 10.1 and later)

**Example 2: Do a valve bleeding edge build**

This needs to be done on arch or Ubuntu 24.04 or later. I haven't tested it on Fedora, and it fails on Ubuntu 22.04 and earlier.
```
./xiv-setup.sh -v -V ""
yes | ./non-makepkg-build.sh 2>&1 | tee valve.log
```
This will build vavle bleeding edge wine with the latest commit.

**Example 3: NTSync**
```
./xiv-setup.sh -s -S v10.0
yes | ./non-makepkg-build.sh 2>&1 | tee ntsync.log
```
This will build wine-staging 10.0 with ntsync patches.

### This repo uses Wine-tkg build system and patches from Wine-xiv-git
For more information on using this build system, check out the original repo: [Frogging-Family/wine-tkg-git](https://github.com/Frogging-Family/wine-tkg-git)

For the official Wine-xiv-git repo and patches: [goatcorp/wine-xiv-git](https://github.com/goatcorp/wine-xiv-git)

### Generated Wine-tkg sources (staging-based):
 - Wine-tkg : https://github.com/Tk-Glitch/wine-tkg
 - Proton-tkg : https://github.com/Tk-Glitch/wine-proton-tkg

Wine : https://github.com/wine-mirror/wine

Wine-staging : https://github.com/wine-staging/wine-staging

Wine esync : https://github.com/zfigura/wine/tree/esync

Wine fsync : https://github.com/zfigura/wine/tree/fsync

Proton : https://github.com/ValveSoftware/Proton
