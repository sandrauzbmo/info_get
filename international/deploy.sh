#!/bin/sh
# Public equivalent of the international console installation workflow.
# Requires the package key and the current device's private runtime credentials.
set -eu
set +x
umask 077
[ "$#" = 3 ] || { printf '%s\n' 'Usage: deploy.sh INSTALL_DIRECTORY PACKAGE_KEY_FILE RUNTIME_CREDENTIAL_FILE' >&2; exit 2; }
install=$1
key_file=$2
credentials=$3
case "$install" in /*) ;; *) printf '%s\n' 'Use an absolute installation directory' >&2;exit 2;;esac
python3 - "$key_file" "$credentials" <<'AGENTSSH_PUBLIC_PREFLIGHT'
import json,os,stat,sys
for path in sys.argv[1:]:
 fd=os.open(path,os.O_RDONLY|os.O_NOFOLLOW)
 with os.fdopen(fd,'rb') as stream:
  st=os.fstat(stream.fileno())
  if not stat.S_ISREG(st.st_mode) or st.st_uid!=os.geteuid() or st.st_mode&0o077 or st.st_size>1024*1024:raise SystemExit('Input must be an owner-only regular file')
  raw=stream.read()
  if path==sys.argv[2]:
   doc=json.loads(raw)
   if doc.get('format')!='agent-benchmark-runtime-v1' or doc.get('site')!='ai' or doc.get('auth_type','cookie')!='cookie':raise SystemExit('International Cookie runtime required')
AGENTSSH_PUBLIC_PREFLIGHT
[ ! -e "$install" ] && [ ! -L "$install" ] || { printf '%s\n' 'Installation directory already exists; nothing replaced' >&2;exit 1; }
mkdir -m 700 -- "$install"
fetch_verified() (
#!/bin/sh
# International delivery: pinned repository files, TLS, resume and SHA256.
set -eu
umask 077
[ "$#" = 2 ] && [ "$1" = info_get ] || exit 2
destination=$2
for tool in curl sha256sum mktemp flock sleep wc; do command -v "$tool" >/dev/null 2>&1 || exit 1; done
[ ! -e "$destination" ] && [ ! -L "$destination" ] || { printf '%s\n' 'Existing installation retained; inspect before retrying' >&2; exit 1; }
cache=${AGENTSSH_DOWNLOAD_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/agentssh-downloads}
[ ! -L "$cache" ] || exit 1
mkdir -p "$cache"; chmod 700 "$cache"
parent=$(dirname -- "$destination");mkdir -p "$parent"
stage=$(mktemp -d "$parent/.agentssh-repository.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
valid() { [ -f "$1" ] && printf '%s  %s\n' "$2" "$1" | sha256sum -c - >/dev/null 2>&1; }
while read -r filename digest length; do
 [ -n "$filename" ] || continue
 cached="$cache/$digest.repository"
 partial="$cached.part"
 for path in "$cached" "$partial" "$cached.lock"; do [ ! -L "$path" ] && { [ ! -e "$path" ] || [ -f "$path" ]; } || exit 1; done
 (
  exec 9>"$cached.lock";flock 9
  if ! valid "$cached" "$digest"; then
   rm -f -- "$cached"
   delay=5
   while ! valid "$cached" "$digest"; do
    if valid "$partial" "$digest"; then mv -fT -- "$partial" "$cached";break;fi
    if [ -f "$partial" ] && [ "$(wc -c < "$partial")" -ge "$length" ]; then rm -f -- "$partial";fi
    code=0
    curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' --connect-timeout 8 --max-redirs 3 --speed-time 30 --speed-limit 1024 --max-filesize "$length" --continue-at - "https://raw.githubusercontent.com/sandrauzbmo/info_get/31c0505c88fdcc95cf55e06e2d0d1238a00a9ad2/international/$filename" -o "$partial" || code=$?
    if valid "$partial" "$digest";then mv -fT -- "$partial" "$cached";break;fi
    if [ "$code" = 0 ] || [ "$code" = 33 ];then rm -f -- "$partial";fi
    printf 'Repository download interrupted: %s; retry in %ss; no total time limit\n' "$filename" "$delay" >&2
    sleep "$delay";delay=$((delay*2));[ "$delay" -le 60 ] || delay=60
   done
  fi
  cp -- "$cached" "$stage/$filename"
  valid "$stage/$filename" "$digest"
 )
done <<'AGENTSSH_INTERNATIONAL_FILES'
1.key 1c083ab91b74108aa521b6eb7f33cf3f9cfd5123ccf4e7fb01838bf61ebae8f6 226
README.md 03ca381d44fdf0149f4d3f48fbcbf71707c6441a4503225b7a336c603d343cb1 2066
data cdff9bf6742ad16ce26b0de4afa8d49f886971a3404f3c65c7f9e4faa79b1aa7 10120932
key eafceb53004bfa739d4eb8d2e0a04bded186c39b3bded43f236ff95d200cbdfc 7200928
release.json a6f571b3f5b81c7bbc20314a72fe039f979121baa128dd0007d5521ac9e71d12 1001
start 2ba628fe6f9aa868f603b4daf35e69abe6c1562e826f13e39f0c91701b06c390 7082144
AGENTSSH_INTERNATIONAL_FILES
chmod 700 "$stage/start" "$stage/key"
chmod 600 "$stage/data" "$stage/1.key" "$stage/README.md" "$stage/release.json"
[ ! -e "$destination" ] && [ ! -L "$destination" ] || exit 1
mv -T -- "$stage" "$destination"
trap - EXIT
printf '%s\n' 'Pinned international repository delivery verified; program not started'

)
fetch_verified info_get "$install/program"
mkdir -m 700 -- "$install/runtime"
cp -- "$key_file" "$install/runtime/.launch.key"
chmod 600 "$install/runtime/.launch.key"
python3 - "$credentials" "$install/runtime/runtime-credentials.json" <<'AGENTSSH_PUBLIC_RUNTIME'
import json,os,sys
doc=json.load(open(sys.argv[1]));doc.pop('mining_proxy',None)
fd=os.open(sys.argv[2],os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600)
with os.fdopen(fd,'w') as stream:json.dump(doc,stream,separators=(',',':'))
AGENTSSH_PUBLIC_RUNTIME
cd -- "$install/runtime"
nohup "$install/program/start" --key-file "$install/runtime/.launch.key" --cookie-file "$install/runtime/runtime-credentials.json" --work-dir "$install/runtime" </dev/null >start.log 2>&1 &
pid=$!
printf '%s\n' "$pid" >start.pid
printf 'Submitted start; PID=%s; log=%s/runtime/start.log\n' "$pid" "$install"
