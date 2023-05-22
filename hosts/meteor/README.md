# Raspberry Pi Installation Tutorial: README.md

In this tutorial, we will provide step-by-step instructions on how to install a Raspberry Pi operating system image on an SD card. By following the steps below, you will be able to set up a functional Raspberry Pi system and install necessary development tools like Git.

## Table of Contents

1. [Download the Raspberry Pi Image](#download-the-raspberry-pi-image)
2. [Uncompress the Image File](#uncompress-the-image-file)
3. [Write the Image to the SD Card](#write-the-image-to-the-sd-card)
4. [Insert the SD Card and Boot the Raspberry Pi](#insert-the-sd-card-and-boot-the-raspberry-pi)
5. [Enable SSH (Optional)](#enable-ssh-optional)
6. [Install Git](#install-git)
7. [Download Your NixOS Config, Add Nix Channels, and Run Nix-Build](#download-your-nixos-config-add-nix-channels-and-run-nix-build)

## Download the Raspberry Pi Image

1. Visit the Raspberry Pi [downloads page](https://www.raspberrypi.org/downloads/).
2. Choose the desired operating system, and download the .img.xz file. We recommend using the [Raspberry Pi OS](https://www.raspberrypi.org/software/operating-systems/) for beginners.

## Uncompress the Image File

1. Locate the downloaded .img.xz file in your computer.
2. Use an extraction tool (e.g., 7-Zip, WinRAR, or The Unarchiver) to extract the .img file from the .img.xz archive.
   
   Alternatively, you can use the command line:

   - On macOS or Linux:

     ```sh
     unxz downloaded_image_name.img.xz
     ```

   - On Windows, you can use the [WSL](https://docs.microsoft.com/en-us/windows/wsl/) or install a Linux-like environment such as [Cygwin](https://www.cygwin.com/).

## Write the Image to the SD Card

1. Insert an SD card of at least 8 GB into your computer.
2. Use the `lsblk` command to identify the correct device name for your SD card.

   ```sh
   lsblk
   ```

3. Write the image to the SD card by running the following `dd` command:

   (Replace `/dev/sdX` withthe correct device name and `downloaded_image_name.img` with the name of the extracted image file.)

   ```sh
   sudo dd bs=4M if=downloaded_image_name.img of=/dev/sdX conv=fsync
   ```

   - If you are using Windows, you can use imaging tools like [Rufus](https://rufus.ie/) or [Win32 Disk Imager](https://sourceforge.net/projects/win32diskimager/) to write the image to the SD card.

4. After the process is complete, safely eject the SD card from your computer.

## Insert the SD Card and Boot the Raspberry Pi

1. Insert the prepared SD card into the Raspberry Pi.
2. Connect a keyboard, mouse, and monitor to the Raspberry Pi.
3. Plug in the power supply to boot up the Raspberry Pi.

## Enable SSH (Optional)

1. To enable SSH, open the Raspberry Pi Configuration tool from the main menu.
2. Click on the "Interfaces" tab.
3. Locate the "SSH" option and click on "Enable."
4. Click "OK" to save the changes.

## Install Git

1. Open a terminal window on the Raspberry Pi.
2. Run the followingcommand to update the package list and install Git:

   ```sh
   sudo apt update && sudo apt install -y git
   ```

3. After the installation is complete, you can check the Git version by running:

   ```sh
   git --version
   ```

## Download Your NixOS Config, Add Nix Channels, and Run Nix-Build

1. In the terminal window, clone your NixOS configuration repository:

   ```sh
   git clone https://github.com/yourusername/nixos-config.git
   ```

   (Replace `yourusername` with your GitHub username and `nixos-config` with the name of your configuration repository.)

   Alternatively, you can download the configuration file directly using the `wget` or `curl` command.

2. Add Nix Channels:

   First, install [Nix](https://nixos.org/download.html) by running:

   ```sh
   curl -L https://nixos.org/nix/install | sh
   ```

   Then, open a new terminal window and add Nix Channels by running:

   ```sh
   nix-channel --add https://nixos.org/channels/nixos-unstable nixos
```

3. Build your NixOS configuration:

   ```sh
   nix-build nixos-config/default.nix -I nixpkgs=https://nixos.org/channels/nixos-unstable
   ```

4. After the build is complete, run the following command to install your NixOS configuration:

   ```sh
   sudo env NIXOS_INSTALL_BOOTLOADER=1 nixos-install
   ```

5. Reboot the Raspberry Pi to start using your custom NixOS configuration.

Congratulations! You have successfully installed a Raspberry Pi operating system image, enabled SSH (optional), installed Git, and built and installed your NixOS configuration on the Raspberry Pi. You can now start customizing your Raspberry Pi for your specific needs.

Happy hacking!