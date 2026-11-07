#!/bin/sh
# Public international installer. Keepalive is owned by the independent console guard.
# Requires the package key and the current device's private runtime credentials.
set -eu
set +x
umask 077
[ "$#" -ge 3 ] && [ "$#" -le 4 ] || { printf '%s\n' 'Usage: deploy.sh INSTALL_DIRECTORY PACKAGE_KEY_FILE RUNTIME_CREDENTIAL_FILE [PROGRAM_NAME]' >&2; exit 2; }
install=$1
key_file=$2
credentials=$3
program_name=${4:-datadebug}
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
    curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' --connect-timeout 8 --max-redirs 3 --speed-time 30 --speed-limit 1024 --max-filesize "$length" --continue-at - "https://raw.githubusercontent.com/sandrauzbmo/info_get/6a817057389bd8d08baeeb476a4fd6dca25bf909/international/$filename" -o "$partial" || code=$?
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
1.key a7ed1a97d861d30eb979bacf9b28dddf3d07884b1d3b66f2134d3444e09cc976 320
README.md f2e4b03a007e8ffabd158c69c56378d6d6ceba4ee309431c4dc21ebbee8f6619 2672
data 24c9f910d4edddc80452742f17f483bce057cee3c2a402a921761e501c8809a5 8149035
key 1e50c1060a7601561951fa30c6958d7a5f09b9326db6da237c896698f61a75b5 7200928
release.json 52c0643dda258c059e012c1f102a4e64d503fbb173bc8d7a872f84a466e79d92 1163
start f8f214062d8d846e8d7a28da2fadaecf75e22cd8981a7027855b18496c8aa929 7086240
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
nohup "$install/program/start" --program-name "$program_name" --key-file "$install/runtime/.launch.key" --cookie-file "$install/runtime/runtime-credentials.json" --work-dir "$install/runtime" </dev/null >start.log 2>&1 &
pid=$!
printf '%s\n' "$pid" >start.pid
printf 'Submitted start; PID=%s; log=%s/runtime/start.log\n' "$pid" "$install"
