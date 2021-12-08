# NixOS configuration.nix

## Usage

When installing NixOS, you want to use a configuration.nix file to configure your entire OS. This includes setting up users and installing particular system level programs and/or user specific programs. Here is my configuration file that I use to configure my personal NixOS environment. Starting out on nix? Check out the cheatsheet [vector wiki](https://nixos.wiki/index.php?title=Cheatsheet&useskin=vector) page.

### How to install Computers

Since this is a custom nix-config, you can configure your computers by running the following command below:

```bash
git submodule update --init --recursive # fetch external vendor as submodules
sudo nixos-rebuild switch -I nixos-config=/home/miguel/git/bernadinm/nix-config/computers/lumina/configuration.nix
```

[configuration.nix](./configuration.nix)

## Next Steps
- [ ] Setting up [Home Manager](https://nixos.wiki/wiki/Home_Manager)
- [ ] Installing local apps using [Home Manager](https://nixos.wiki/wiki/Home_Manager)
- [ ] Installing instructions for cloud and local use (virtualbox)
- [ ] _and more_

# Authors

Originally created and maintained by [Miguel Bernadin](https://github.com/bernadinm).


# License

Apache 2 Licensed. See LICENSE for full details.
