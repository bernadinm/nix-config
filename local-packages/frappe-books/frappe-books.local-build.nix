{ stdenv, lib, fetchFromGitHub, yarn, nodejs, mkYarnPackage, src }:

mkYarnPackage rec {
  pname = "frappe-books";
  version = "v0.17.0";

  src = src;

  yarnNix = ./yarn.nix; # path to the generated yarn.nix file

  nativeBuildInputs = [ yarn nodejs ];

  buildPhase = ''
    yarn install
    yarn build --linux
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r . $out/
    ln -s $out/books $out/bin/books
  '';

  meta = with lib; {
    description = "Simple free accounting software for small businesses";
    homepage = "https://books.frappe.io";
    license = licenses.mit;
    maintainers = with maintainers; [ bernadim ];
  };
}

