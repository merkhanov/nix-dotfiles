{ self, pkgs, ... }:
{
  # System-level packages (the user's tools live in home-manager instead).
  environment.systemPackages = [ pkgs.vim ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Record the git revision so `darwin-version` reports it.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Backwards-compat baseline — read the changelog before changing.
  system.stateVersion = 6;

  # The platform this configuration is used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # The account home-manager manages, and the primary user for user-scoped
  # macOS defaults.
  system.primaryUser = "yernar33";
  users.users.yernar33 = {
    name = "yernar33";
    home = "/Users/yernar33";
  };
}
