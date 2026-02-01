{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # other packages...
    # frappe-books
  ];
}
