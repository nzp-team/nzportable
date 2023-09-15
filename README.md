# Nazi Zombies: Portable

# About
This is the main/hub repository for NZ:P, a Call of Duty: Zombies "de-make" powered by various enhanced forks of the Quake engine, in development since 2009. This hub repository serves as a place to host nightly builds as well as a means of bug reporting on a game-wide (non-component) scale. See [the breakdown](#github-organzation-breakdown) for source code and other components.

The game itself is feature-equivalent with Call of Duty: World at War on a generic level. Gameplay components are implemented with minor parity differences. Most World at War maps and their unique features are not yet represented. Various small additions and changes from Call of Duty: Black Ops are present as a means of gameplay smoothing, but not on a wide scale. NZ:P is, first and foremost, a Call of Duty: World at War remake.

# Supported Platforms
* Linux (x86, x86_64, armhf, arm64)
* macOS†
* Nintendo Switch
* Nintendo 3DS
* PlayStation Portable (both "PHAT" (PSP-1000) and "SLIM" (PSP-2000 and higher))
* PlayStation VITA
* Windows (x86, x86_64)

# GitHub Organzation Breakdown
* [assets](https://github.com/nzp-team/assets): Game GFX, Sound, etc. data.
* [dquakeplus](https://github.com/nzp-team/dquakeplus): The NZ:P PSP engine, forked from dQuakePlus.
* [fteqw](https://github.com/nzp-team/fteqw): The NZ:P Windows, Mac, Linux, and Web engine. Powered by Spike's FTEQW, with minimal changes.
* [glquake](https://github.com/nzp-team/glquake): The NZ:P Nintendo 3DS engine, forked from ctrQuake.
* [quakespasm](https://github.com/nzp-team/quakespasm): The NZ:P Nintendo Switch and PS VITA engine, forked from QuakespasmNX.
* [quakec](https://github.com/nzp-team/quakec): The game-side code for things like weapons and Perk machines.
* [tools](https://github.com/nzp-team/tools): Misc. development tools.

# Screenshots

<center>
    <p float="left">
        <img src="screenshots/0.webp" width="400" />
        <img src="screenshots/1.webp" width="400" /> 
    </p>
    <p float="left">
        <img src="screenshots/2.webp" width="400" />
        <img src="screenshots/3.webp" width="400" /> 
    </p>
</center>

# Credits

#### Programming
Blubswillrule, Jukki, DR_Mabuse1981, Naievil, Cypress, Scatterbox

#### Models
Blubswillrule, Ju\[s]tice, Derped_Crusader

#### GFX
Blubswillrule, Ju\[s]tice, Cypress, Derped_Crusader

#### Sounds/Music
Blubswillrule, Biodude, Cypress, Marty P.

#### Special Thanks
* Spike, Eukara, Contributors: FTEQW
* Shpuld: CleanQC4FTE, heavy dQuakePlus optimization
* Crow_Bar, st1x51: (a)dQuake(plus)
* fgsfdsfgs: Quakespasm-NX
* MasterFeizz: ctrQuake
* Rinnegatamante: Initial VITA port, VITA Auto-Updater
* Azenn: GFX Assistance
* BCDeshiG: Extensive Testing

†macOS 10.10 Yosemite is a supported platform via the FTEQW engine. This means NZ:P is compatible with macOS, however, cross-compiling FTEQW for macOS via docker or similar has proved a challenge, and as such pre-builds with NZ:Ps changes are not yet available.