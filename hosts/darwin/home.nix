{ ... }:
{
  # Shared home-manager configuration (programs, packages, env).
  imports = [ ../home.nix ];

  # Host/account-specific identity. Changing these two lines (plus the system
  # config) is all a future account rename needs — everything else derives from
  # config.home.homeDirectory.
  home.username = "yernar33";
  home.homeDirectory = "/Users/yernar33";

  # Matches the home-manager release; read the changelog before bumping.
  home.stateVersion = "26.05";
}
