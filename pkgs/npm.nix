{ pkgs, ... }:

let
  nodejs-14 = pkgs.nodejs-14_x;
in
{
  # ...

  environment.systemPackages = with pkgs; [
    git
    (nodejs-14.override { npmbin = true; })
  ];

  # ...

  ai-cli = pkgs.buildNodePackage {
    name = "ai-cli";
    src = fetchgit
      {
        url = "https://github.com/abhagsain/ai-cli.git";
        rev = "14d9sw5nlyldvbq6clryzd53w98ism1a4azg8n11vpirwmnnmx2h";
        ref = "refs/heads/v1.2.3";
      };
    # Or, use the branch:
    # ref = "refs/heads/main";
    buildInputs = with pkgs;
      [
        git
        (nodejs-14.override {
          npmbin = true;
        })
        pkgs.typescript
      ];
    buildPhase = ''
      npm install && npm run build
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp -r ${src}/dist/* $out/
      ln -s ${nodejs-14}/bin/node $out/bin/node
    '';
  };

  # ...

  environment.etc."profile".text = ''
    export PATH=$PATH:${ai-cli}/bin
  '';
}
