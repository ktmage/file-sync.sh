#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.6.0-alpha
# error(message: Text, code: Int)
error__0_v0() {
    local message_3="${1}"
    local code_4="${2}"
    printf '%s
' "${message_3}" >&2
    __status=$?
    exit "${code_4}"
}

# env_or(name: Text, fallback: Text)
env_or__1_v0() {
    local name_14="${1}"
    local fallback_15="${2}"
    local command_0
    command_0="$(/usr/bin/printenv "${name_14}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_env_or1_v0="${fallback_15}"
        return 0
    fi
    local value_16="${command_0}"
    if [ "$([ "_${value_16}" != "_" ]; echo $?)" != 0 ]; then
        ret_env_or1_v0="${fallback_15}"
        return 0
    fi
    ret_env_or1_v0="${value_16}"
    return 0
}

# real_path(path: Text)
real_path__2_v0() {
    local path_23="${1}"
    local command_1
    command_1="$(resolved=$(/bin/realpath -- "${path_23}" && printf '.') || exit 1
        newline=$'\n'
        resolved="${resolved%"$newline."}"
        if [[ "$resolved" == *"$newline" ]]; then exit 1; fi
        printf '%s' "$resolved")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_real_path2_v0=''
        return "${__status}"
    fi
    local output_24="${command_1}"
    ret_real_path2_v0="${output_24}"
    return 0
}

# file_exists(path: Text)
file_exists__3_v0() {
    local path_1107="${1}"
    test -e "${path_1107}" || test -L "${path_1107}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_exists3_v0=0
        return 0
    fi
    ret_file_exists3_v0=1
    return 0
}

# ensure_directory(path: Text)
ensure_directory__4_v0() {
    local path_1104="${1}"
    /bin/mkdir -p -- "${path_1104}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not create directory: ${path_1104}" 1
    fi
}

# lock_file(path: Text)
lock_file__5_v0() {
    local path_1157="${1}"
    # lockf on an inherited descriptor keeps the lock until this shell exits.
    test ! -L "${path_1157}" && exec 9>>"${path_1157}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not open lock: ${path_1157}" 1
    fi
    /usr/bin/lockf -t 15 9
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not acquire lock: ${path_1157}" 1
    fi
}

# write_file(path: Text, data: Text)
write_file__6_v0() {
    local path_1205="${1}"
    local data_1206="${2}"
    local command_2
    command_2="$(/usr/bin/mktemp "${path_1205}.XXXXXX")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not stage: ${path_1205}" 1
    fi
    local temp_1207="${command_2}"
    printf '%s
' "${data_1206}" > "${temp_1207}" && /bin/mv -f -h -- "${temp_1207}" "${path_1205}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        /bin/rm -f -- "${temp_1207}"
        __status=$?
        error__0_v0 "Could not save: ${path_1205}" 1
    fi
}

# confirm(message: Text)
confirm__7_v0() {
    local message_1208="${1}"
    printf '%s [y/N] ' "${message_1208}" >&2
    __status=$?
    IFS= read -r answer && case "$answer" in y|Y|yes|YES) true;; *) false;; esac
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Cancelled" 1
    fi
}

# lock_sync_writes(state: Text)
lock_sync_writes__8_v0() {
    local state_1196="${1}"
    ensure_directory__4_v0 "${state_1196}"
    local path_1197="${state_1196}/.write.lock"
    test ! -L "${path_1197}" && exec 7>>"${path_1197}" && /usr/bin/lockf -t 15 7
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not acquire the file write lock: ${path_1197}" 1
    fi
}

# stored_targets(path: Text)
stored_targets__18_v0() {
    local path_1161="${1}"
    file_exists__3_v0 "${path_1161}"
    local ret_file_exists3_v0__4_12="${ret_file_exists3_v0}"
    if [ "$(( ! ret_file_exists3_v0__4_12 ))" != 0 ]; then
        ret_stored_targets18_v0="{\"version\":1,\"targets\":[]}"
        return 0
    fi
    test -f "${path_1161}" && test ! -L "${path_1161}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid targets file: ${path_1161}" 1
    fi
    local command_3
    command_3="$(/usr/bin/jq -ces '
        if length == 1 and (.[0] | .version == 1 and (.targets | type == "array" and all(.[];
          type == "object" and (.path | type == "string" and startswith("/")) and
          (.plugin | type == "string" and test("^[a-z0-9][a-z0-9-]*\\z")) and (.url | type == "string" and startswith("https://"))
        ) and (map(.path) | length == (unique | length)) and (map(.url) | length == (unique | length))))
        then .[0] else error("Invalid file-sync registry") end
    ' -- "${path_1161}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid targets file: ${path_1161}" 1
    fi
    local targets_1162="${command_3}"
    ret_stored_targets18_v0="${targets_1162}"
    return 0
}

# canonical_file(file: Text)
canonical_file__19_v0() {
    local file_1140="${1}"
    real_path__2_v0 "${file_1140}">/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "File not found: ${file_1140}" 1
    fi
    local path_1141="${ret_real_path2_v0}"
    test -f "${path_1141}" && [[ "${path_1141}" == *.[mM][dD] ]]
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Expected a regular Markdown file: ${file_1140}" 1
    fi
    ret_canonical_file19_v0="${path_1141}"
    return 0
}

