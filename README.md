<h1 align="center">
  <br>
  <img src="https://cdn.discordapp.com/attachments/1184152045456990249/1468246666950873343/Logo.png?ex=698352c4&is=69820144&hm=1942f5e1134843844bc1a7f3ea72f17ae14510fb905f59743be7c380110b64d9&" alt="JoyBoxOS" width="200"></a>
  <br>
  JoyBox OS
  <br>
</h1>

<h4 align="center"> Vim Configuration for all JoyJab Arcades </h4>

<p align="center">

![Version](https://img.shields.io/badge/dynamic/json?label=version&query=$.version&url=https://raw.githubusercontent.com/JoyJab-Games/Project-JoyBoxOS/main/version.json&color=green)

</p>

## Installation

- boot into a [minimal NixOS ISO ](https://nixos.org/download/)
- run the installer script ```bash <(curl -sL https://raw.githubusercontent.com/JoyJab-Games/Project-JoyBoxOS/main/bootstrap.sh)```
- profit

## Configuration
If you are setting up an unsupported PC follow these steps:

- Boot the PC from a NixOS ISO.
- Run ```nixos-generate-config --no-filesystems```
- Take the resulting hardware-configuration.nix and create a new hardware config under modules/hardware. Use eiter one of the existing disk-layouts or create a new one tailored to the PC.