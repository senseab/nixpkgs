{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  buildPackages,
  coreutils,
  nix-update-script,
  nixosTests,
}:

buildGoModule rec {
  pname = "sing-box";
  version = "1.10.5";

  src = fetchFromGitHub {
    owner = "SagerNet";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-gVbOJsGY8s2fVugd7Tha1dAhS9rxZbN6m3FVza0WUdc=";
  };

  vendorHash = "sha256-b0SPUVGL1ESeseWn27xQ2YFFIxJeBAfukZG6lynAIik=";

  tags = [
    "with_quic"
    "with_dhcp"
    "with_wireguard"
    "with_ech"
    "with_utls"
    "with_reality_server"
    "with_acme"
    "with_clash_api"
    "with_gvisor"
  ];

  subPackages = [
    "cmd/sing-box"
  ];

  nativeBuildInputs = [ installShellFiles ];

  ldflags = [
    "-X=github.com/sagernet/sing-box/constant.Version=${version}"
  ];

  postInstall =
    let
      emulator = stdenv.hostPlatform.emulator buildPackages;
    in
    ''
      installShellCompletion --cmd sing-box \
        --bash <(${emulator} $out/bin/sing-box completion bash) \
        --fish <(${emulator} $out/bin/sing-box completion fish) \
        --zsh  <(${emulator} $out/bin/sing-box completion zsh )

      substituteInPlace release/config/sing-box{,@}.service \
        --replace-fail "/usr/bin/sing-box" "$out/bin/sing-box" \
        --replace-fail "/bin/kill" "${coreutils}/bin/kill"
      install -Dm444 -t "$out/lib/systemd/system/" release/config/sing-box{,@}.service
    '';

  passthru = {
    updateScript = nix-update-script { };
    tests = { inherit (nixosTests) sing-box; };
  };

  meta = with lib; {
    homepage = "https://sing-box.sagernet.org";
    description = "Universal proxy platform";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ nickcao ];
    mainProgram = "sing-box";
  };
}
