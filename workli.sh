#!/bin/bash

# set default variables

export worklitmp="/tmp/workli"

# uselocal="1" # uncomment for using local files instead of auto download (use alongside $cache after first run to use cached files from previous runs)

# cache="1" # uncomment to not delete the tmp folder at the end (recommended to be used alongside $uselocal)

export spload="$worklitmp/rk3588_spl_loader_v1.08.111.bin" # https://dl.radxa.com/rock5/sw/images/loader/rock-5b/rk3588_spl_loader_v1.08.111.bin
export efi="$worklitmp/RK3588_NOR_FLASH_REL.img" # https://github.com/edk2-porting/edk2-rk35xx/releases

export uefntf="$worklitmp/bootaa64.efi" # https://github.com/pbatard/uefi-ntfs/releases
export uefntfd="$worklitmp/ntfs_aa64.efi" # https://github.com/pbatard/ntfs-3g/releases

export pei="$worklitmp/worklipe.cmd" # https://github.com/buddyjojo/workli/tree/master/files
export bexec="$worklitmp/batchexec.exe" # ^
export bcd="$worklitmp/BCD" # ^

export filepefiles="$worklitmp/pe-files.zip" # used for auto download only

if [[ $DEBUG == *"1"* ]]; then
    set -x
fi

if ! command -v zenity &> /dev/null
then
    echo "'zenity' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install zenity'; for Arch, run 'sudo pacman -S zenity')"
fi

if [ "$EUID" -ne 0 ]
    then zenity --title "workli" --info --ok-label="Exit" --text "This script needs to be run as root. If you're a noob, that's 'sudo ./workli.sh' or 'sudo bash workli.sh'"
    exit 1
fi

debug() {
 echo -e "\e[1;36m[DEBUG]\e[0m $1" >&2
}
error() {
 zenity --error --title "workli" --text "An error has occurred.\n\nError: $1"
 echo -e "\e[1;31m[ERROR]\e[0m $1" >&2
 exit 1
}

if ! command -v wimupdate &> /dev/null
then
    wimtool=" - 'wimtools/wimlib' package not installed.\n\n"
    wimtoold="wimtools "
    wimtoola="wimlib "
    export reqdep=1
fi

if ! command -v parted &> /dev/null
then
    parted=" - 'parted' package not installed.\n\n"
    partedp="parted "
    export reqdep=1
fi

if ! command -v mkfs.ntfs &> /dev/null
then
    exfat=" - 'mkfs.ntfs' command not found.\n\n"
    ntfsp="ntfs-3g "
    export reqdep=1
fi

if ! command -v gawk &> /dev/null
then
    gawk=" - 'gawk' package not installed.\n\n"
    gawkp="gawk "
    export reqdep=1
fi

if ! command -v xmlstarlet &> /dev/null
then
    xmlstarle=" - 'xmlstarlet' package not installed.\n\n"
    xmartletp="xmlstarlet "
    export reqdep=1
fi

if [[ $reqdep == *"1"* ]]; then
    zenity --title "workli" --info --ok-label="Exit" --text "Mandatory dependencies:\n\n$wimtool$parted$exfat$gawk$xmlstarle\nInstall them:\n\nFor Debian and Ubuntu, run: \"sudo apt install $wimtoold$partedp$ntfsp$gawkp$xmlstarletp\"\n\nFor Arch, run: \"sudo pacman -S $wimtoola$partedp$ntfsp$gawkp$xmlstarletp\""
    exit 1
else
    debug "All mandatory dependencies are met!"
fi

if ! command -v wget &> /dev/null
then
    wgeta=" - 'wget' package not installed (used for boot files and UEFI files downloading).\n\n"
    wgetp="wget "
    export optdep=1
fi

if ! command -v aria2c &> /dev/null
then
    aria=" - 'aria2c' package not installed (used for ESD downloading).\n\n"
    ariap="aria2 "
    export optdep=1
fi

if ! command -v curl &> /dev/null
then
    curle=" - 'curl' package not installed (used for ESD downloading).\n\n"
    curlp="curl "
    export optdep=1
fi

if ! command -v jq &> /dev/null
then
    jqe=" - 'jq' package not installed (used for UEFI image downloading).\n\n"
    jqp="jq "
    export optdep=1
fi

if ! command -v rkdeveloptool &> /dev/null
then
    rkdevtoola=" - 'rkdeveloptool' package not installed (used for UEFI spi flashing). Install it (some distros may not have it yet, in that case you'd need to <a href='https://opensource.rock-chips.com/wiki_Rkdeveloptool'>compile it</a>\n\n"
    export optdep=1
fi

