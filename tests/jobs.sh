#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd -P)"
cli="$repo/file-sync.sh"
tmp="$(mktemp -d)"
export FILE_SYNC_CONFIG_HOME="$tmp/config" FILE_SYNC_STATE_HOME="$tmp/state"
finish() {
    "$cli" stop copy >/dev/null 2>&1 || :
    "$cli" stop note >/dev/null 2>&1 || :
    rm -rf -- "$tmp"
}
trap finish EXIT
mkdir -p "$tmp/config/plugins" "$tmp/config/jobs"
doc="$tmp/source with spaces.bin"
printf '\0before\n' > "$doc"
dest="$tmp/output"
copy="$dest$(realpath "$doc")"
jq -n --arg command "$repo/plugins/local-mirror/plugin.sh" '{command:$command,protocol:"sync"}' > "$tmp/config/plugins/local-mirror.json"
job() {
    jq -n --arg file "$doc" --arg dest "$dest" --arg mode "$1" '{plugin:"local-mirror",mode:$mode,intervalSeconds:1,settings:{files:[$file],destination:$dest,writeBack:true}}' > "$tmp/config/jobs/copy.json"
}
job manual
"$cli" run copy
cmp "$doc" "$copy"
"$cli" job-status copy | jq -e '.running == false'
printf 'manual' > "$copy"
sleep 1
[ "$(cat "$doc" | tr -d '\0')" = before ]
"$cli" run copy
cmp "$copy" "$doc"
job watch
"$cli" run copy
"$cli" job-status copy | jq -e .running
if "$cli" run copy; then exit 1; fi
printf 'watched' > "$doc"
for i in {1..50}; do cmp -s "$doc" "$copy" && break; sleep .1; done
cmp "$doc" "$copy"
"$cli" stop copy
"$cli" job-status copy | jq -e '.running == false'
job watch
"$cli" run copy
job manual
for i in {1..50}; do "$cli" job-status copy | jq -e '.running == false' >/dev/null && break; sleep .1; done
"$cli" job-status copy | jq -e '.running == false'
printf 'different' > "$copy"
printf 'local edit' > "$doc"
job manual
if "$cli" run copy; then exit 1; fi
[ "$(cat "$copy")" = different ] && [ "$(cat "$doc")" = 'local edit' ]

cat > "$tmp/backend" <<'PLUGIN'
#!/bin/bash
set -eu
printf x >> "$REMOTE.calls"
r=$(cat)
case "$(jq -r .operation <<< "$r")" in
resolve) jq -c '{version,result:{url}}' <<< "$r";;
read) jq -nc --rawfile body "$REMOTE" '{version:1,result:{title:"Note",body:$body}}';;
*) exit 1;;
esac
PLUGIN
chmod +x "$tmp/backend"
export REMOTE="$tmp/remote"
printf 'first' > "$REMOTE"
md="$tmp/doc.md"
printf '# Note\nfirst' > "$md"
jq -n --arg command "$tmp/backend" '{command:$command}' > "$tmp/config/plugins/example.json"
jq -n --arg f "$md" '{plugin:"example",mode:"watch",intervalSeconds:1,settings:{file:$f,url:"https://example.test/doc",direction:"pull"}}' > "$tmp/config/jobs/note.json"
manifest="$tmp/config/plugins/example.json"
jobfile="$tmp/config/jobs/note.json"
jq '. + {allowedModes:["manual"]}' "$manifest" > "$tmp/manual-plugin"
cp "$tmp/manual-plugin" "$manifest"
for direction in push pull; do
    jq --arg direction "$direction" '.settings.direction=$direction | .allowedModes=["watch"] | .settings.allowedModes=["watch"]' "$jobfile" > "$tmp/job"
    cp "$tmp/job" "$jobfile"
    if "$cli" run note > "$tmp/result" 2>&1; then exit 1; fi
    grep -q 'does not allow job mode: watch' "$tmp/result"
    [ ! -e "$REMOTE.calls" ] && [ ! -e "$tmp/state/jobs/note/worker.log" ] || exit 1
done
jq '.mode="manual"' "$jobfile" > "$tmp/job"
cp "$tmp/job" "$jobfile"
"$cli" run note
[ -s "$REMOTE.calls" ]
jq '.mode="watch"' "$jobfile" > "$tmp/job"
cp "$tmp/job" "$jobfile"
jq 'del(.allowedModes)' "$manifest" > "$tmp/plugin"
cp "$tmp/plugin" "$manifest"
"$cli" run note
printf second > "$REMOTE"
for i in {1..50}; do grep -q second "$md" && break; sleep .1; done
grep -q second "$md"
"$cli" stop note
printf 'local edit' >> "$md"
printf third > "$REMOTE"
if "$cli" run note; then exit 1; fi
grep -q 'local edit' "$md"
