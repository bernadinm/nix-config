{nodeEnv, fetchurl, fetchgit, nix-gitignore, stdenv, lib, globalBuildInputs ? []}:

let
  sources = {
    "@babel/code-frame-7.16.7" = {
      name = "_at_babel_slash_code-frame";
      packageName = "@babel/code-frame";
      version = "7.16.7";
      src = fetchurl {
        url = "https://registry.npmjs.org/@babel/code-frame/-/code-frame-7.16.7.tgz";
        sha512 = "iAXqUn8IIeBTNd72xsFlgaXHkMBMt6y4HJp1tIaK465CWLT/fG1aqB7ykr95gHHmlBdGbFeWWfyB4NJJ0nmeIg==";
      };
    };
    
