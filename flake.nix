{
  inputs = {
    impermanence.url = "github:nix-community/impermanence";
  };
  outputs = { self, nixpkgs, impermanence }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
    in
    {
      # replace 'joes-desktop' with your hostname here.
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          impermanence.nixosModules.impermanence
          ./configuration.nix
        ];
      };

      packages.aarch64-darwin = {
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
            # ssh-keygen -Y sign -n "$1" -f ~/.ssh/id_ed25519  "$dir"/message  2>&1 | \
            #   grep Write | \
            #   awk '{print $4}' | \
            #   xargs cat
            ssh-keygen -Y sign -n "$namespace" -f "$file" "$dir"/message  2>&1 | \
              grep Write | \
              awk '{print $4}' | \
              xargs cat
          '';
        };
      };
    };
}

