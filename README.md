# workli

<img src="https://cdn.discordapp.com/attachments/546129764440604705/1087991121621303447/workli.png" alt="alt text" title="logo made by fengzi, bastardized by me" width="128" height="128">

### Simple Windows on Rockchip Linux Installer. 

Built for simplicity and compatibility.

# NOTE: The Windows on Rockchip project is currently highly experimental and not much works yet (see [here](https://worproject.com/guides/how-to-install/on-rockchip#what-works)).

#### Full dependency list:

> NOTE: The script gives commands for debian/arch to install these dependencies, this is just a refrence for other distros.

Required dependencies: `zenity`, `wimupdate`, `wimapply` and `wiminfo` ([wimlib](https://wimlib.net/)), `parted`, `mk.ntfs` ([ntfs-3g](https://github.com/tuxera/ntfs-3g)), `zip`, `gawk`, `xmlstarlet`.

Required dependencies for auto file downloads: `wget`.

Required dependencies for direct ESD download: `aria2c, curl`.

Required dependencies for auto ISO generation: `curl`, `jq`, `aria2c`, `cabextract`, `chntpw`, `mkisofs` or `genisoimage`.

Required dependencies for UEFI flashing to SPI: [rkdeveloptool](https://opensource.rock-chips.com/wiki_Rkdeveloptool).

## INSTRUCTIONS

1. Go to "Releases" and download the latest ["workli.sh"](https://github.com/buddyjojo/worli/releases/latest/download/workli.sh).

2. Put the script into an empty folder **WITH NO SPACES IN ITS NAME**!

3. Open a terminal in that folder and run `sudo bash workli.sh`, or `chmod +x workli.sh` and then `sudo ./workli.sh` (remove `sudo` if in a root shell)

4. Follow the on-screen instructions provided by the script

##

##### If you have any problems or suggestions, please create a GitHub issue or tell me in our Discard severe.

**Alsor chuck our out [Discard severe](https://discord.gg/26CMEjQ47g)!**
