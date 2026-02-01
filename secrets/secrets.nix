let
  miguel = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqgRfblq8qT8u60vcfUEWo5aAy0GsnM4onnzDYRejNj";
  users = [ miguel ];

in
{
  "secret.age".publicKeys = [ miguel ];
}