# NixOS configuration.nix

## Usage

When installing NixOS, you want to use a configuration.nix file to configure your entire OS. This includes setting up users and installing particular system level programs and/or user specific programs. Here is my configuration file that I use to configure my personal NixOS environment. Starting out on nix? Check out the cheatsheet [vector wiki](https://nixos.wiki/index.php?title=Cheatsheet&useskin=vector) page.

### How to install hosts

Since this is a custom nix-config, you can configure your hosts by running the following command below:

```bash
git submodule update --init --recursive # fetch external vendor as submodules
sudo nixos-rebuild switch -I nixos-config=/home/miguel/git/bernadinm/nix-config/hosts/lumina/configuration.nix
```

[configuration.nix](./configuration.nix)

## Next Steps

- [x] Import specific groups of apps via modules
- [x] Source external git repositories using git submodules
- [x] Consider Setting up [Home Manager](https://nixos.wiki/wiki/Home_Manager)
- [ ] Installing instructions for cloud and local use (virtualbox)
- [ ] Installing instructions for Rasberry Pi
- [ ] Migrating from X11 to Wayland (Branch: [wayland-migration](https://github.com/bernadinm/nix-config/tree/wayland-migration))

# Authors

Originally created and maintained by [Miguel Bernadin](https://github.com/bernadinm).

# License

Apache 2 Licensed. See LICENSE for full details.
