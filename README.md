
Conky Manager
=======================

Simple tool for managing Conky configs.
...

# Conky Manager 2 - a newer conky config manager

This is a fork of the old original Conky Manager by teejee2008(Tony George).

This latest version supports Ubuntu 16-22 versions as well as Mint 18-21.x and any other Ubuntu flavor or derivative.

It also provides support for the newer lua-based conky and configuration files(v1.10)


## Installation

**For Ubuntu and derivatives:**

```bash
sudo add-apt-repository ppa:teejee2008/foss
sudo apt update
sudo apt install conky-manager2
```

**Other Distributions**

Right now, the alternate installation method is to download and compile this source package, but it's only a few simple commands. It will provide `make install` as well as building a `.deb`.

Please see document [HOWTOBUILD.md](./HOWTOBUILD.md)

(macOS note: To build this newer version for macOS you can use the git software if it is installed. Please see the 2 instructions in the following HOWTOBUILD.md document on how to [clone this repository](./HOWTOBUILD.md#clone-this-repository) -Alternately, you can use the magic green button to download the zip file, and then you extract it. Be sure to open Terminal into the source file directory. Then to do the actual software build and installation, follow the instructions provided here: [https://github.com/npyl/conky-manager](https://github.com/npyl/conky-manager#conky-manager) )