if [[ $optdep == *"1"* ]]; then
    zenity --title "workli" --info --ok-label="Continue" --text "Optional dependencies:\n\n$wgeta$aria$curle$jqe$rkdevtoola\nInstall them:\n\nFor Debian and Ubuntu, run: \"sudo apt install $wgetp$ariap$curlp$jqp\"\n\nFor Arch, run: \"sudo pacman -S $wgetp$ariap$curlp$jqp\""
else
    debug "All optional dependencies are met!"
fi

zenity --title "workli" --info --ok-label="Next" --text "WoRKli, made by JoJo Autoboy#1931\n\nNot really based off of Mario's WoR Linux <a href='https://worproject.com/guides/how-to-install/on-rockchip'>guide</a>"

mkdir -p "$worklitmp/"
chmod 777 "$worklitmp/"

if [[ $uselocal == *"1"* ]]; then

    debug "uselocal set to 1, skipping auto download..."

else
    if ! command -v wget &> /dev/null
    then
        zenity --title "workli" --info --ok-label="Exit" --text "'wget' package not installed. Install it\n\nFor Debian and Ubuntu, run 'sudo apt install $wgetp'\n\nFor Arch, run 'sudo pacman -S $wgetp'\n\nFor macOS, run 'brew install $wgetp'"
        exit 1
    fi

    wget -O "$uefntf" "https://github.com/pbatard/uefi-ntfs/releases/latest/download/bootaa64.efi" || error "Failed to download bootaa64.efi from pbatard/uefi-ntfs"
    wget -O "$uefntfd" "https://github.com/pbatard/ntfs-3g/releases/latest/download/ntfs_aa64.efi" || error "Failed to download ntfs_aa64.efi from pbatard/ntfs-3g"
    wget -O "$filepefiles" "https://github.com/buddyjojo/workli/releases/latest/download/y-pe-files.zip" || error "Failed to download y-pe-files.zip from buddyjojo/workli"

    unzip -o "$filepefiles" -d "$worklitmp/"

    export auto="1"
fi

if [[ -f $uefntf ]]; then
    debug "'bootaa64.efi' found"
else
    error "'bootaa64.efi' does not exist."
    exit 1
fi
if [[ -f $uefntfd ]]; then
    debug "'ntfs_aa64.efi' found"
else
    error "'ntfs_aa64.efi' does not exist."
    exit 1
fi
if [[ -f $pei ]]; then
    debug "'worklipe.cmd' found"
else
    error "'worklipe.cmd' does not exist."
    exit 1
fi
if [[ -f $bexec ]]; then
    debug "'batchexec.exe' found"
else
    error "'batchexec.exe' does not exist."
    exit 1
fi
if [[ -f $bcd ]]; then
    debug "'batchexec.exe' found"
else
    error "'batchexec.exe' does not exist."
    exit 1
fi

zenity --question --title="workli" --text "Do you want to flash the UEFI bootloader? (mandatory for first time run)"

case $? in
    [0])

if [[ $uselocal == *"1"* ]]; then

    debug "uselocal set to 1, skipping auto download..."

