NixOS Image build scripts
=========================

[NixOS](http://nixos.org) is a linux distribution with a purely functional
package manager. 


Building the images
-------------------

First install [packer](http://packer.io) and [virtualbox](https://www.virtualbox.org/)

Then:

```bash
packer build template.json
```
