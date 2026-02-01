#!/bin/sh

# This script installs the Nix package manager on your system by
# downloading a binary distribution and running its installer script
# (which in turn creates and populates /nix).

{ # Prevent execution if this script was only partially downloaded
oops() {
    echo "$0:" "$@" >&2
    exit 1
}

umask 0022

tmpDir="$(mktemp -d -t nix-binary-tarball-unpack.XXXXXXXXXX || \
          oops "Can't create temporary directory for downloading the Nix binary tarball")"
cleanup() {
    rm -rf "$tmpDir"
}
trap cleanup EXIT INT QUIT TERM

require_util() {
    command -v "$1" > /dev/null 2>&1 ||
        oops "you do not have '$1' installed, which I need to $2"
}

case "$(uname -s).$(uname -m)" in
    Linux.x86_64)
        hash=e5fd4e993bc6c565aa0544eec2db6a977e496896f4133002436b1be1d3e9a8f6
        path=xwn7n573m5m3j4c01dljm0xis1d1l0qq/nix-2.9.2-x86_64-linux.tar.xz
        system=x86_64-linux
        ;;
    Linux.i?86)
        hash=d8d6a8a08a40ad0e22491b57402de2212d055e91d3e03fc5cee0db5064319f72
        path=nz375g80bx5i26gzqfsddiz3b4kk0ghn/nix-2.9.2-i686-linux.tar.xz
        system=i686-linux
        ;;
    Linux.aarch64)
        hash=b1bd23a831357e9041a255fd23a7665f51cbd40229773eb7eb66c5b3d3976986
        path=39wdq7nscrd9jf0dz858s89kwpvqjrv1/nix-2.9.2-aarch64-linux.tar.xz
        system=aarch64-linux
        ;;
    Linux.armv6l_linux)
        hash=29c88bd45341eb05c239ad7a51840e57a28749db3cac3432983076018a0df1c5
        path=zm4i801kcna7530ml0c81girb7m403bi/nix-2.9.2-armv6l-linux.tar.xz
        system=armv6l-linux
        ;;
    Linux.armv7l_linux)
        hash=983299e3d1b6fdadc487624d94e66a4e7b268c4acc77707739ef1bb78783a4a4
        path=bcvm9kkqw4wyycybhsz3ygy0lrja8905/nix-2.9.2-armv7l-linux.tar.xz
        system=armv7l-linux
        ;;
    Darwin.x86_64)
        hash=09bbf6c6f75a6cb5073d7360f29168994ed45ef53ee9348f7a452ec7dc31ddf7
        path=fzalici37aikkxqilzi3qjiq4qr2sllk/nix-2.9.2-x86_64-darwin.tar.xz
        system=x86_64-darwin
        ;;
    Darwin.arm64|Darwin.aarch64)
        hash=aa5405f427a94b26c839cebb2735c6f40ecac970920881942b2ba6d147ce05dc
        path=2clmi87ali1zc3g856pszfin8aw5jigv/nix-2.9.2-aarch64-darwin.tar.xz
        system=aarch64-darwin
        ;;
    *) oops "sorry, there is no binary distribution of Nix for your platform";;
esac

# Use this command-line option to fetch the tarballs using nar-serve or Cachix
if [ "${1:-}" = "--tarball-url-prefix" ]; then
    if [ -z "${2:-}" ]; then
        oops "missing argument for --tarball-url-prefix"
    fi
    url=${2}/${path}
    shift 2
else
    url=https://releases.nixos.org/nix/nix-2.9.2/nix-2.9.2-$system.tar.xz
fi

tarball=$tmpDir/nix-2.9.2-$system.tar.xz

require_util tar "unpack the binary tarball"
if [ "$(uname -s)" != "Darwin" ]; then
    require_util xz "unpack the binary tarball"
fi

if command -v curl > /dev/null 2>&1; then
    fetch() { curl --fail -L "$1" -o "$2"; }
elif command -v wget > /dev/null 2>&1; then
    fetch() { wget "$1" -O "$2"; }
else
    oops "you don't have wget or curl installed, which I need to download the binary tarball"
fi

echo "downloading Nix 2.9.2 binary tarball for $system from '$url' to '$tmpDir'..."
fetch "$url" "$tarball" || oops "failed to download '$url'"

if command -v sha256sum > /dev/null 2>&1; then
    hash2="$(sha256sum -b "$tarball" | cut -c1-64)"
elif command -v shasum > /dev/null 2>&1; then
    hash2="$(shasum -a 256 -b "$tarball" | cut -c1-64)"
elif command -v openssl > /dev/null 2>&1; then
    hash2="$(openssl dgst -r -sha256 "$tarball" | cut -c1-64)"
else
    oops "cannot verify the SHA-256 hash of '$url'; you need one of 'shasum', 'sha256sum', or 'openssl'"
fi

if [ "$hash" != "$hash2" ]; then
    oops "SHA-256 hash mismatch in '$url'; expected $hash, got $hash2"
fi

unpack=$tmpDir/unpack
mkdir -p "$unpack"
tar -xJf "$tarball" -C "$unpack" || oops "failed to unpack '$url'"

script=$(echo "$unpack"/*/install)

[ -e "$script" ] || oops "installation script is missing from the binary tarball!"
export INVOKED_FROM_INSTALL_IN=1
"$script" "$@"

} # End of wrapping
