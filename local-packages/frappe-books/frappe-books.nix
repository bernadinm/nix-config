{ yarn2nix-moretea
, fetchFromGitHub
, lib
}:

yarn2nix-moretea.mkYarnPackage rec {
  pname = "frappe-books";
  version = import ./version.nix;

  src = fetchFromGitHub {
    owner = "frappe";
    repo = "books";
    rev = "v${version}";
    sha256 = import ./source-sha.nix;
  };

  yarnNix = ./yarn.nix; # path to the generated yarn.nix file
  yarnLock = ./yarn.lock; # path to the generated yarn.nix file

 buildPhase = ''
    export HOME=$(mktemp -d)
    export WRITABLE_NODE_MODULES="$(pwd)/tmp"
    # (not needed) export NODE_OPTIONS=--openssl-legacy-provider
    # - mkdir -p "$WRITABLE_NODE_MODULES"

    # react-scripts requires a writable node_modules/.cache, so we have to copy the symlink's contents back
    # into `node_modules/`.
    # See https://github.com/facebook/create-react-app/issues/11263
    # - cd deps/gotify-ui
    node_modules="$(readlink node_modules)"
    rm node_modules
    mkdir -p "$WRITABLE_NODE_MODULES"/.cache
    cp -r $node_modules/* "$WRITABLE_NODE_MODULES"

    # In `node_modules/.bin` are relative symlinks that would be broken after copying them over,
    # so we take care of them here.
    mkdir -p "$WRITABLE_NODE_MODULES"/.bin
    for x in "$node_modules"/.bin/*; do
      ln -sfv "$node_modules"/.bin/"$(readlink "$x")" "$WRITABLE_NODE_MODULES"/.bin/"$(basename "$x")"
    done

    ln -sfv "$WRITABLE_NODE_MODULES" node_modules
    cd ../..

    yarn build

    # - cd deps/gotify-ui
    # - rm -rf node_modules
    # - ln -sf $node_modules node_modules
    # - cd ../..
  '';
  
  meta = with lib; {
    description = "Simple free accounting software for small businesses";
    homepage = "https://books.frappe.io";
    license = licenses.mit;
    maintainers = with maintainers; [ bernadim ];
  };
}