else
    if ! command -v wget &> /dev/null
    then
        zenity --title "workli" --info --ok-label="Exit" --text "'wget' package not installed. Install it\n\nFor Debian and Ubuntu, run 'sudo apt install $wgetp'\n\nFor Arch, run 'sudo pacman -S $wgetp'\n\nFor macOS, run 'brew install $wgetp'"
        exit 1
    fi
    
    gitjson=$(curl https://api.github.com/repos/edk2-porting/edk2-rk35xx/releases/latest)
    
    efiFILE=$(echo $gitjson | jq -r '.assets[] | .name' | gawk '{ printf "FALSE""\0"$0"\0" }' | xargs -0 zenity --list --title="workli" --text="What device do you have?\n\nNote: device support may vary and may not work\n\nOfficaly supported boards: Orange pi 5, Rock 5a" --radiolist --multiple --column ' ' --column 'Devices' --height=450)
    
    efiURL=$(echo $gitjson | jq --arg efifile "$efiFILE" -r '.assets[] | select( .name | match($efifile)) | .browser_download_url ')
    
    wget -O "$efi" "$efiURL" || error "Failed to download RK3588_NOR_FLASH_REL.img"

    export auto="1"
    
fi

if [[ -f $efi ]]; then
    debug "UEFI img found"
else
    error "UEFI img does not exist."
fi

zenity --question --title="workli" --text "Do you want to install the UEFI to SPI/EMMC or SD card plugged into host?" --ok-label="SPI" --cancel-label="SD"
case $? in
    [0])
    export UEFI="SPI"

    zenity --title "workli" --info --ok-label="Next" --text "Put the board into Maskrom mode and plug it into the host, depends on device but the Rock 5 and Orange Pi 5 follow about the <a href='https://wiki.radxa.com/Rock5/install/spi#3.29_Boot_the_board_to_Maskrom_mode'>same method</a>\n\n<span color=\"red\">DO THIS BEFORE CONTINUING</span>"


    if ! command -v rkdeveloptool &> /dev/null
    then
        zenity --title "workli" --info --ok-label="Exit" --text "'rkdeveloptool' not installed. Install it (some ditros may not have it yet, in that case you'd need to <a href='https://wiki.radxa.com/Rockpi4/install/rockchip-flash-tools#Part_two:_rkdeveloptool_on_Linux'>compile it</a>"
        exit 1
    fi

    if [[ $uselocal == *"1"* ]]; then
    
        debug "uselocal set to 1, skipping auto download..."
    
    else
        if ! command -v wget &> /dev/null
        then
            zenity --title "workli" --info --ok-label="Exit" --text "'wget' package not installed. Install it\n\nFor Debian and Ubuntu, run 'sudo apt install $wgetp'\n\nFor Arch, run 'sudo pacman -S $wgetp'\n\nFor macOS, run 'brew install $wgetp'"
            exit 1
        fi

        wget -O "$spload" "https://dl.radxa.com/rock5/sw/images/loader/rock-5b/rk3588_spl_loader_v1.08.111.bin" || error "Failed to download rk3588_spl_loader_v1.08.111.bin"
    fi


    if [[ -f $efi ]]; then
        debug "'rk3588_spl_loader_v1.08.111.bin' found"
    else
        error "'rk3588_spl_loader_v1.08.111.bin' does not exist."
    fi


    if rkdeveloptool ld | grep -q 'Maskrom'
    then

    (

        rkdeveloptool db $spload >&2 || error "Unable to load the loader"

        rkdeveloptool wl 0 $efi >&2 || error "unable to flash to SPI"

        rkdeveloptool rd >&2

        zenity --title "workli" --info --ok-label="Continue" --text "The SPI flash suceeded!, device has been reset and should have booted into the UEFI"

    ) |
        zenity --progress \
        --title="workli" \
        --text="Flashing SPI...." \
        --pulsate \
        --auto-close
        (( $? != 0 )) && exit 1

    else
        zenity --title "workli" --info --ok-label="Exit" --text "Board not plugged in/not in Maskrom mode"
        exit 1
    fi

    ;;
    [1])

        zenity --question --title="workli" --text "Are you installing Windows to the same SD card or just using it for the bootloader?\n\n<span color=\"red\">NOTE: SAME SD OPTION CURRENTLY BROKEN\n\nSame sd requires custom uefi image</span>" --ok-label="Only bootloader" --cancel-label="Same SD"

        case $? in
            [0])

                disko () {

                export fdisk=$(parted -l | grep "Disk /dev*" | grep -v loop | sort | gawk '{ printf "FALSE""\0"$0"\0" }' | xargs -0 zenity --list --title="workli" --text="Where in /dev/ is your SD card?" --radiolist --multiple --column ' ' --column 'Disks' --extra-button "Rescan")

                (( $? != 0 )) && exit 1

                sdisk=${fdisk#Disk /dev/*}
                disk="${sdisk%%:*}"

                }

                disko

                while [[ $fdisk == *"Rescan"* ]]; do
                    disko
                done

                zenity --question --title="workli" --text "You have selected '$disk', is this correct?"

                case $? in
                    [0])
                    debug "ok '$disk' it is then"
                    ;;
                    [1])
                    exit 1
                    ;;
                    *)
                    exit 1
                    ;;
                esac

                if [[ $disk == *"/dev"* ]]; then
                    error "how.... ('/dev' is in disk name)"
                else
                    debug "Disk name format correct"
                fi

                if [[ -b "/dev/$disk" ]]; then
                debug "'$disk' found"
                else
                error "'$disk' does not exist."
                fi

                zenity --question --title="workli" --text '<span color=\"red\">WARNING: THE SD '$disk' WILL BE WIPED! (have 8MB dded to it)</span>\n\nDo you want to continue?' --ok-label="No" --cancel-label="Yes"

                case $? in
                    [1])
                    debug "No going back now"
                    ;;
                    [0])
                    exit 1
                    ;;
                    *)
                    error "Invalid input"
                    ;;
                esac

                umount /dev/$disk*

                dd if="$efi" of=/dev/$disk conv=fsync || error "Failed to dd UEFI"

            ;;
            [1])
            export UEFI="SD"
            zenity --title "workli" --info --ok-label="Continue" --text "UEFI will be flashed to the sd card during partitioning"
            ;;
            *)
            exit 1
            ;;
        esac

    ;;
    *)
    error "Invalid input"
    exit 1
    ;;
esac

    ;;
    [1])
    debug "UEFI not flashed"
    ;;
    *)
    exit 1
    ;;
esac