# registered_path(input: Text)
registered_path__20_v0() {
    local input_1251="${1}"
    real_path__2_v0 "${input_1251}">/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        [[ "${input_1251}" == /* ]]
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Use the registered absolute path for a missing file" 2
        fi
        ret_registered_path20_v0="${input_1251}"
        return 0
    fi
    local path_1252="${ret_real_path2_v0}"
    ret_registered_path20_v0="${path_1252}"
    return 0
}

# find_target(file: Text, path: Text)
find_target__21_v0() {
    local file_1159="${1}"
    local path_1160="${2}"
    stored_targets__18_v0 "${file_1159}"
    local targets_1163="${ret_stored_targets18_v0}"
    local command_4
    command_4="$(/usr/bin/jq -cer --arg path "${path_1160}" '.targets[] | select(.path == $path)' <<< "${targets_1163}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "File has no registered sync target: ${path_1160}" 1
    fi
    local target_1164="${command_4}"
    ret_find_target21_v0="${target_1164}"
    return 0
}

# load_plugin(config: Text, id: Text)
load_plugin__22_v0() {
    local config_1114="${1}"
    local id_1115="${2}"
    LC_ALL=C; [[ "${id_1115}" =~ ^[a-z0-9][a-z0-9-]*$ ]]
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid plugin ID: ${id_1115}" 2
    fi
    local path_1116="${config_1114}/plugins/${id_1115}.json"
    test -f "${path_1116}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin configuration not found: ${path_1116}" 1
    fi
    local command_5
    command_5="$(/usr/bin/jq -ces '
        select(length == 1) | .[0] | select(type == "object"
          and (.command | type == "string" and (startswith("/") or startswith("~/"))
          and (test("[[:cntrl:]]") | not))
          and (if has("writable") then (.writable | type == "boolean") else true end)
          and ((.protocol // "markdown") | . == "markdown" or . == "sync")
          and (if has("allowedModes") then (.allowedModes | type == "array" and length > 0
            and all(.[]; . == "manual" or . == "watch")) else true end)
          and (if has("backgroundWrite") then (.backgroundWrite | type == "boolean") else true end)
          and (if has("settings") then (.settings | type == "object") else true end))
    ' -- "${path_1116}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid plugin configuration: ${path_1116}" 1
    fi
    local manifest_1117="${command_5}"
    local command_6
    command_6="$(/usr/bin/jq -er '.command' <<< "${manifest_1117}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Missing plugin command: ${id_1115}" 1
    fi
    local command_1118="${command_6}"
    local tool_1119="${command_1118}"
    [[ "${command_1118}" == "~/"* ]]
    __status=$?
    if [ "${__status}" = 0 ]; then
        local command_7
        command_7="$(value="${command_1118}"; printf '%s/%s' "$HOME" "${value:2}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid plugin command: ${id_1115}" 1
        fi
        tool_1119="${command_7}"
    fi
    test -f "${tool_1119}" && test -x "${tool_1119}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin command is not executable: ${tool_1119}" 1
    fi
    local command_8
    command_8="$(/usr/bin/jq -ce --arg tool "${tool_1119}" '{command:$tool,protocol:(.protocol // "markdown"),allowedModes:(.allowedModes // ["manual","watch"]),backgroundWrite:(.backgroundWrite // false),settings:(.settings // {}),writable:(.writable // false)}' <<< "${manifest_1117}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read plugin settings: ${id_1115}" 1
    fi
    local plugin_1120="${command_8}"
    ret_load_plugin22_v0="${plugin_1120}"
    return 0
}

# plugin_call(plugin: Text, operation: Text, url: Text, payload: Text)
plugin_call__23_v0() {
    local plugin_1130="${1}"
    local operation_1131="${2}"
    local url_1132="${3}"
    local payload_1133="${4}"
    local command_9
    command_9="$(/usr/bin/jq -er '.command' <<< "${plugin_1130}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Missing plugin command" 1
    fi
    local tool_1134="${command_9}"
    local command_10
    command_10="$(printf '%s
' "${plugin_1130}" "${payload_1133}" | /usr/bin/jq -ces --arg op "${operation_1131}" --arg url "${url_1132}" '
        .[1] + (.[0] | {version:1, operation:$op, settings}) + (if $op == "sync" then {} else {url:$url} end)
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not build plugin request" 1
    fi
    local request_1135="${command_10}"
    local command_11
    command_11="$(printf '%s
' "${request_1135}" | "${tool_1134}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin failed: ${operation_1131}" 1
    fi
    local response_1136="${command_11}"
    local command_12
    command_12="$(printf '%s' "${response_1136}" | /usr/bin/jq -ces '
        select(length == 1) | .[0] | select(.version == 1 and (.result | type == "object")) | .result
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid plugin response: ${operation_1131}" 1
    fi
    local result_1137="${command_12}"
    ret_plugin_call23_v0="${result_1137}"
    return 0
}

# link_target(config: Text, id: Text, input: Text, url: Text)
link_target__24_v0() {
    local config_1269="${1}"
    local id_1270="${2}"
    local input_1271="${3}"
    local url_1272="${4}"
    canonical_file__19_v0 "${input_1271}"
    local file_1273="${ret_canonical_file19_v0}"
    load_plugin__22_v0 "${config_1269}" "${id_1270}"
    local plugin_1274="${ret_load_plugin22_v0}"
    local command_13
    command_13="$(/usr/bin/jq -ner --arg url "${url_1272}" '
        $url | select(test("^https://[^/[:space:][:cntrl:]]+[^[:space:][:cntrl:]]*\\z"))
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Expected a HTTPS URL: ${url_1272}" 2
    fi
    local source_1275="${command_13}"
    plugin_call__23_v0 "${plugin_1274}" "resolve" "${source_1275}" "{}"
    local resolved_1276="${ret_plugin_call23_v0}"
    local command_14
    command_14="$(/usr/bin/jq -ce --arg path "${file_1273}" --arg plugin "${id_1270}" '
        select(.url | type == "string" and test("^https://[^/[:space:][:cntrl:]]+[^[:space:][:cntrl:]]*\\z"))
        | {$path, $plugin, url:.url}
    ' <<< "${resolved_1276}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin did not return a valid HTTPS URL" 1
    fi
    local target_1277="${command_14}"
    ensure_directory__4_v0 "${config_1269}"
    lock_file__5_v0 "${config_1269}/.targets.lock"
    local registry_1278="${config_1269}/targets.json"
    stored_targets__18_v0 "${registry_1278}"
    local current_1279="${ret_stored_targets18_v0}"
    local command_15
    command_15="$(printf '%s
' "${current_1279}" "${target_1277}" | /usr/bin/jq -ces '
        .[0] as $current | .[1] as $target
        | if any($current.targets[]; . == $target) then $current
          elif any($current.targets[]; .path == $target.path or .url == $target.url) then error("File or URL already registered")
          else $current | .targets += [$target] end
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not register: ${file_1273}" 1
    fi
    local updated_1280="${command_15}"
    if [ "$([ "_${updated_1280}" == "_${current_1279}" ]; echo $?)" != 0 ]; then
        write_file__6_v0 "${registry_1278}" "${updated_1280}"
    fi
    printf '%s\n' "${file_1273}"
}

# unlink_target(config: Text, input: Text)
unlink_target__25_v0() {
    local config_1249="${1}"
    local input_1250="${2}"
    registered_path__20_v0 "${input_1250}"
    local path_1253="${ret_registered_path20_v0}"
    ensure_directory__4_v0 "${config_1249}"
    lock_file__5_v0 "${config_1249}/.targets.lock"
    local registry_1254="${config_1249}/targets.json"
    stored_targets__18_v0 "${registry_1254}"
    local current_1255="${ret_stored_targets18_v0}"
    local command_16
    command_16="$(/usr/bin/jq -ce --arg path "${path_1253}" '
        if any(.targets[]; .path == $path) then .targets |= map(select(.path != $path))
        else error("File has no registered sync target") end
    ' <<< "${current_1255}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not unlink: ${path_1253}" 1
    fi
    local updated_1256="${command_16}"
    write_file__6_v0 "${registry_1254}" "${updated_1256}"
    printf '%s\n' "${path_1253}"
}

# list_targets(config: Text, as_json: Bool)
list_targets__26_v0() {
    local config_1236="${1}"
    local as_json_1237="${2}"
    stored_targets__18_v0 "${config_1236}/targets.json"
    local current_1238="${ret_stored_targets18_v0}"
    if [ "${as_json_1237}" != 0 ]; then
        /usr/bin/jq -c '{targets:(.targets | sort_by(.path))}' <<< "${current_1238}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not list targets" 1
        fi
    else
        /usr/bin/jq -r '.targets | sort_by(.path) | .[] | [.path,.plugin,.url] | @tsv' <<< "${current_1238}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not list targets" 1
        fi
    fi
}

# local_document(path: Text)
local_document__41_v0() {
    local path_1168="${1}"
    local command_17
    command_17="$(/usr/bin/jq -nce --rawfile raw "${path_1168}" '
      def document: capture("^# (?<title>[^\r\n]+)(?:\r?\n|\\z)(?<body>[\\s\\S]*)\\z");
      (if ($raw | test("^---\r?\n")) then $raw | capture("^(?<front>---\r?\n(?:[^\n]*\n)*?---(?:\r?\n|\\z))(?<doc>[\\s\\S]*)\\z")
       else {front:"",doc:$raw} end) as $split
      | ($split.doc | sub("^(?:\r?\n)*"; "") | document) + {front:$split.front,raw:$raw}
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Markdown must have an initial # heading: ${path_1168}" 1
    fi
    local result_1169="${command_17}"
    if [ "$([ "_${result_1169}" != "_" ]; echo $?)" != 0 ]; then
        error__0_v0 "Markdown must have an initial # heading: ${path_1168}" 1
    fi
    ret_local_document41_v0="${result_1169}"
    return 0
}

# write_markdown(path: Text, value: Text)
write_markdown__42_v0() {
    local path_1216="${1}"
    local value_1217="${2}"
    local command_18
    command_18="$(/usr/bin/stat -f "%Lp" -- "${path_1216}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read permissions: ${path_1216}" 1
    fi
    local mode_1218="${command_18}"
    local command_19
    command_19="$(/usr/bin/mktemp "${path_1216}.XXXXXX")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not stage: ${path_1216}" 1
    fi
    local temp_1219="${command_19}"
    printf '%s' "${value_1217}" | /usr/bin/jq -ej '.' > "${temp_1219}" &&
        /bin/chmod "${mode_1218}" "${temp_1219}" && /bin/mv -f -h -- "${temp_1219}" "${path_1216}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        /bin/rm -f -- "${temp_1219}"
        __status=$?
        error__0_v0 "Could not save: ${path_1216}" 1
    fi
}

# state_records(path: Text)
state_records__43_v0() {
    local path_1182="${1}"
    file_exists__3_v0 "${path_1182}"
    local ret_file_exists3_v0__27_12="${ret_file_exists3_v0}"
    if [ "$(( ! ret_file_exists3_v0__27_12 ))" != 0 ]; then
        ret_state_records43_v0="[]"
        return 0
    fi
    test -f "${path_1182}" && test ! -L "${path_1182}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid sync record: ${path_1182}" 1
    fi
    local command_20
    command_20="$(/usr/bin/jq -ces 'select(length == 1) | .[0] | select(type == "array" and all(.[]; type == "object" and (.target | type == "object") and (.baseline.title | type == "string") and (.baseline.body | type == "string")))' -- "${path_1182}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid sync record: ${path_1182}" 1
    fi
    local result_1183="${command_20}"
    ret_state_records43_v0="${result_1183}"
    return 0
}

# record_sync(state: Text, target: Text, baseline: Text)
record_sync__44_v0() {
    local state_1198="${1}"
    local target_1199="${2}"
    local baseline_1200="${3}"
    local file_1201="${state_1198}/state.json"
    state_records__43_v0 "${file_1201}"
    local current_1202="${ret_state_records43_v0}"
    local command_21
    command_21="$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read the clock" 1
    fi
    local now_1203="${command_21}"
    local command_22
    command_22="$(printf '%s
' "${current_1202}" "${target_1199}" "${baseline_1200}" | /usr/bin/jq -cs --arg now "${now_1203}" '
        .[1] as $target | .[2] as $baseline
        | (.[0] | map(select(.target != $target))) + [{$target,$baseline,syncedAt:$now}]
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not update sync record" 1
    fi
    local updated_1204="${command_22}"
    write_file__6_v0 "${file_1201}" "${updated_1204}"
}

# normalized(doc: Text)
normalized__45_v0() {
    local doc_1176="${1}"
    local command_23
    command_23="$(printf '%s' "${doc_1176}" | /usr/bin/jq -ce '
        {title, body:(.body | gsub("\r\n"; "\n") | rtrimstr("\n"))}
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read Markdown" 1
    fi
    local payload_1177="${command_23}"
    ret_normalized45_v0="${payload_1177}"
    return 0
}

# read_remote(plugin: Text, url: Text)
read_remote__46_v0() {
    local plugin_1171="${1}"
    local url_1172="${2}"
    plugin_call__23_v0 "${plugin_1171}" "read" "${url_1172}" "{}"
    local response_1173="${ret_plugin_call23_v0}"
    local command_24
    command_24="$(/usr/bin/jq -ce '
        select((.title | type == "string" and test("^[^\r\n\u0000]+\\z"))
          and (.body | type == "string" and (contains("\u0000") | not)))
        | {title,body}
    ' <<< "${response_1173}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin did not return a Markdown title and body" 1
    fi
    local document_1174="${command_24}"
    ret_read_remote46_v0="${document_1174}"
    return 0
}

# diff_document(before: Text, after: Text, before_label: Text, after_label: Text)
diff_document__47_v0() {
    local before_1192="${1}"
    local after_1193="${2}"
    local before_label_1194="${3}"
    local after_label_1195="${4}"
    # jq writes the Markdown to diff through pipes, preserving escaping in JSON.
    /usr/bin/diff -u -L "${before_label_1194}" -L "${after_label_1195}"         <(printf '%s' "${before_1192}" | /usr/bin/jq -r '"# " + .title + "\n" + .body')         <(printf '%s' "${after_1193}" | /usr/bin/jq -r '"# " + .title + "\n" + .body')
    __status=$?
    if [ "${__status}" != 0 ]; then
        if [ "$(( __status != 1 ))" != 0 ]; then
            error__0_v0 "Could not compare documents" 1
        fi
    fi
}

# saved_baseline(state: Text, target: Text)
saved_baseline__48_v0() {
    local state_1180="${1}"
    local target_1181="${2}"
    state_records__43_v0 "${state_1180}/state.json"
    local current_1184="${ret_state_records43_v0}"
    local command_25
    command_25="$(printf '%s
' "${current_1184}" "${target_1181}" | /usr/bin/jq -cs '.[1] as $target | [.[0][] | select(.target == $target) | .baseline] | last')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read the comparison baseline" 1
    fi
    local value_1185="${command_25}"
    ret_saved_baseline48_v0="${value_1185}"
    return 0
}

# compare_status(local: Text, remote: Text, baseline: Text)
compare_status__49_v0() {
    local local_1187="${1}"
    local remote_1188="${2}"
    local baseline_1189="${3}"
    local command_26
    command_26="$(printf '%s
' "${local_1187}" "${remote_1188}" "${baseline_1189}" | /usr/bin/jq -rs '
        .[0] as $local | .[1] as $remote | .[2] as $base
        | if $local == $remote then "equal"
          elif $base == null then "untracked-difference"
          elif $local != $base and $remote != $base then "conflict"
          elif $local != $base then "local-changed"
          else "remote-changed" end
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not compare sync states" 1
    fi
    local result_1190="${command_26}"
    ret_compare_status49_v0="${result_1190}"
    return 0
}

# sync_document(config: Text, state: Text, action: Text, input: Text, option: Bool, configured: Text, unattended: Bool, backend: Text)
sync_document__50_v0() {
    local config_1148="${1}"
    local state_1149="${2}"
    local action_1150="${3}"
    local input_1151="${4}"
    local option_1152="${5}"
    local configured_1153="${6}"
    local unattended_1154="${7}"
    local backend_1155="${8}"
    canonical_file__19_v0 "${input_1151}"
    local path_1156="${ret_canonical_file19_v0}"
    if [ "$([ "_${action_1150}" == "_status" ]; echo $?)" != 0 ]; then
        ensure_directory__4_v0 "${config_1148}"
        lock_file__5_v0 "${config_1148}/.targets.lock"
    fi
    local target_1158="${configured_1153}"
    if [ "$([ "_${target_1158}" != "_" ]; echo $?)" != 0 ]; then
        find_target__21_v0 "${config_1148}/targets.json" "${path_1156}"
        target_1158="${ret_find_target21_v0}"
    fi
    local command_27
    command_27="$(/usr/bin/jq -er '.url' <<< "${target_1158}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Target URL missing" 1
    fi
    local url_1165="${command_27}"
    local command_28
    command_28="$(/usr/bin/jq -er '.plugin' <<< "${target_1158}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Target plugin missing" 1
    fi
    local id_1166="${command_28}"
    local plugin_1167="${backend_1155}"
    if [ "$([ "_${plugin_1167}" != "_" ]; echo $?)" != 0 ]; then
        load_plugin__22_v0 "${config_1148}" "${id_1166}"
        plugin_1167="${ret_load_plugin22_v0}"
    fi
    local_document__41_v0 "${path_1156}"
    local body_1170="${ret_local_document41_v0}"
    read_remote__46_v0 "${plugin_1167}" "${url_1165}"
    local response_1175="${ret_read_remote46_v0}"
    normalized__45_v0 "${body_1170}"
    local local_1178="${ret_normalized45_v0}"
    normalized__45_v0 "${response_1175}"
    local remote_1179="${ret_normalized45_v0}"
    saved_baseline__48_v0 "${state_1149}" "${target_1158}"
    local baseline_1186="${ret_saved_baseline48_v0}"
    compare_status__49_v0 "${local_1178}" "${remote_1179}" "${baseline_1186}"
    local change_1191="${ret_compare_status49_v0}"
    if [ "$([ "_${action_1150}" != "_status" ]; echo $?)" != 0 ]; then
        printf '%s\n' "${change_1191}"
        if [ "$(( option_1152 && $([ "_${change_1191}" == "_equal" ]; echo $?) ))" != 0 ]; then
            if [ "$([ "_${baseline_1186}" != "_null" ]; echo $?)" != 0 ]; then
                diff_document__47_v0 "${local_1178}" "${remote_1179}" "local" "remote"
            else
                diff_document__47_v0 "${baseline_1186}" "${local_1178}" "last sync" "local"
                diff_document__47_v0 "${baseline_1186}" "${remote_1179}" "last sync" "remote"
            fi
        fi
        exit 0
    fi
    ensure_directory__4_v0 "${state_1149}"
    if [ "$([ "_${change_1191}" != "_equal" ]; echo $?)" != 0 ]; then
        if [ "$(( unattended_1154 && $([ "_${baseline_1186}" != "_${local_1178}" ]; echo $?) ))" != 0 ]; then
            exit 0
        fi
        lock_sync_writes__8_v0 "${state_1149}"
        record_sync__44_v0 "${state_1149}" "${target_1158}" "${local_1178}"
        echo "equal"
        exit 0
    fi
    if [ "$([ "_${action_1150}" != "_push" ]; echo $?)" != 0 ]; then
        diff_document__47_v0 "${remote_1179}" "${local_1178}" "remote" "proposed remote"
        printf '%s\n' "${url_1165}"
        /usr/bin/jq -e '.writable' <<< "${plugin_1167}" > /dev/null
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Apply the displayed change at the sync target, then run push again to record the match" 1
        fi
        if [ "$(( $([ "_${change_1191}" == "_local-changed" ]; echo $?) && $(( ! option_1152 )) ))" != 0 ]; then
            error__0_v0 "${change_1191}: use --overwrite to select the local content explicitly" 1
        fi
        if [ "$(( ! unattended_1154 ))" != 0 ]; then
            confirm__7_v0 "Apply this change to ${url_1165}?"
        fi
        local_document__41_v0 "${path_1156}"
        local ret_local_document41_v0__136_12="${ret_local_document41_v0}"
        read_remote__46_v0 "${plugin_1167}" "${url_1165}"
        local ret_read_remote46_v0__136_44="${ret_read_remote46_v0}"
        if [ "$(( $([ "_${ret_local_document41_v0__136_12}" == "_${body_1170}" ]; echo $?) || $([ "_${ret_read_remote46_v0__136_44}" == "_${response_1175}" ]; echo $?) ))" != 0 ]; then
            error__0_v0 "Contents changed; review the new diff before applying" 1
        fi
        local command_29
        command_29="$(printf '%s
' "${response_1175}" "${body_1170}" | /usr/bin/jq -cs '{expected:.[0],document:(.[1] | {title,body})}')"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not prepare the document" 1
        fi
        local payload_1209="${command_29}"
        plugin_call__23_v0 "${plugin_1167}" "write" "${url_1165}" "${payload_1209}"
        local receipt_1210="${ret_plugin_call23_v0}"
        /usr/bin/jq -e '.written == true' <<< "${receipt_1210}" > /dev/null
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Plugin did not confirm the write" 1
        fi
        lock_sync_writes__8_v0 "${state_1149}"
        read_remote__46_v0 "${plugin_1167}" "${url_1165}"
        local ret_read_remote46_v0__141_41="${ret_read_remote46_v0}"
        normalized__45_v0 "${ret_read_remote46_v0__141_41}"
        local saved_remote_1211="${ret_normalized45_v0}"
        local_document__41_v0 "${path_1156}"
        local ret_local_document41_v0__142_37="${ret_local_document41_v0}"
        if [ "$(( $([ "_${saved_remote_1211}" == "_${local_1178}" ]; echo $?) || $([ "_${ret_local_document41_v0__142_37}" == "_${body_1170}" ]; echo $?) ))" != 0 ]; then
            error__0_v0 "Contents differ after writing; check status before retrying" 1
        fi
        record_sync__44_v0 "${state_1149}" "${target_1158}" "${local_1178}"
        echo "equal"
        exit 0
    fi
    diff_document__47_v0 "${local_1178}" "${remote_1179}" "local" "proposed local"
    if [ "$(( $([ "_${change_1191}" == "_remote-changed" ]; echo $?) && $(( ! option_1152 )) ))" != 0 ]; then
        error__0_v0 "Use --overwrite to select the remote content explicitly" 1
    fi
    if [ "$(( ! unattended_1154 ))" != 0 ]; then
        confirm__7_v0 "Apply this change to ${path_1156}?"
    fi
    lock_sync_writes__8_v0 "${state_1149}"
    local_document__41_v0 "${path_1156}"
    local current_1212="${ret_local_document41_v0}"
    read_remote__46_v0 "${plugin_1167}" "${url_1165}"
    local current_remote_1213="${ret_read_remote46_v0}"
    if [ "$(( $([ "_${current_1212}" == "_${body_1170}" ]; echo $?) || $([ "_${current_remote_1213}" == "_${response_1175}" ]; echo $?) ))" != 0 ]; then
        error__0_v0 "Contents changed; review the new diff before applying" 1
    fi
    ensure_directory__4_v0 "${state_1149}/backup"
    local command_30
    command_30="$(/usr/bin/mktemp "${state_1149}/backup/document.XXXXXX")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not stage backup" 1
    fi
    local backup_1214="${command_30}"
    /bin/cp -- "${path_1156}" "${backup_1214}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not save backup" 1
    fi
    local command_31
    command_31="$(printf '%s
' "${body_1170}" "${response_1175}" | /usr/bin/jq -cs '
        (.[0].front | if . == "" or endswith("\n") then . else . + "\n" end) + "# " + .[1].title + "\n" + .[1].body
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not render Markdown" 1
    fi
    local updated_1215="${command_31}"
    write_markdown__42_v0 "${path_1156}" "${updated_1215}"
    local_document__41_v0 "${path_1156}"
    local ret_local_document41_v0__161_30="${ret_local_document41_v0}"
    normalized__45_v0 "${ret_local_document41_v0__161_30}"
    local saved_1220="${ret_normalized45_v0}"
    if [ "$([ "_${saved_1220}" == "_${remote_1179}" ]; echo $?)" != 0 ]; then
        error__0_v0 "Saved Markdown does not match the sync target; backup: ${backup_1214}" 1
    fi
    record_sync__44_v0 "${state_1149}" "${target_1158}" "${remote_1179}"
    printf '%s\n' "${path_1156}"
}

# read_job(config: Text, name: Text)
read_job__52_v0() {
    local config_1109="${1}"
    local name_1110="${2}"
    local path_1111="${config_1109}/jobs/${name_1110}.json"
    local command_32
    command_32="$(/usr/bin/jq -ces '
        select(length == 1) | .[0] | select(type == "object"
          and (.plugin | type == "string") and (.mode == "manual" or .mode == "watch")
          and (.settings | type == "object")
          and (if has("intervalSeconds") then (.intervalSeconds | type == "number" and . == floor and . >= 1 and . <= 86400) else true end))
    ' -- "${path_1111}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid job: ${path_1111}" 1
    fi
    local job_1112="${command_32}"
    local command_33
    command_33="$(/usr/bin/jq -r .plugin <<< "${job_1112}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Missing plugin" 1
    fi
    local id_1113="${command_33}"
    load_plugin__22_v0 "${config_1109}" "${id_1113}"
    local plugin_1121="${ret_load_plugin22_v0}"
    local command_34
    command_34="$(/usr/bin/jq -r .mode <<< "${job_1112}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Missing job mode" 1
    fi
    local mode_1122="${command_34}"
    /usr/bin/jq -e --arg mode "${mode_1122}" '.allowedModes | index($mode) != null' <<< "${plugin_1121}" > /dev/null
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin ${id_1113} does not allow job mode: ${mode_1122}" 1
    fi
    local command_35
    command_35="$(printf '%s
' "${job_1112}" "${plugin_1121}" | /usr/bin/jq -cs '
        .[0] as $job | .[1] as $manifest | $job + {backend:($manifest + {settings:($manifest.settings + $job.settings)})}
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid plugin settings" 1
    fi
    local plan_1123="${command_35}"
    ret_read_job52_v0="${plan_1123}"
    return 0
}

# run_pass(config: Text, state: Text, plan: Text)
run_pass__53_v0() {
    local config_1126="${1}"
    local state_1127="${2}"
    local plan_1128="${3}"
    local command_36
    command_36="$(/usr/bin/jq -c .backend <<< "${plan_1128}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Missing plugin" 1
    fi
    local plugin_1129="${command_36}"
    /usr/bin/jq -e '.protocol == "sync"' <<< "${plugin_1129}" > /dev/null
    __status=$?
    if [ "${__status}" = 0 ]; then
        plugin_call__23_v0 "${plugin_1129}" "sync" "" "{}"
        local result_1138="${ret_plugin_call23_v0}"
        /usr/bin/jq -e '.synced == true' <<< "${result_1138}" > /dev/null
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Plugin did not complete synchronization" 1
        fi
        exit 0
    fi
    local command_37
    command_37="$(/usr/bin/jq -er '.backend.settings.file | select(type == "string" and startswith("/") and (test("[[:cntrl:]]") | not))' <<< "${plan_1128}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Expected an absolute Markdown file path" 1
    fi
    local file_1139="${command_37}"
    canonical_file__19_v0 "${file_1139}"
    local path_1142="${ret_canonical_file19_v0}"
    local command_38
    command_38="$(/usr/bin/jq -er '.backend.settings.url | select(type == "string" and test("^https://[^[:space:][:cntrl:]]+$"))' <<< "${plan_1128}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Expected an HTTPS URL" 1
    fi
    local url_1143="${command_38}"
    local command_39
    command_39="$(/usr/bin/jq -er '.backend.settings.direction | select(. == "push" or . == "pull")' <<< "${plan_1128}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Expected direction pull or push" 1
    fi
    local action_1144="${command_39}"
    local command_40
    command_40="$(/usr/bin/jq -r .mode <<< "${plan_1128}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Missing mode" 1
    fi
    local mode_1145="${command_40}"
    if [ "$(( $([ "_${mode_1145}" != "_watch" ]; echo $?) && $([ "_${action_1144}" != "_push" ]; echo $?) ))" != 0 ]; then
        /usr/bin/jq -e '.writable and .backgroundWrite' <<< "${plugin_1129}" > /dev/null
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Plugin does not support unattended writes" 1
        fi
    fi
    plugin_call__23_v0 "${plugin_1129}" "resolve" "${url_1143}" "{}"
    local resolved_1146="${ret_plugin_call23_v0}"
    local command_41
    command_41="$(printf '%s
' "${plan_1128}" "${resolved_1146}" | /usr/bin/jq -ces --arg path "${path_1142}" '
        select(.[1].url | type == "string" and test("^https://[^[:space:][:cntrl:]]+$"))
        | {path:$path,plugin:.[0].plugin,url:.[1].url}
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin returned an invalid URL" 1
    fi
    local target_1147="${command_41}"
    sync_document__50_v0 "${config_1126}" "${state_1127}" "${action_1144}" "${path_1142}" 0 "${target_1147}" "$([ "_${mode_1145}" != "_watch" ]; echo $?)" "${plugin_1129}"
}

# active(dir: Text)
active__54_v0() {
    local dir_1221="${1}"
    /usr/bin/lockf -k -s -t 0 "${dir_1221}/worker.lock" /usr/bin/true
    __status=$?
    if [ "${__status}" != 0 ]; then
        if [ "$(( __status == 75 ))" != 0 ]; then
            ret_active54_v0=1
            return 0
        fi
        error__0_v0 "Could not check job lock" 1
    fi
    ret_active54_v0=0
    return 0
}

# job_command(config: Text, state: Text, script: Text, action: Text, name: Text)
job_command__55_v0() {
    local config_1098="${1}"
    local state_1099="${2}"
    local script_1100="${3}"
    local action_1101="${4}"
    local name_1102="${5}"
    LC_ALL=C; [[ "${name_1102}" =~ ^[a-z0-9][a-z0-9-]*$ ]]
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid job name" 2
    fi
    local dir_1103="${state_1099}/jobs/${name_1102}"
    ensure_directory__4_v0 "${dir_1103}"
    if [ "$([ "_${action_1101}" != "_--job-worker" ]; echo $?)" != 0 ]; then
        exec 8>>"${dir_1103}/worker.lock" && /usr/bin/lockf -s -t 0 8
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Job already running" 1
        fi
        local command_42
        command_42="$(/usr/bin/jq -ce .)"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Missing job snapshot" 1
        fi
        local plan_1105="${command_42}"
        FILE_SYNC_RUN_DIR=$(/usr/bin/mktemp -d "${dir_1103}/run.XXXXXX") && export FILE_SYNC_RUN_DIR &&
            trap '/bin/rm -rf -- "$FILE_SYNC_RUN_DIR"' EXIT
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not prepare the watch session" 1
        fi
        local command_43
        command_43="$(/usr/bin/jq -r '.intervalSeconds // 5' <<< "${plan_1105}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid interval" 1
        fi
        local interval_1106="${command_43}"
        while :
        do
            file_exists__3_v0 "${dir_1103}/stop"
            local ret_file_exists3_v0__67_16="${ret_file_exists3_v0}"
            if [ "${ret_file_exists3_v0__67_16}" != 0 ]; then
                exit 0
            fi
            /bin/bash "${script_1100}" --job-pass "${name_1102}" <<< "${plan_1105}" > /dev/null
            __status=$?
            if [ "${__status}" != 0 ]; then
                error__0_v0 "Job stopped after a failed pass" 1
            fi
            : > "${dir_1103}/ready"
            __status=$?
            if [ "${__status}" != 0 ]; then
                error__0_v0 "Could not record job start" 1
            fi
            local elapsed_1108=0
            while :
            do
                file_exists__3_v0 "${dir_1103}/stop"
                local ret_file_exists3_v0__72_20="${ret_file_exists3_v0}"
                if [ "${ret_file_exists3_v0__72_20}" != 0 ]; then
                    exit 0
                fi
                test "${elapsed_1108}" -lt "${interval_1106}"
                __status=$?
                if [ "${__status}" != 0 ]; then
                    break
                fi
                /bin/sleep 1
                __status=$?
                elapsed_1108="$(( elapsed_1108 + 1 ))"
            done
        done
    fi
    if [ "$([ "_${action_1101}" != "_--job-pass" ]; echo $?)" != 0 ]; then
        read_job__52_v0 "${config_1098}" "${name_1102}"
        local plan_1124="${ret_read_job52_v0}"
        local command_44
        command_44="$(/usr/bin/jq -ce .)"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Missing worker settings" 1
        fi
        local snapshot_1125="${command_44}"
        if [ "$([ "_${plan_1124}" == "_${snapshot_1125}" ]; echo $?)" != 0 ]; then
            error__0_v0 "Job configuration changed" 1
        fi
        run_pass__53_v0 "${config_1098}" "${state_1099}" "${plan_1124}"
        exit 0
    fi
    exec 6>>"${dir_1103}/control.lock" && /usr/bin/lockf -t 15 6
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not lock job" 1
    fi
    if [ "$([ "_${action_1101}" != "_job-status" ]; echo $?)" != 0 ]; then
        active__54_v0 "${dir_1103}"
        local running_1222="${ret_active54_v0}"
        /usr/bin/jq -nc --arg job "${name_1102}" --argjson running "${running_1222}" --arg log "${dir_1103}/worker.log" '{job:$job,running:($running == 1),log:$log}'
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not display job state" 1
        fi
        exit 0
    fi
    if [ "$([ "_${action_1101}" != "_stop" ]; echo $?)" != 0 ]; then
        : > "${dir_1103}/stop"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not request job stop" 1
        fi
        for (( _attempt_1223=0; _attempt_1223 < 50; _attempt_1223++ )); do
            active__54_v0 "${dir_1103}"
            local ret_active54_v0__95_20="${ret_active54_v0}"
            if [ "$(( ! ret_active54_v0__95_20 ))" != 0 ]; then
                exit 0
            fi
            /bin/sleep 0.1
            __status=$?
done
        error__0_v0 "Stop requested; waiting for the current plugin call to finish" 1
    fi
    read_job__52_v0 "${config_1098}" "${name_1102}"
    local plan_1224="${ret_read_job52_v0}"
    active__54_v0 "${dir_1103}"
    local ret_active54_v0__101_8="${ret_active54_v0}"
    if [ "${ret_active54_v0__101_8}" != 0 ]; then
        error__0_v0 "Job already running; stop it before restarting" 1
    fi
    /usr/bin/jq -e '.mode == "manual"' <<< "${plan_1224}" > /dev/null
    __status=$?
    if [ "${__status}" = 0 ]; then
        run_pass__53_v0 "${config_1098}" "${state_1099}" "${plan_1224}"
        exit 0
    fi
    /bin/rm -f -- "${dir_1103}/stop" "${dir_1103}/ready"
    __status=$?
    local command_45
    command_45="$((exec 6>&-; exec /usr/bin/nohup /bin/bash "${script_1100}" --job-worker "${name_1102}") <<< "${plan_1224}" >"${dir_1103}/worker.log" 2>&1 & printf '%s' "$!")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not start job" 1
    fi
    local pid_1225="${command_45}"
    for (( _attempt_1226=0; _attempt_1226 < 50; _attempt_1226++ )); do
        file_exists__3_v0 "${dir_1103}/ready"
        local ret_file_exists3_v0__109_12="${ret_file_exists3_v0}"
        if [ "${ret_file_exists3_v0__109_12}" != 0 ]; then
            printf '%s\n' "${name_1102}"
            exit 0
        fi
        kill -0 "${pid_1225}" 2>/dev/null
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Job failed; see ${dir_1103}/worker.log" 1
        fi
        /bin/sleep 0.1
        __status=$?
done
    active__54_v0 "${dir_1103}"
    local ret_active54_v0__116_8="${ret_active54_v0}"
    if [ "${ret_active54_v0__116_8}" != 0 ]; then
        echo "Starting ${name_1102}; see ${dir_1103}/worker.log"
        exit 0
    fi
    error__0_v0 "Job did not start; see ${dir_1103}/worker.log" 1
}

# usage()
usage__65_v0() {
    echo "Usage: file-sync link <file> <url> --plugin <id> | unlink <file> | list [--json]"
    echo "       file-sync status <file> [--diff] | pull <file> [--overwrite] | push <file> [--overwrite]"
    echo "       file-sync run <job> | job-status <job> | stop <job>"
    echo "       file-sync mirror --to <directory> [--write-back] -- <file>..."
    echo "       file-sync --check"
}

# check_dependencies()
check_dependencies__66_v0() {
    local ready_8=1
    local required_9=("/bin/bash" "/bin/chmod" "/bin/cp" "/bin/date" "/bin/mkdir" "/bin/mv" "/bin/realpath" "/bin/rm" "/bin/sleep" "/usr/bin/awk" "/usr/bin/basename" "/usr/bin/diff" "/usr/bin/dirname" "/usr/bin/env" "/usr/bin/jq" "/usr/bin/lockf" "/usr/bin/mktemp" "/usr/bin/nohup" "/usr/bin/printenv" "/usr/bin/shasum" "/usr/bin/stat" "/usr/bin/true")
    (( BASH_VERSINFO[0] > 3 || (BASH_VERSINFO[0] == 3 && BASH_VERSINFO[1] >= 2) ))
    __status=$?
    if [ "${__status}" != 0 ]; then
        printf 'Unsupported Bash %s (requires 3.2 or newer)
' "$BASH_VERSION"
        __status=$?
        ready_8=0
    fi
    if [ "${ready_8}" != 0 ]; then
        printf 'OK Bash %s
' "$BASH_VERSION"
        __status=$?
    fi
    for path_10 in "${required_9[@]}"; do
        test -f "${path_10}" && test -x "${path_10}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo "Missing ${path_10}"
            ready_8=0
            continue
        fi
        echo "OK ${path_10}"
    done
    echo "Remote Markdown comparison requires the plugin configured for the target."
    if [ "$(( ! ready_8 ))" != 0 ]; then
        exit 1
    fi
    exit 0
}

typeset -r args_0=("$0" "$@")
__length_50=("${args_0[@]}")
if [ "$(( $(( ${#__length_50[@]} > 1 )) && $([ "_${args_0[1]?"Index out of bounds (at src/main.ab:63:31)"}" != "_--check" ]; echo $?) ))" != 0 ]; then
    __length_51=("${args_0[@]}")
    if [ "$(( ${#__length_51[@]} != 2 ))" != 0 ]; then
        error__0_v0 "Usage: file-sync --check" 2
    fi
    check_dependencies__66_v0 
fi
umask 077
__status=$?
env_or__1_v0 "HOME" ""
home_17="${ret_env_or1_v0}"
if [ "$([ "_${home_17}" != "_" ]; echo $?)" != 0 ]; then
    error__0_v0 "HOME is required" 1
fi
env_or__1_v0 "FILE_SYNC_CONFIG_HOME" "${home_17}/.config/file-sync"
config_18="${ret_env_or1_v0}"
env_or__1_v0 "FILE_SYNC_STATE_HOME" "${home_17}/.local/state/file-sync"
state_19="${ret_env_or1_v0}"
__length_52=("${args_0[@]}")
if [ "$(( ${#__length_52[@]} == 1 ))" != 0 ]; then
    error__0_v0 "Expected a file-sync command; use --help" 2
fi
action_20="${args_0[1]?"Index out of bounds (at src/main.ab:73:25)"}"
if [ "$(( $(( $(( $(( $([ "_${action_20}" != "_run" ]; echo $?) || $([ "_${action_20}" != "_stop" ]; echo $?) )) || $([ "_${action_20}" != "_job-status" ]; echo $?) )) || $([ "_${action_20}" != "_--job-pass" ]; echo $?) )) || $([ "_${action_20}" != "_--job-worker" ]; echo $?) ))" != 0 ]; then
    __length_53=("${args_0[@]}")
    if [ "$(( ${#__length_53[@]} != 3 ))" != 0 ]; then
        error__0_v0 "Expected one job name" 2
    fi
    real_path__2_v0 "${args_0[0]?"Index out of bounds (at src/main.ab:76:39)"}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not locate file-sync" 1
    fi
    script_25="${ret_real_path2_v0}"
    job_command__55_v0 "${config_18}" "${state_19}" "${script_25}" "${action_20}" "${args_0[2]?"Index out of bounds (at src/main.ab:77:57)"}"
    exit 0
fi
if [ "$([ "_${action_20}" != "_mirror" ]; echo $?)" != 0 ]; then
    load_plugin__22_v0 "${config_18}" "local-mirror"
    plugin_1227="${ret_load_plugin22_v0}"
    command_54="$(/usr/bin/jq -er .command <<< "${plugin_1227}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Missing local mirror plugin" 1
    fi
    command_1228="${command_54}"
    options_1229=()
    index_1230=1
    __length_56=("${args_0[@]}")
    while [ "$(( index_1230 < ${#__length_56[@]} ))" != 0 ]; do
        options_1229+=("${args_0[${index_1230}]?"Index out of bounds (at src/main.ab:86:30)"}")
        index_1230="$(( index_1230 + 1 ))"
    done
    real_path__2_v0 "${args_0[0]?"Index out of bounds (at src/main.ab:89:39)"}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not locate file-sync" 1
    fi
    script_1231="${ret_real_path2_v0}"
    FILE_SYNC_CLI="${script_1231}" exec "${command_1228}" "${options_1229[@]}"
    __status=$?
fi
if [ "$(( $([ "_${action_20}" != "_--help" ]; echo $?) || $([ "_${action_20}" != "_-h" ]; echo $?) ))" != 0 ]; then
    usage__65_v0 
    exit 0
fi
if [ "$([ "_${action_20}" != "_list" ]; echo $?)" != 0 ]; then
    as_json_1232=0
    __length_58=("${args_0[@]}")
    if [ "$(( ${#__length_58[@]} == 3 ))" != 0 ]; then
        as_json_1232="$([ "_${args_0[2]?"Index out of bounds (at src/main.ab:98:44)"}" != "_--json" ]; echo $?)"
    fi
    __length_59=("${args_0[@]}")
    __length_60=("${args_0[@]}")
    if [ "$(( $(( ${#__length_59[@]} > 3 )) || $(( $(( ${#__length_60[@]} == 3 )) && $(( ! as_json_1232 )) )) ))" != 0 ]; then
        error__0_v0 "Usage: file-sync list [--json]" 2
    fi
    list_targets__26_v0 "${config_18}" "${as_json_1232}"
    exit 0
fi
if [ "$([ "_${action_20}" != "_unlink" ]; echo $?)" != 0 ]; then
    __length_61=("${args_0[@]}")
    if [ "$(( ${#__length_61[@]} != 3 ))" != 0 ]; then
        error__0_v0 "Usage: file-sync unlink <file>" 2
    fi
    unlink_target__25_v0 "${config_18}" "${args_0[2]?"Index out of bounds (at src/main.ab:105:36)"}"
    exit 0
fi
if [ "$([ "_${action_20}" != "_link" ]; echo $?)" != 0 ]; then
    __length_62=("${args_0[@]}")
    if [ "$(( $(( ${#__length_62[@]} != 6 )) || $([ "_${args_0[4]?"Index out of bounds (at src/main.ab:110:35)"}" == "_--plugin" ]; echo $?) ))" != 0 ]; then
        error__0_v0 "Usage: file-sync link <file> <url> --plugin <id>" 2
    fi
    link_target__24_v0 "${config_18}" "${args_0[5]?"Index out of bounds (at src/main.ab:113:34)"}" "${args_0[2]?"Index out of bounds (at src/main.ab:113:43)"}" "${args_0[3]?"Index out of bounds (at src/main.ab:113:52)"}"
    exit 0
fi
if [ "$(( $(( $([ "_${action_20}" != "_status" ]; echo $?) || $([ "_${action_20}" != "_push" ]; echo $?) )) || $([ "_${action_20}" != "_pull" ]; echo $?) ))" != 0 ]; then
    option_1281=0
    flag_1282="--overwrite"
    if [ "$([ "_${action_20}" != "_status" ]; echo $?)" != 0 ]; then
        flag_1282="--diff"
    fi
    __length_63=("${args_0[@]}")
    if [ "$(( ${#__length_63[@]} == 4 ))" != 0 ]; then
        option_1281="$([ "_${args_0[3]?"Index out of bounds (at src/main.ab:120:43)"}" != "_${flag_1282}" ]; echo $?)"
    fi
    __length_64=("${args_0[@]}")
    __length_65=("${args_0[@]}")
    __length_66=("${args_0[@]}")
    if [ "$(( $(( $(( ${#__length_64[@]} < 3 )) || $(( ${#__length_65[@]} > 4 )) )) || $(( $(( ${#__length_66[@]} == 4 )) && $(( ! option_1281 )) )) ))" != 0 ]; then
        error__0_v0 "Usage: file-sync ${action_20} <file> [${flag_1282}]" 2
    fi
    sync_document__50_v0 "${config_18}" "${state_19}" "${action_20}" "${args_0[2]?"Index out of bounds (at src/main.ab:124:51)"}" "${option_1281}" "" 0 ""
    exit 0
fi
error__0_v0 "Unknown file-sync command: ${action_20}" 2
