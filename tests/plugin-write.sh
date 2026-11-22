#!/bin/bash
set -euo pipefail

cli="$(cd "$(dirname "$0")/.." && pwd)/file-sync.sh"
testdir=$(/usr/bin/mktemp -d)
trap '/bin/rm -rf -- "$testdir"' EXIT
export FILE_SYNC_CONFIG_HOME="$testdir/config" FILE_SYNC_STATE_HOME="$testdir/state" REMOTE="$testdir/remote.json"
mkdir -p "$FILE_SYNC_CONFIG_HOME/plugins"
doc="$testdir/note.md"
url=https://example.test/note
cat > "$testdir/plugin" <<'PLUGIN'
#!/bin/bash
set -euo pipefail
request=$(cat)
case "$(jq -r .operation <<< "$request")" in
    resolve) jq -c '{version,result:{url}}' <<< "$request";;
    read) jq -c '{version:1,result:.}' "$REMOTE";;
    write)
        jq -es '.[0].expected == .[1]' <(printf '%s' "$request") "$REMOTE" >/dev/null
        printf x >> "$REMOTE.writes"
        if [ -z "${SKIP_SAVE:-}" ]; then jq -c .document <<< "$request" > "$REMOTE"; fi
        echo '{"version":1,"result":{"written":true}}';;
    *) exit 1;;
esac
PLUGIN
chmod +x "$testdir/plugin"
manifest="$FILE_SYNC_CONFIG_HOME/plugins/example.json"
jq -n --arg command "$testdir/plugin" '{command:$command}' > "$manifest"
printf '{"title":"One","body":"before"}\n' > "$REMOTE"
printf '# One\nbefore\n' > "$doc"
"$cli" link "$doc" "$url" --plugin example >/dev/null
"$cli" push "$doc" >/dev/null
printf '# Two\nafter\n' > "$doc"

rejected() {
    local rc=0
    "$@" <<< y > "$testdir/log" 2>&1 || rc=$?
    if [ "$rc" != 1 ]; then cat "$testdir/log" >&2; exit 1; fi
}

rejected "$cli" push "$doc"
test ! -e "$REMOTE.writes"
jq -n --arg command "$testdir/plugin" '{command:$command,writable:true}' > "$manifest"
SKIP_SAVE=1 rejected "$cli" push "$doc"
test "$(cat "$REMOTE.writes")" = x
test "$("$cli" status "$doc")" = local-changed
printf '{"title":"Other","body":"elsewhere"}\n' > "$REMOTE"
rejected "$cli" push "$doc"
test "$(cat "$REMOTE.writes")" = x
if "$cli" push "$doc" --overwrite <<< n >/dev/null 2>&1; then exit 1; fi
test "$(cat "$REMOTE.writes")" = x
"$cli" push "$doc" --overwrite <<< y > "$testdir/log" 2>&1
test "$(cat "$REMOTE.writes")" = xx
test "$("$cli" status "$doc")" = equal
