#!/bin/bash

# Whether to do a nightly
PUSH_NIGHTLY="0"

# Store individual repo updates so we can add commit info
# TODO: Actually display commit info, for now since this
# is hacky we'll just do "PSP update" etc.
ASSET_UPDATE="0"
FTEQW_UPDATE="0"
QUAKC_UPDATE="0"
DQUAK_UPDATE="0"
SPASM_UPDATE="0"

# The time of execution in epoch
CURRENT_TIME=$(date "+%s")

# The epoch time of yesterday, exactly
YESTERDAY_TIME=$(expr $CURRENT_TIME - 86400)

# The Build Date string to add to the game files
BUILD_STRING="2.0.0-indev+$(date +'%Y%m%d%H%M%S')"

# Epoch times for every repo we care about
ASSET_REPO_TIME=$(date "+%s" -d $(curl -s -H "Authorization: token $1" https://api.github.com/repos/nzp-team/assets/branches/main | jq '.commit.commit.author.date'| tr -d '"'))
FTEQW_REPO_TIME=$(date "+%s" -d $(curl -s -H "Authorization: token $1" https://api.github.com/repos/nzp-team/fteqw/branches/master | jq '.commit.commit.author.date'| tr -d '"'))
QUAKC_REPO_TIME=$(date "+%s" -d $(curl -s -H "Authorization: token $1" https://api.github.com/repos/nzp-team/quakec/branches/main | jq '.commit.commit.author.date'| tr -d '"'))
DQUAK_REPO_TIME=$(date "+%s" -d $(curl -s -H "Authorization: token $1" https://api.github.com/repos/nzp-team/vril-engine/branches/main | jq '.commit.commit.author.date'| tr -d '"'))
SPASM_REPO_TIME=$(date "+%s" -d $(curl -s -H "Authorization: token $1" https://api.github.com/repos/nzp-team/quakespasm/branches/main | jq '.commit.commit.author.date'| tr -d '"'))

# Now check through them all and see if any have been updated recently
if [ "$ASSET_REPO_TIME" -ge "$YESTERDAY_TIME" ]; then
    PUSH_NIGHTLY="1"
    ASSET_UPDATE="1"
fi

if [ "$FTEQW_REPO_TIME" -ge "$YESTERDAY_TIME" ]; then
    PUSH_NIGHTLY="1"
    FTEQW_UPDATE="1"
fi

if [ "$QUAKC_REPO_TIME" -ge "$YESTERDAY_TIME" ]; then
    PUSH_NIGHTLY="1"
    QUAKC_UPDATE="1"
fi

if [ "$DQUAK_REPO_TIME" -ge "$YESTERDAY_TIME" ]; then
    PUSH_NIGHTLY="1"
    DQUAK_UPDATE="1"
fi

if [ "$SPASM_REPO_TIME" -ge "$YESTERDAY_TIME" ]; then
    PUSH_NIGHTLY="1"
    SPASM_UPDATE="1"
fi

# Do we proceed?
if [ "$PUSH_NIGHTLY" -ne "1" ]; then
    echo "Nothing to do."
    exit 1
fi

#
# Generate a changelog for the release body
#
printf "This is a nightly generated automagically." > changes.txt
printf " Nightlies are generated at 3AM EST if changes are made to any component" >> changes.txt
printf " of the project in the past 24 hours. Be sure to check the build date above" >> changes.txt
printf " and compare it to the version displayed on the main menu to verify whether" >> changes.txt
printf " or not you are out of date.\nChanges in the following areas have been made" >> changes.txt
printf " since the last nightly:\n" >> changes.txt

if [ "$ASSET_UPDATE" -eq "1" ]; then
    printf "* Game Assets\n" >> changes.txt
fi

if [ "$FTEQW_UPDATE" -eq "1" ]; then
    printf "* FTEQW (PC Engine)\n" >> changes.txt
fi

if [ "$QUAKC_UPDATE" -eq "1" ]; then
    printf "* QuakeC (Game Code)\n" >> changes.txt
fi

if [ "$DQUAK_UPDATE" -eq "1" ]; then
    printf "* Vril (PSP/3DS/NSPIRE Engine)\n" >> changes.txt
fi

if [ "$SPASM_UPDATE" -eq "1" ]; then
    printf "* Quakespasm (PS VITA/Nintendo Switch Engine)\n\n" >> changes.txt
fi

if [ "$GLQUA_UPDATE" -eq "1" ]; then
    printf "* glQuake (Nintendo 3DS Engine)\n\n" >> changes.txt
fi

printf "\n " >> changes.txt
printf "Installation Instructions:\n" >> changes.txt
printf "* PC: Extract .ZIP archive into a folder of your choice. Linux users may need" >> changes.txt
printf " to mark as executable with \`chmod\`. Linux users may also choose to use the Flatpak.\n" >> changes.txt
printf "* PSP: Extract the `nzportable` folder inside the .ZIP archive into \`PSP/GAME/\`.\n" >> changes.txt
printf "* Nintendo Switch: Extract the `nzportable` folder inside the .ZIP archive" >> changes.txt
printf " into \`/switch/\` and launch with Homebrew Launcher. Requires extra memory," >> changes.txt
printf " so make sure to open HBLauncher by holding 'R' over an installed title!\n" >> changes.txt
printf "* PS VITA: Extract the .ZIP archive into ux0: and install \`nzp.vpk\`.\n" >> changes.txt
printf "* Nintendo 3DS: Extract the .ZIP archive into \`/3ds/\`.\n" >> changes.txt
printf "* TI NSPIRE: Extract the .ZIP archive and sync contents to \`My Documents\`. \n" >> changes.txt
printf "\n " >> changes.txt
printf "\nYou can also play the WebGL version at https://nzp.gay/" >> changes.txt

#
# Start the packaging process
#

# Assets
wget -nc https://github.com/nzp-team/assets/releases/download/newest/nx-nzp-assets.zip
wget -nc https://github.com/nzp-team/assets/releases/download/newest/pc-nzp-assets.zip
wget -nc https://github.com/nzp-team/assets/releases/download/newest/psp-nzp-assets.zip
wget -nc https://github.com/nzp-team/assets/releases/download/newest/vita-nzp-assets.zip
wget -nc https://github.com/nzp-team/assets/releases/download/newest/3ds-nzp-assets.zip
wget -nc https://github.com/nzp-team/assets/releases/download/newest/nspire-nzp-assets.zip

# Vril
wget -nc https://github.com/nzp-team/vril-engine/releases/download/bleeding-edge/psp-nzp-eboot.zip
wget -nc https://github.com/nzp-team/vril-engine/releases/download/bleeding-edge/ctr-nzp-3dsx.zip
wget -nc https://github.com/nzp-team/vril-engine/releases/download/bleeding-edge/nspire-nzp-tns.zip

# FTEQW
wget -nc https://github.com/nzp-team/fteqw/releases/download/bleeding-edge/pc-nzp-linux32.zip
wget -nc https://github.com/nzp-team/fteqw/releases/download/bleeding-edge/pc-nzp-linux64.zip
wget -nc https://github.com/nzp-team/fteqw/releases/download/bleeding-edge/pc-nzp-linux_arm64.zip
wget -nc https://github.com/nzp-team/fteqw/releases/download/bleeding-edge/pc-nzp-linux_armhf.zip
wget -nc https://github.com/nzp-team/fteqw/releases/download/bleeding-edge/pc-nzp-win32.zip
wget -nc https://github.com/nzp-team/fteqw/releases/download/bleeding-edge/pc-nzp-win64.zip

# QuakeC
wget -nc https://github.com/nzp-team/quakec/releases/download/bleeding-edge/fte-nzp-qc.zip
wget -nc https://github.com/nzp-team/quakec/releases/download/bleeding-edge/standard-nzp-qc.zip

# Quakespasm
wget -nc https://github.com/nzp-team/quakespasm/releases/download/bleeding-edge/nx-nzp-nro.zip
wget -nc https://github.com/nzp-team/quakespasm/releases/download/bleeding-edge/vita-nzp-vpk.zip

# Directory setup
mkdir -p {pc-assembly,psp-assembly,vita-assembly,nx-assembly,3ds-assembly,nspire-assembly,out}
echo $BUILD_STRING > release_version.txt

#
# Assemble PC builds
#

cd pc-assembly
mkdir assets
unzip -q ../pc-nzp-assets.zip -d assets/
unzip -q ../fte-nzp-qc.zip -d assets/nzp/
unzip -q ../pc-nzp-linux32.zip -d $PWD
unzip -q ../pc-nzp-linux64.zip -d $PWD
unzip -q ../pc-nzp-linux_arm64.zip -d $PWD
unzip -q ../pc-nzp-linux_armhf.zip -d $PWD
unzip -q ../pc-nzp-win32.zip -d $PWD
unzip -q ../pc-nzp-win64.zip -d $PWD
echo $BUILD_STRING > assets/nzp/version.txt
cp assets/nzp/version.txt ../out/build-version.txt
mv nzportable32-sdl assets/
cd assets
zip -q -r ../nzportable-linux32.zip ./*
rm nzportable32-sdl
cd ../
mv nzportable-linux32.zip ../out/
mv nzportable64-sdl assets/
cd assets
zip -q -r ../nzportable-linux64.zip ./*
rm nzportable64-sdl
cd ../
mv nzportable-linux64.zip ../out/
mv nzportablearm64-sdl assets/
cd assets
zip -q -r ../nzportable-linuxarm64.zip ./*
rm nzportablearm64-sdl
cd ../
mv nzportable-linuxarm64.zip ../out/
mv nzportablearmhf-sdl assets/
cd assets
zip -q -r ../nzportable-linuxarmhf.zip ./*
rm nzportablearmhf-sdl
cd ../
mv nzportable-linuxarmhf.zip ../out/
mv nzportable-sdl.exe assets/
cd assets
zip -q -r ../nzportable-win32.zip ./*
rm nzportable-sdl.exe
cd ../
mv nzportable-win32.zip ../out/
mv nzportable-sdl64.exe assets/
cd assets
zip -q -r ../nzportable-win64.zip ./*
rm nzportable-sdl64.exe
cd ../
mv nzportable-win64.zip ../out/
cd ../

#
# Assemble PSP Builds
#

cd psp-assembly
mkdir assets
unzip -q ../psp-nzp-assets.zip -d assets/
unzip -q ../standard-nzp-qc.zip -d assets/nzportable/nzp/
unzip -q ../psp-nzp-eboot.zip -d $PWD
echo $BUILD_STRING > assets/nzportable/nzp/version.txt
mv EBOOT.PBP assets/nzportable/
cd assets/
zip -q -r ../nzportable-psp.zip ./*
cd ../
mv nzportable-psp.zip ../out/
cd ../

#
# Assemble NX Build
#

cd nx-assembly
mkdir assets
unzip -q ../nx-nzp-assets.zip -d assets/
unzip -q ../standard-nzp-qc.zip -d assets/nzportable/nzp
unzip -q ../nx-nzp-nro.zip -d $PWD
echo $BUILD_STRING > assets/nzportable/nzp/version.txt
mv nzportable.nacp assets/nzportable
mv nzportable.nro assets/nzportable
cd assets/
zip -q -r ../nzportable-switch.zip ./*
cd ../
mv nzportable-switch.zip ../out/
cd ../

#
# Assemble VITA Build
#
cd vita-assembly
mkdir assets
unzip -q ../vita-nzp-assets.zip -d assets/
unzip -q ../standard-nzp-qc.zip -d assets/data/nzp/nzp
unzip -q ../vita-nzp-vpk.zip -d $PWD
echo $BUILD_STRING > assets/data/nzp/nzp/version.txt
mv nzp.vpk assets/
cd assets/
zip -q -r ../nzportable-vita.zip ./*
cd ../
mv nzportable-vita.zip ../out/
cd ../

#
# Assemble 3DS Build
#
cd 3ds-assembly
mkdir assets
unzip -q ../3ds-nzp-assets.zip -d assets/
unzip -q ../standard-nzp-qc.zip -d assets/nzportable/nzp
unzip -q ../ctr-nzp-3dsx.zip -d assets/nzportable/
echo $BUILD_STRING > assets/nzportable/nzp/version.txt
cd assets/
zip -q -r ../nzportable-3ds.zip ./*
cd ../
mv nzportable-3ds.zip ../out/
cd ../

#
# Assemble TI-NSPIRE Build
#
cd nspire-assembly
mkdir assets
unzip -q ../nspire-nzp-assets.zip -d assets/
unzip -q ../standard-nzp-qc.zip -d assets/nzp
# Progs need renaming to .tns
mv assets/nzp/progs.dat assets/nzp/progs.dat.tns
unzip -q ../nspire-nzp-tns.zip -d assets/
echo $BUILD_STRING > assets/nzp/version.txt.tns
cd assets/
zip -q -r ../nzportable-nspire.zip ./*
cd ../
mv nzportable-nspire.zip ../out/
cd ../