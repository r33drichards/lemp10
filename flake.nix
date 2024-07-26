{
  description = "basic flake-utils";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.impermanence.url = "github:nix-community/impermanence";

  outputs = { self, nixpkgs, flake-utils, impermanence, ... }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

        in
        {
          nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              impermanence.nixosModules.impermanence
              ./configuration.nix
            ];
          };
          packages = {
            sign = pkgs.writeShellApplication {
              name = "sign";
              runtimeInputs = [ pkgs.openssh pkgs.gawk ];
              text = ''
                # parse flags -n, -f, and -m from command line
                # -f should be optional but -n and -m are required
                # -n is namespace 
                # -m is message (public key)
                # -f is file to sign with, default to ~/.ssh/id_ed25519
                file=~/.ssh/id_ed25519

                parse_args() {
                  while getopts "n:m:f:" opt; do
                    case $opt in
                      n)
                        namespace=$OPTARG
                        ;;
                      m)
                        message=$OPTARG
                        ;;
                      f)
                        file=$OPTARG
                        ;;
                      \?)
                        echo "Invalid option: -$OPTARG" >&2
                        ;;
                    esac
                  done
                }

                parse_args "$@"

                if [ -z "$namespace" ] || [ -z "$message" ]; then
                  echo "Usage: sign -n <namespace> -m <message> [-f <file>]"
                  exit 1
                fi


                dir="$(mktemp -d)"
                # echo "$2" > "$dir"/message
                echo "$message" > "$dir"/message
                ssh-keygen -Y sign -n "$namespace" -f "$file" "$dir"/message  2>&1 | \
                  grep Write | \
                  awk '{print $4}' | \
                  xargs cat
                rm -rf "$dir"
              '';
            };
          };

        })
    );
}
