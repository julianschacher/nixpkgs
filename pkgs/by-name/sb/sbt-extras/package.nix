{
  lib,
  stdenv,
  fetchFromGitHub,
  which,
  curl,
  makeWrapper,
  jdk,
  writeScript,
  common-updater-scripts,
  cacert,
  git,
  nixfmt-classic,
  nix,
  jq,
  coreutils,
  gnused,
}:

stdenv.mkDerivation rec {
  pname = "sbt-extras";
  rev = "408f74841b90169a7f674955389212e2d02f7f4d";
  version = "2024-09-28";

  src = fetchFromGitHub {
    owner = "paulp";
    repo = "sbt-extras";
    inherit rev;
    sha256 = "2iXNs2Ks54Gj6T6PR5AtWrmR9uUxgFScAfek2v+qdTo=";
  };

  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    substituteInPlace bin/sbt --replace 'declare java_cmd="java"' 'declare java_cmd="${jdk}/bin/java"'

    install bin/sbt $out/bin

    wrapProgram $out/bin/sbt --prefix PATH : ${
      lib.makeBinPath [
        which
        curl
      ]
    }

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/sbt -h >/dev/null
  '';

  passthru.updateScript = writeScript "update.sh" ''
     #!${stdenv.shell}
     set -xo errexit
     PATH=${
       lib.makeBinPath [
         common-updater-scripts
         curl
         cacert
         git
         nixfmt-classic
         nix
         jq
         coreutils
         gnused
       ]
     }
    oldVersion="$(nix-instantiate --eval -E "with import ./. {}; lib.getVersion ${pname}" | tr -d '"')"
     latestSha="$(curl -L -s https://api.github.com/repos/paulp/sbt-extras/commits\?sha\=master\&since\=$oldVersion | jq -r '.[0].sha')"
    if [ ! "null" = "$latestSha" ]; then
       nixpkgs="$(git rev-parse --show-toplevel)"
       default_nix="$nixpkgs/pkgs/development/tools/build-managers/sbt-extras/default.nix"
       latestDate="$(curl -L -s https://api.github.com/repos/paulp/sbt-extras/commits/$latestSha | jq '.commit.committer.date' | sed 's|"\(.*\)T.*|\1|g')"
       update-source-version ${pname} "$latestSha" --version-key=rev
       update-source-version ${pname} "$latestDate" --ignore-same-hash
       nixfmt "$default_nix"
     else
       echo "${pname} is already up-to-date"
     fi
  '';

  meta = {
    description = "A more featureful runner for sbt, the simple/scala/standard build tool";
    homepage = "https://github.com/paulp/sbt-extras";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      nequissimus
      puffnfresh
    ];
    mainProgram = "sbt";
    platforms = lib.platforms.unix;
  };
}