dwnopt=$(zenity --question --title="workli" --text "Do you want to:\n\n(1) Let this script download an ESD directly from Microsoft (Recommended, release versions only, gives more type options)\n(2) Generate ISO with UUP Dump (Slower, for insider builds)\n(3) Use your own ISO/ESD or a previously generated/downloaded one" --switch --extra-button "1" --extra-button "2" --extra-button "3")

case $dwnopt in

    1)

if ! command -v aria2c &> /dev/null
then
    aria=" - 'aria2c' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install aria2'; for Arch, run 'sudo pacman -S aria2')\n\n"
    export reqdep=1
fi

if ! command -v curl &> /dev/null
then
    curle=" - 'curl' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install curl'; for Arch, run 'sudo pacman -S curl')\n\n"
    export reqdep=1
fi

if [[ $reqdep == *"1"* ]]; then
    zenity --title "workli" --info --ok-label="Exit" --text "Dependencies:\n\n$aria$curle"
    exit 1
else
    debug "All dependencies are met!"
fi

getversionsxml=$(curl -s -G 'https://worproject.com/dldserv/esd/getversions.php')

winversion=$(echo $getversionsxml | xmlstarlet sel -t -v /productsDb/versions/version/@number | zenity --list --title="workli" --text="What Windows version do you want?" --column 'Windows version')

