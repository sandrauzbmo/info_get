International deployment

`deploy.sh` downloads the signed 2.3.0-ai-sg1 artifacts from pinned commit
31c0505c88fdcc95cf55e06e2d0d1238a00a9ad2 and checks every file's SHA256.

Usage:

```sh
sh deploy.sh /root/agentssh-ai-sg /root/package-key.txt /root/.agentssh-workbuddy-credentials.json
```

The two input files must already exist and be readable only by their owner.
The runtime document must belong to this device and its international Cookie
account, as verified and delivered by the authorized console. This command
does not register a device, obtain credentials, create a cloud task, or replace
an existing installation. It starts through `start`; the decrypted miner is
`run`, with direct TLS mining to the Singapore endpoint.

The console's automatic deployment additionally checks current account and
device ownership and starts temporary protection before downloading. The
native program ends only its matching temporary guard after its own verified
handshake and two fresh increasing heartbeats.