if [[ -z "${winversion// }" ]]; then
    debug "none selected, using latest"
    winversion=$(echo $getversionsxml | xmlstarlet sel -t -v /productsDb/versions/*[1]/@number - )
fi

debug "Windows version is $winversion"

winbuild=$(echo $getversionsxml | xmlstarlet sel -t -m /productsDb/versions/version[@number=$winversion]/releases/release -o " " -v ./@build -o " " - )

winbuild=$(zenity --list --title="workli" --text="What Windows build would you like?\n\nNote: defaults to latest if none are selected" --column 'Windows build' $winbuild --height=300)

if [[ -z "$winbuild" ]]; then
    debug "none selected, using latest"
    winbuild=$(echo $getversionsxml | xmlstarlet sel -t -v /productsDb/versions/version[@number=$winversion]/releases/*[1]/@build - )
fi

debug "Windows build is $winbuild"

getcatalogxml=$(curl -s -G 'https://worproject.com/dldserv/esd/getcatalog.php' -d arch=ARM64 -d ver=$winversion -d build=$winbuild)

winedition=$(echo $getcatalogxml | xmlstarlet sel -t -m "/MCT/Catalogs/Catalog/PublishedMedia/Files/File[not(./Edition_Loc=preceding-sibling::File/Edition_Loc)]" -o " " -v "Edition_Loc" -o " " - | sed s/%//g)
winedition="${winedition:1}"

winedition=$(zenity --list --title="workli" --text="What Windows edition would you like?\n\nNote: Client is your 'normal' Windows versions (home and pro)\n\nEnterprise is self descriptive" --column 'Windows edition' $winedition --height=300)

if [[ -z "$winedition" ]]; then
    debug "none selected, using first edition that should be Client"
    winedition=$(echo $getcatalogxml | xmlstarlet sel -t -v /MCT/Catalogs/Catalog/PublishedMedia/Files/File[1]/Edition_Loc -| sed s/%//g )
fi

debug "Windows edition is $winedition"

winlanguage=$(echo $getcatalogxml | xmlstarlet sel -t -v /MCT/Catalogs/Catalog/PublishedMedia/Files/File/Language | zenity --list --title="workli" --text="What Windows language would you like?" --column 'Windows Language' --width=300 --height=300)

if [[ -z "${winlanguage// }" ]]; then
    debug "none selected, using english"
    winlangcode="en-us"
    winlanguage="default"
else
    winlangcode=$(echo $getcatalogxml | xmlstarlet sel -t -m "/MCT/Catalogs/Catalog/PublishedMedia/Files/File[Language='$winlanguage' and Edition_Loc='%$winedition%']" -v LanguageCode - )
fi

debug "Windows language is $winlanguage, lang code is $winlangcode"

esdurl=$(echo $getcatalogxml | xmlstarlet sel -t -m "/MCT/Catalogs/Catalog/PublishedMedia/Files/File[LanguageCode='$winlangcode' and Edition_Loc='%$winedition%']" -v FilePath - )

debug "ESD link is $esdurl"

tmpuupvar=$(zenity --question --title="workli" --text "Do you want the ESD to be deleted when the script finishes?\n\nNote: The ESD will be put in the current directory ($PWD)\n\nNote: The /tmp option is not recommended as /tmp can be too small to fit the ESD (~3.6GB)\n\nNote: The /tmp option will delete the ESD when the script finishes" --extra-button "Download ESD in /tmp")

case $? in
    [0])
    export esdpth="$(pwd)"
    export delesd=1
    ;;
    [1])
    export esdpth="$(pwd)"
    ;;
    *)
    exit 1
    ;;
esac

if [[ $tmpuupvar == "Download ESD in /tmp" ]]; then
    export esdpth="$worklitmp/tmpesd"
    mkdir "$esdpth"
    export tmpesd=1
fi

if [[ -f $esdpth/win.esd ]] ; then

zenity --question --title="workli" --text "Previously generated win.esd found in $esdpth/win.esd, would you like to delete it?"

case $? in
    [0])
    rm "$esdpth/win.esd"
    ;;
    [1])
    error "Please remove or rename file $esdpth/win.esd (or use it with option 2)"
    ;;
    *)
    exit 1
    ;;
esac

fi

zenity --title "workli" --info --ok-label="Continue" --text "The aria2c download will now be ran\nIts output will be in the terminal where this script was run"

esddwn() {
 aria2c -d $esdpth -o "win.esd" $esdurl >&2
}

(

esddwn
if [[ $? -ne 0 ]]; then
    echo "# Download failed, trying again... Current amount of attempts: $counter"
    sleep 5
    esddwn
    while [ $? -ne 0 ]; do
        counter=$(( counter + 1 ))
        echo "# Download failed, trying again... Current amount of attempts: $counter"
        sleep 5
        esddwn
    done
else
    zenity --title "workli" --info --ok-label="Continue" --text "The ESD download suceeded!"
fi

) |
zenity --progress \
  --title="workli" \
  --text="Downloading ESD...." \
  --pulsate \
  --auto-close

(( $? != 0 )) && exit 1

export iso="$esdpth/win.esd"
export esd=1

    ;;
    2)

if ! command -v curl &> /dev/null
then
    curle=" - 'curl' command not found.\n\n"
    curlep="curl "
    export reqdep=1
fi

if ! command -v jq &> /dev/null
then
    jq=" - 'jq' command not found.\n\n"
    jqp="jq "
    export reqdep=1
fi

if ! command -v aria2c &> /dev/null
then
    aria2c=" - 'aria2c' command not found.\n\n"
    aria2p="aria2 "
    export reqdep=1
fi

if ! command -v cabextract &> /dev/null
then
    cabextract=" - 'cabextract' command not found.\n\n"
    cabextractp="cabextract "
    export reqdep=1
fi

if ! command -v chntpw &> /dev/null
then
    chntpw=" - 'chntpw' command not found.\n\n"
    chntpwp="chntpw "
    export reqdep=1
fi

if ! command -v mkisofs &> /dev/null && ! command -v genisoimage &> /dev/null
then
    mkisofs=" - 'genisoimage or mkisofs' command not found.\n\n"
    mkisofsdeb="genisoimage "
    export reqdep=1
fi

if [[ $reqdep == *"1"* ]]; then
    zenity --title "workli" --info --ok-label="Exit" --text "Dependencies:\n\n$curle$jq$aria2c$cabextract$chntpw$mkisofs\nInstall them:\n\nFor Debaian and Ubuntu, run 'sudo apt install $curlep$jqp$aria2p$cabextractp$chntpwp$mkisofsdeb'\n\nFor Arch, run 'sudo pacman -S $curlep$jqp$aria2p$cabextractp$chntpwp$mkisofsarmc'"
    exit 1
else
    debug "All dependencies are met!"
fi

zenity --question --title="workli" --text "Do you want to use the latest retail/dev builds or enter your own uupdump.net build id? Press 'No' to use id"

case $? in
    [1])
    updateid=$(zenity --title "workli" --entry --text "What's the uupdump.net uuid?\nE.g. Once you select the build you want the id will be in the url like:\n\nhttps://uupdump.net/selectlang.php?id= '6b1e576c-9854-44b4-9cdd-108d13cf0035'")

    foundBuild=$(curl -sk "https://uupdump.net/json-api/listlangs.php?id=$updateid" | jq -r '.response.updateInfo.title')

    if [[ $? -ne 0 ]]; then
        error "Got rate limited or id is incrorrect, please try again"
    else
        debug "Not null thats good"
    fi

    ;;
    [0])
    release=$(zenity --list --title="workli" --text="What windows release type do you want?\n\nNote: Defaults to Public Release\n\nNOTE: Dev builds will not boot on pi 4 and below" --column 'Release type'  "Latest Public Release build" "Latest Dev Channel build" --height=300)

    if [[ $release == "Latest Dev Channel build" ]]; then
        export ring="wif&build=latest"
    else
        export ring="retail&build=19041.1"
    fi

    apiget=$(curl "https://uupdump.net/json-api/fetchupd.php?arch=arm64&ring=$ring" | jq -r '.response.updateArray[] | select( .updateTitle | contains("Windows")) | {Id: .updateId, Name: .updateTitle} ')

    if [[ $? -ne 0 ]]; then
        error "Probably got rate limited, please try again"
    else
        debug "Not null thats good"
    fi

    updateid=$(echo $apiget | jq -r .Id)

    foundBuild=$(echo $apiget | jq -r .Name)
    ;;
    *)
    exit 1
    ;;
esac

debug $foundBuild

zenity --question --title="workli" --text "You are about to download:\n\n'$foundBuild'\n\nIs this ok?"

case $? in
    [0])
    debug "ok '$foundBuild' it is then"
    ;;
    [1])
    exit 1
    ;;
    *)
    exit 1
    ;;
esac

langjson=$(curl -sk "https://uupdump.net/json-api/listlangs.php?id=$updateid" | jq -r '.response.langFancyNames')

if [[ $? -ne 0 ]]; then
    error "Probably got rate limited, please try again"
else
    debug "Not null thats good"
fi

var=$(echo "$langjson" | cut -d\" -f4 | tr -d '{}' | tr '\n' '|'); var="${var#?}"; var="${var%?}"; var="${var%?}"

langa=$(zenity --forms --title "workli" --text "language" --add-combo "Choose your language." --combo-values "$var")

if [[ -z "$langa" ]]
    then error "No language was selected"
fi

language=$(echo "$langjson" | grep "$langa" | cut -d\" -f2)

debug "Language is $language"

tmpuupvar=$(zenity --question --title="workli" --text "Do you want the ISO to be deleted when the script finishes?\n\nNote: The UUP files and ISO will be put in the current directory ($PWD/uup)\n\nNote: The /tmp option is not recommended as /tmp can be too small to fit the files needed (4gb+)\n\nNote: The /tmp option will delete the ISO when the script finishes" --extra-button "Generate ISO in /tmp")

case $? in
    [0])
    uuproot="$(pwd)"
    export deluup=1
    ;;
    [1])
    uuproot="$(pwd)"
    ;;
    *)
    exit 1
    ;;
esac

if [[ $tmpuupvar == "Generate ISO in /tmp" ]]; then
    uuproot="$worklitmp/tmpuup"
    mkdir "$uuproot"
    export tmpuup=1
fi

wget -O "$worklitmp/UUP.zip" "https://uupdump.net/get.php?id=$updateid&pack=en-us&edition=professional&autodl=2" || error "Failed to download UUP.zip"

export uupzip=1

unzip "$worklitmp/UUP.zip" -d "$uuproot/uup"

zenity --question --title="workli" --text "UUP Dump is known to be unstable sometimes and may require multiple tries to sucessfully download all reqired files.\n\nTo combat this, do you want to enable auto retry? It will indefinitely rerun the UUP script until it succeeds.\n\nYou can stop this any time by pressing the cancel button on the 'progress' window or by ctrl+c'ing the terminal this script is running from"

case $? in
    [0])
    export autoretry=1
    export counter=1
    ;;
    [1])
    export autoretry=0
    ;;
    *)
    exit 1
    ;;
esac

zenity --title "workli" --info --ok-label="Continue" --text "The UUP Dump script will now be executed\nIts output will be in the terminal where this script was run"

cd $uuproot/uup

chmod +x uup_download_linux.sh

isogen() {
 ./uup_download_linux.sh >&2
}

(

isogen
if [[ $? -ne 0 ]]; then
    if [[ $autoretry == *"1"* ]]; then
    echo "# Auto-retry enabled, current amount of attempts: $counter"
    sleep 5
    isogen
    while [ $? -ne 0 ]; do
        counter=$(( counter + 1 ))
        echo "# Auto-retry enabled, current amount of attempts: $counter"
        sleep 5
        isogen
    done
    else
    error "Auto-retry disabled, quitting scritpt"
    fi
else
    zenity --title "workli" --info --ok-label="Continue" --text "The UUP Dump script suceeded!"
fi

) |
zenity --progress \
  --title="workli" \
  --text="Generating ISO...." \
  --pulsate \
  --auto-close

(( $? != 0 )) && exit 1

cd ../

if [[ -f "$uuproot/uup/"*ARM64*.ISO ]]; then
    debug "ISO found"
    iso=$(find $uuproot/uup/ -name "*ARM64*.ISO")
    export fulliso=1
else
    error "ISO not found"
fi

    ;;
    3)

zenity --title "workli" --info --ok-label="Next" --text "Prerequisites\n\n- Get the windows ESD/ISO: <a href='https://worproject.com/guides/getting-windows-images'>https://worproject.com/guides/getting-windows-images</a>\n\n- Rename the ESD/ISO file to 'win.iso' or 'win.esd'\n\n- If you want use use a modified install.wim, rename it to 'install.wim'\n\n<span color=\"red\">DO THE PREREQUISITES BEFORE CONTINUING</span>"

if [[ -f $(pwd)/win.esd ]] || [[ -f "$worklitmp/tmpesd/win.esd" ]] ; then

zenity --question --title="workli" --text "Previously downloaded ESD found, would you like to use that or use another one?"

case $? in
    [0])

    if [[ -f "$worklitmp/tmpesd/win.esd" ]]; then
        iso="$worklitmp/tmpesd/win.esd"
        export esd=1
    else
        iso="$(pwd)/win.esd"
        export esd=1
    fi

    ;;
    [1])
    iso=$(zenity --title "workli" --entry --text "What's the path to the 'win.esd' or 'install.wim' or 'win.iso'?\n\nE.g. '~/win.iso'")
    ;;
    *)
    exit 1
    ;;
esac

else

iso=$(zenity --title "workli" --entry --text "What's the path to the 'win.esd' or 'install.wim' or 'win.iso'?\n\nE.g. '~/win.iso'")

fi

    ;;

    *)

    error "Invalid input"
    exit 1
    ;;
esac

if [[ -f "$iso" ]]; then
    debug "'win.iso/install.wim/win.esd' found"
else
    error "'win.iso/install.wim/win.esd' does not exist. The iso variable was set to '$iso'"
fi

if [[ $iso =~ \.[Ww][Ii][Mm]$ ]]; then
    export fulliso=0
    export esd=0
    debug "WIM detected = $fulliso, $iso"
    typexml=$(wiminfo --xml $iso | xmlstarlet fo)
elif [[ $iso =~ \.[Ee][Ss][Dd]$ ]]; then
    export esd=1
    export fulliso=0
    debug "ESD detected = $esd, $iso"
    typexml=$(wiminfo --xml $iso | xmlstarlet fo)
else
    export fulliso=1
    export esd=0
    debug "Full ISO detected = $fulliso, $iso"

    debug "Mounting ISO for type selection"

    mkdir -p "$worklitmp/isomount"
    chmod 777 "$worklitmp/isomount"

    mount "$iso" "$worklitmp/isomount"

    typexml=$(wiminfo --xml "$worklitmp/isomount/sources/install.*" | xmlstarlet fo)

    umount "$worklitmp/isomount"

    rm -rf "$worklitmp/isomount"
fi

windtype=$(echo "$typexml"  | xmlstarlet sel -t -v /WIM/IMAGE/NAME | gawk '{ printf "FALSE""\0"$0"\0" }' | sed 's/\(.*\)FALSE/\1TRUE/' |zenity --list --title="workli" --text="What windows type do you want?\n\nNote: some windows types may not be bootable" --radiolist --multiple --column ' ' --column 'Windows type' --width=300 --height=300)

wintype=$(echo "$typexml" | xmlstarlet sel -t -v "/WIM/IMAGE[NAME='$windtype']/@INDEX")

debug "wintype(index) is $wintype"

disko () {

export fdisk=$(parted -l | grep "Disk /dev*" | grep -v loop | sort | gawk '{ printf "FALSE""\0"$0"\0" }' | xargs -0 zenity --list --title="workli" --text="Where in /dev/ is your drive?" --radiolist --multiple --column ' ' --column 'Disks' --extra-button "Rescan")

(( $? != 0 )) && exit 1

sdisk=${fdisk#Disk /dev/*}
disk="${sdisk%%:*}"

}

disko

while [[ $fdisk == *"Rescan"* ]]; do
    disko
done

zenity --question --title="workli" --text "You have selected '$disk', is this correct?"

case $? in
    [0])
    debug "ok '$disk' it is then"
    ;;
    [1])
    exit 1
    ;;
    *)
    exit 1
    ;;
esac

if [[ $disk == *"mmcblk"* ]]; then
    export nisk="${disk}p"
else
    export nisk="$disk"
fi

if [[ $disk == *"disk"* ]]; then
    export nisk="${disk}s"
else
    export nisk="$disk"
fi

if [[ $disk == *"/dev"* ]]; then
    error "how.... ('/dev' is in disk name)"
else
    debug "Disk name format correct"
fi

if [[ -b "/dev/$disk" ]]; then
   debug "'$disk' found"
else
   error "'$disk' does not exist."
fi

zenity --question --title="workli" --text '<span color=\"red\">WARNING: THE DISK '$disk' WILL BE WIPED!</span>\n\nDo you want to continue?' --ok-label="No" --cancel-label="Yes"

case $? in
    [1])
    debug "No going back now"
    ;;
    [0])
    exit 1
    ;;
    *)
    error "Invalid input"
    ;;
esac

(

echo "# Creating partitions..."

echo "10"

debug "Creating partitions..."

umount /dev/$disk*

parted -s /dev/$disk mklabel gpt

if [[ $UEFI == *"SD"* ]]; then
    debug "installing fully to sd"
    dd if="$efi" of=/dev/$disk bs=512 seek=64 conv=fsync || error "Failed to dd UEFI"
    parted -s /dev/$disk mkpart primary 8MB 128MB
else
    parted -s /dev/$disk mkpart primary 1MB 128MB
fi

parted -s /dev/$disk set 1 esp on
parted -s /dev/$disk set 1 boot on

echo "20"

parted -s -- /dev/$disk mkpart primary 145MB -0
parted -s /dev/$disk set 2 msftdata on

sync
mkfs.fat -F 32 /dev/$nisk'1' || error "Failed to format disk"
sync

mkfs.ntfs -f /dev/$nisk'2' || error "Failed to format disk"
sync

echo "30"

echo "# Copying Windows files to the drive...\n\nThis will take a while.\n\nProgress shown in terminal..."
debug "Copying Windows files to the drive."

if [[ $fulliso == *"1"* ]]; then

    mkdir -p "$worklitmp/isomount"
    chmod 777 "$worklitmp/isomount"

    mount "$iso" "$worklitmp/isomount"

    wimapply --check "$worklitmp/isomount/sources/install.*" $wintype /dev/$nisk'2' >&2

    umount "$worklitmp/isomount"

    rm -rf "$worklitmp/isomount"

else
    wimapply --check "$iso" $wintype /dev/$nisk'2' >&2
fi

echo "40"

echo "# Mounting partitions..."

mkdir -p "$worklitmp/bootpart" "$worklitmp/winpart"

mount /dev/$nisk'1' "$worklitmp/bootpart"
mount /dev/$nisk'2' "$worklitmp/winpart"

echo "50"

echo "# Copying boot files..."

mkdir -p "$worklitmp/bootpart/EFI/Boot/"
mkdir -p "$worklitmp/bootpart/EFI/Rufus/"

debug "${uefntf}, ${uefntfd}"

cp ${uefntf} "$worklitmp/bootpart/EFI/Boot/"
cp ${uefntfd} "$worklitmp/bootpart/EFI/Rufus/"

mkdir -p "$worklitmp/winpart/EFI/Boot/"
mkdir -p "$worklitmp/winpart/EFI/Microsoft/Boot/Resources"

cp "$worklitmp/winpart/Windows/Boot/EFI/bootmgfw.efi" "$worklitmp/winpart/EFI/Boot/bootaa64.efi"
cp ${bcd} "$worklitmp/winpart/EFI/Microsoft/Boot/BCD"
cp "$worklitmp/winpart/Windows/Boot/EFI/winsipolicy.p7b" "$worklitmp/winpart/EFI/Microsoft/Boot/winsipolicy.p7b"
cp "$worklitmp/winpart/Windows/Boot/Resources/bootres.dll" "$worklitmp/winpart/EFI/Microsoft/Boot/Resources/bootres.dll"
cp -r "$worklitmp/winpart/Windows/Boot/EFI/CIPolicies" "$worklitmp/winpart/EFI/Microsoft/Boot/"
cp -r "$worklitmp/winpart/Windows/Boot/Fonts" "$worklitmp/winpart/EFI/Microsoft/Boot/"

echo "60"

echo "# Editing WinRE..."

winrewim=$(find "$worklitmp/winpart/Windows/System32/Recovery/" -type f -name [Ww]inre.wim)

cp "$winrewim" "$worklitmp/winpart/Windows/System32/Recovery/backup-winre.wim"

wimupdate "$winrewim" 1 --command="add ${pei} /worklipe.cmd"

wimupdate "$winrewim" 1 --command="delete /sources/recovery/RecEnv.exe"

wimupdate "$winrewim" 1 --command="add ${bexec} /sources/recovery/RecEnv.exe"

echo "80"
echo "# Unmounting drive...\n\nThis may also take a while..."
debug "Unmounting drive"

sync

umount /dev/$disk*

echo "90"
echo "# Cleaning up..."

if [[ $cache == *"1"* ]]; then
    debug "cache set to 1, skipping tmp deletion"
    debug "uncomment uselocal at top of script to use cached files"
else
    rm -rf "$worklitmp/"
fi

if [[ $deluup == *"1"* ]]; then
    rm -rf "$uuproot/uup"
else
    debug "UUPs set to not be deleted"
fi

if [[ $delesd == *"1"* ]]; then
    rm -rf "$esdpth"
else
    debug "ESD set to not be deleted"
fi

echo "100"
echo "# Press OK to continue"

) |
zenity --progress \
  --title="workli" \
  --text="Creating partitions..." \
  --percentage=0

(( $? != 0 )) && exit 1

zenity --title "workli" --info --ok-label="Done!" --text "Booting\n\n1. Connect the drive and other peripherals to your board then boot it up.\n\n2. Assuming everything went right in the previous steps, the device will boot up to a PE enviroment where it will do some configuring and then reboot into hopefully a full Windows install.\n\nAll done :)\nThanks for using WoRKli"

debug "It has finnished"

exit 0
