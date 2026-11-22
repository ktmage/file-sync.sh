#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.6.0-alpha
# error(message: Text, code: Int)
error__0_v0() {
    local message_10="${1}"
    local code_11="${2}"
    printf '%s
' "${message_10}" >&2
    __status=$?
    exit "${code_11}"
}

# env_or(name: Text, fallback: Text)
env_or__1_v0() {
    local name_4="${1}"
    local fallback_5="${2}"
    local command_0
    command_0="$(/usr/bin/printenv "${name_4}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_env_or1_v0="${fallback_5}"
        return 0
    fi
    local value_6="${command_0}"
    if [ "$([ "_${value_6}" != "_" ]; echo $?)" != 0 ]; then
        ret_env_or1_v0="${fallback_5}"
        return 0
    fi
    ret_env_or1_v0="${value_6}"
    return 0
}

# real_path(path: Text)
real_path__2_v0() {
    local path_491="${1}"
    local command_1
    command_1="$(resolved=$(/bin/realpath -- "${path_491}" && printf '.') || exit 1
        newline=$'\n'
        resolved="${resolved%"$newline."}"
        if [[ "$resolved" == *"$newline" ]]; then exit 1; fi
        printf '%s' "$resolved")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_real_path2_v0=''
        return "${__status}"
    fi
    local output_492="${command_1}"
    ret_real_path2_v0="${output_492}"
    return 0
}

# file_exists(path: Text)
file_exists__3_v0() {
    local path_500="${1}"
    test -e "${path_500}" || test -L "${path_500}"
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
    local path_488="${1}"
    /bin/mkdir -p -- "${path_488}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not create directory: ${path_488}" 1
    fi
}

# lock_file(path: Text)
lock_file__5_v0() {
    local path_498="${1}"
    # lockf on an inherited descriptor keeps the lock until this shell exits.
    test ! -L "${path_498}" && exec 9>>"${path_498}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not open lock: ${path_498}" 1
    fi
    /usr/bin/lockf -t 15 9
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not acquire lock: ${path_498}" 1
    fi
}

# write_file(path: Text, data: Text)
write_file__6_v0() {
    local path_521="${1}"
    local data_522="${2}"
    local command_2
    command_2="$(/usr/bin/mktemp "${path_521}.XXXXXX")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not stage: ${path_521}" 1
    fi
    local temp_523="${command_2}"
    printf '%s
' "${data_522}" > "${temp_523}" && /bin/mv -f -h -- "${temp_523}" "${path_521}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        /bin/rm -f -- "${temp_523}"
        __status=$?
        error__0_v0 "Could not save: ${path_521}" 1
    fi
}

# confirm(message: Text)
confirm__7_v0() {
    local message_872="${1}"
    printf '%s [y/N] ' "${message_872}" >&2
    __status=$?
    IFS= read -r answer && case "$answer" in y|Y|yes|YES) true;; *) false;; esac
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Cancelled" 1
    fi
}

# hash_file(path: Text)
hash_file__14_v0() {
    local path_517="${1}"
    file_exists__3_v0 "${path_517}"
    local ret_file_exists3_v0__4_12="${ret_file_exists3_v0}"
    if [ "$(( ! ret_file_exists3_v0__4_12 ))" != 0 ]; then
        ret_hash_file14_v0="missing"
        return 0
    fi
    test -f "${path_517}" && test ! -L "${path_517}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_hash_file14_v0="invalid"
        return 0
    fi
    real_path__2_v0 "${path_517}">/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_hash_file14_v0="invalid"
        return 0
    fi
    local resolved_518="${ret_real_path2_v0}"
    if [ "$([ "_${path_517}" == "_${resolved_518}" ]; echo $?)" != 0 ]; then
        ret_hash_file14_v0="invalid"
        return 0
    fi
    local command_3
    command_3="$(/usr/bin/shasum -a 256 < "${path_517}" | /usr/bin/awk 'NF == 2 && length($1) == 64 {print $1}')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_hash_file14_v0="invalid"
        return 0
    fi
    local hash_519="${command_3}"
    if [ "$([ "_${hash_519}" != "_" ]; echo $?)" != 0 ]; then
        ret_hash_file14_v0="invalid"
        return 0
    fi
    ret_hash_file14_v0="${hash_519}"
    return 0
}

# lock_sync_writes(state: Text)
lock_sync_writes__15_v0() {
    local state_538="${1}"
    ensure_directory__4_v0 "${state_538}"
    local path_539="${state_538}/.write.lock"
    test ! -L "${path_539}" && exec 7>>"${path_539}" && /usr/bin/lockf -t 15 7
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not acquire the file write lock: ${path_539}" 1
    fi
}

# running(directory: Text)
running__16_v0() {
    local directory_503="${1}"
    /usr/bin/lockf -k -s -t 0 "${directory_503}/worker.lock" /usr/bin/true
    __status=$?
    if [ "${__status}" != 0 ]; then
        if [ "$(( __status == 75 ))" != 0 ]; then
            ret_running16_v0=1
            return 0
        fi
        error__0_v0 "Could not check mirror worker: ${directory_503}" 1
    fi
    ret_running16_v0=0
    return 0
}

# load_session(path: Text)
load_session__17_v0() {
    local path_499="${1}"
    file_exists__3_v0 "${path_499}"
    local ret_file_exists3_v0__30_12="${ret_file_exists3_v0}"
    if [ "$(( ! ret_file_exists3_v0__30_12 ))" != 0 ]; then
        ret_load_session17_v0="{\"pairs\":[]}"
        return 0
    fi
    test -f "${path_499}" && test ! -L "${path_499}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid mirror record: ${path_499}" 1
    fi
    local command_4
    command_4="$(/usr/bin/jq -ces '
        select(length == 1) | .[0] | select(type == "object" and (.destination | type == "string")
        and (.writeBack | type == "boolean") and (.pairs | type == "array" and all(.[];
          (.source | type == "string" and startswith("/")) and (.copy | type == "string" and startswith("/"))
          and (.baseline == null or (.baseline | type == "string" and length == 64 and test("^[a-f0-9]+$"))))))
    ' -- "${path_499}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid mirror record: ${path_499}" 1
    fi
    local value_501="${command_4}"
    ret_load_session17_v0="${value_501}"
    return 0
}

# directory_is_safe(path: Text)
directory_is_safe__18_v0() {
    local path_533="${1}"
    local command_6
    command_6="$(/bin/realpath -- "${path_533}" 2>/dev/null)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        file_exists__3_v0 "${path_533}"
        local ret_file_exists3_v0__43_12="${ret_file_exists3_v0}"
        if [ "${ret_file_exists3_v0__43_12}" != 0 ]; then
            ret_directory_is_safe18_v0=0
            return 0
        fi
        local command_5
        command_5="$(/usr/bin/dirname -- "${path_533}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_directory_is_safe18_v0=0
            return 0
        fi
        local parent_534="${command_5}"
        if [ "$([ "_${parent_534}" != "_${path_533}" ]; echo $?)" != 0 ]; then
            ret_directory_is_safe18_v0=0
            return 0
        fi
        directory_is_safe__18_v0 "${parent_534}"
        ret_directory_is_safe18_v0="${ret_directory_is_safe18_v0}"
        return 0
    fi
    local resolved_535="${command_6}"
    ret_directory_is_safe18_v0="$([ "_${resolved_535}" != "_${path_533}" ]; echo $?)"
    return 0
}

# copy_checked(state: Text, source: Text, source_hash: Text, target: Text, target_hash: Text, backup_target: Bool)
copy_checked__19_v0() {
    local state_555="${1}"
    local source_556="${2}"
    local source_hash_557="${3}"
    local target_558="${4}"
    local target_hash_559="${5}"
    local backup_target_560="${6}"
    local command_7
    command_7="$(/usr/bin/dirname -- "${target_558}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_checked19_v0=0
        return 0
    fi
    local parent_561="${command_7}"
    directory_is_safe__18_v0 "${parent_561}"
    local ret_directory_is_safe18_v0__53_12="${ret_directory_is_safe18_v0}"
    if [ "$(( ! ret_directory_is_safe18_v0__53_12 ))" != 0 ]; then
        ret_copy_checked19_v0=0
        return 0
    fi
    /bin/mkdir -p -- "${parent_561}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_checked19_v0=0
        return 0
    fi
    directory_is_safe__18_v0 "${parent_561}"
    local ret_directory_is_safe18_v0__55_12="${ret_directory_is_safe18_v0}"
    if [ "$(( ! ret_directory_is_safe18_v0__55_12 ))" != 0 ]; then
        ret_copy_checked19_v0=0
        return 0
    fi
    local command_8
    command_8="$(/usr/bin/mktemp "${parent_561}/.file-sync.XXXXXX")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_checked19_v0=0
        return 0
    fi
    local temp_562="${command_8}"
    /bin/cp -p -- "${source_556}" "${temp_562}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        /bin/rm -f -- "${temp_562}"
        __status=$?
        ret_copy_checked19_v0=0
        return 0
    fi
    hash_file__14_v0 "${temp_562}"
    local ret_hash_file14_v0__61_8="${ret_hash_file14_v0}"
    hash_file__14_v0 "${target_558}"
    local ret_hash_file14_v0__61_42="${ret_hash_file14_v0}"
    directory_is_safe__18_v0 "${parent_561}"
    local ret_directory_is_safe18_v0__61_82="${ret_directory_is_safe18_v0}"
    if [ "$(( $(( $([ "_${ret_hash_file14_v0__61_8}" == "_${source_hash_557}" ]; echo $?) || $([ "_${ret_hash_file14_v0__61_42}" == "_${target_hash_559}" ]; echo $?) )) || $(( ! ret_directory_is_safe18_v0__61_82 )) ))" != 0 ]; then
        /bin/rm -f -- "${temp_562}"
        __status=$?
        ret_copy_checked19_v0=0
        return 0
    fi
    if [ "${backup_target_560}" != 0 ]; then
        /bin/mkdir -p -- "${state_555}/backup" && /bin/chmod 700 "${state_555}/backup"
        __status=$?
        if [ "${__status}" != 0 ]; then
            /bin/rm -f -- "${temp_562}"
            __status=$?
            ret_copy_checked19_v0=0
            return 0
        fi
        local command_9
        command_9="$(/usr/bin/mktemp "${state_555}/backup/mirror.XXXXXX")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            /bin/rm -f -- "${temp_562}"
            __status=$?
            ret_copy_checked19_v0=0
            return 0
        fi
        local backup_563="${command_9}"
        /bin/cp -- "${target_558}" "${backup_563}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            /bin/rm -f -- "${temp_562}" "${backup_563}"
            __status=$?
            ret_copy_checked19_v0=0
            return 0
        fi
    fi
    /bin/mv -f -h -- "${temp_562}" "${target_558}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        /bin/rm -f -- "${temp_562}"
        __status=$?
        ret_copy_checked19_v0=0
        return 0
    fi
    ret_copy_checked19_v0=1
    return 0
}

# mirror_change(source: Text, copy: Text, previous: Text, write_back: Bool)
mirror_change__20_v0() {
    local source_548="${1}"
    local copy_549="${2}"
    local previous_550="${3}"
    local write_back_551="${4}"
    if [ "$(( $([ "_${source_548}" != "_invalid" ]; echo $?) || $([ "_${copy_549}" != "_invalid" ]; echo $?) ))" != 0 ]; then
        ret_mirror_change20_v0="unreadable or replaced path"
        return 0
    fi
    if [ "$([ "_${source_548}" != "_missing" ]; echo $?)" != 0 ]; then
        ret_mirror_change20_v0="missing source"
        return 0
    fi
    if [ "$([ "_${copy_549}" != "_${source_548}" ]; echo $?)" != 0 ]; then
        ret_mirror_change20_v0="equal"
        return 0
    fi
    if [ "$(( $([ "_${copy_549}" != "_missing" ]; echo $?) || $(( $([ "_${previous_550}" == "_" ]; echo $?) && $([ "_${copy_549}" != "_${previous_550}" ]; echo $?) )) ))" != 0 ]; then
        ret_mirror_change20_v0="copy"
        return 0
    fi
    if [ "$(( $([ "_${source_548}" != "_${previous_550}" ]; echo $?) && write_back_551 ))" != 0 ]; then
        ret_mirror_change20_v0="write-back"
        return 0
    fi
    if [ "$([ "_${source_548}" != "_${previous_550}" ]; echo $?)" != 0 ]; then
        ret_mirror_change20_v0="copy edited"
        return 0
    fi
    ret_mirror_change20_v0="conflict"
    return 0
}

# reconcile_pair(state: Text, pair: Text, write_back: Bool)
reconcile_pair__21_v0() {
    local state_540="${1}"
    local pair_541="${2}"
    local write_back_542="${3}"
    local command_10
    command_10="$(/usr/bin/jq -er '.source' <<< "${pair_541}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid mirror source" 1
    fi
    local source_543="${command_10}"
    local command_11
    command_11="$(/usr/bin/jq -er '.copy' <<< "${pair_541}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid mirror copy" 1
    fi
    local copy_544="${command_11}"
    local command_12
    command_12="$(/usr/bin/jq -r '.baseline // ""' <<< "${pair_541}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid mirror baseline" 1
    fi
    local previous_545="${command_12}"
    hash_file__14_v0 "${source_543}"
    local source_hash_546="${ret_hash_file14_v0}"
    hash_file__14_v0 "${copy_544}"
    local copy_hash_547="${ret_hash_file14_v0}"
    mirror_change__20_v0 "${source_hash_546}" "${copy_hash_547}" "${previous_545}" "${write_back_542}"
    local action_552="${ret_mirror_change20_v0}"
    local next_553="${previous_545}"
    local problem_554="${action_552}"
    if [ "$([ "_${action_552}" != "_equal" ]; echo $?)" != 0 ]; then
        next_553="${source_hash_546}"
        problem_554=""
    fi
    if [ "$([ "_${action_552}" != "_copy" ]; echo $?)" != 0 ]; then
        copy_checked__19_v0 "${state_540}" "${source_543}" "${source_hash_546}" "${copy_544}" "${copy_hash_547}" 0
        local ret_copy_checked19_v0__110_12="${ret_copy_checked19_v0}"
        if [ "${ret_copy_checked19_v0__110_12}" != 0 ]; then
            next_553="${source_hash_546}"
            problem_554=""
        else
            problem_554="copy changed or could not be written"
        fi
    fi
    if [ "$([ "_${action_552}" != "_write-back" ]; echo $?)" != 0 ]; then
        copy_checked__19_v0 "${state_540}" "${copy_544}" "${copy_hash_547}" "${source_543}" "${source_hash_546}" 1
        local ret_copy_checked19_v0__118_12="${ret_copy_checked19_v0}"
        if [ "${ret_copy_checked19_v0__118_12}" != 0 ]; then
            next_553="${copy_hash_547}"
            problem_554=""
        else
            problem_554="source changed or could not be written"
        fi
    fi
    local command_13
    command_13="$(/usr/bin/jq -c --arg baseline "${next_553}" --arg problem "${problem_554}" '
        .baseline = (if $baseline == "" then null else $baseline end)
        | .problem = (if $problem == "" then null else $problem end)
    ' <<< "${pair_541}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not update mirror pair" 1
    fi
    local update_564="${command_13}"
    ret_reconcile_pair21_v0="${update_564}"
    return 0
}

# reconcile_mirror(state: Text, directory: Text, destination: Text, session: Text)
reconcile_mirror__22_v0() {
    local state_524="${1}"
    local directory_525="${2}"
    local destination_526="${3}"
    local session_527="${4}"
    local file_528="${directory_525}/session.json"
    local command_14
    command_14="$(/usr/bin/jq -r '.pairs | length' <<< "${session_527}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not count files" 1
    fi
    local count_529="${command_14}"
    local next_session_530="${session_527}"
    local command_15
    command_15="$(/usr/bin/jq -r '.writeBack' <<< "${session_527}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read mirror direction" 1
    fi
    local direction_531="${command_15}"
    local index_532=0
    while :
    do
        test "${index_532}" -lt "${count_529}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            break
        fi
        file_exists__3_v0 "${directory_525}/stop"
        local ret_file_exists3_v0__140_12="${ret_file_exists3_v0}"
        if [ "${ret_file_exists3_v0__140_12}" != 0 ]; then
            break
        fi
        directory_is_safe__18_v0 "${destination_526}"
        local ret_directory_is_safe18_v0__141_16="${ret_directory_is_safe18_v0}"
        if [ "$(( ! ret_directory_is_safe18_v0__141_16 ))" != 0 ]; then
            break
        fi
        local command_16
        command_16="$(/usr/bin/jq -c --argjson index "${index_532}" '.pairs[$index]' <<< "${next_session_530}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not read mirror pair" 1
        fi
        local pair_536="${command_16}"
        local command_17
        command_17="$(/usr/bin/jq -er '.copy' <<< "${pair_536}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid mirror copy" 1
        fi
        local copy_537="${command_17}"
        [[ "${copy_537}" == "${destination_526}/"* ]]
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Mirror copy is outside the destination" 1
        fi
        lock_sync_writes__15_v0 "${state_524}"
        reconcile_pair__21_v0 "${state_524}" "${pair_536}" "$([ "_${direction_531}" != "_true" ]; echo $?)"
        local updated_565="${ret_reconcile_pair21_v0}"
        exec 7>&-
        __status=$?
        local command_18
        command_18="$(printf '%s
' "${next_session_530}" "${updated_565}" | /usr/bin/jq -cs --argjson index "${index_532}" '
            .[1] as $pair | .[0] | .pairs[$index] = $pair
        ')"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not update mirror record" 1
        fi
        next_session_530="${command_18}"
        index_532="$(( index_532 + 1 ))"
    done
    if [ "$([ "_${next_session_530}" == "_${session_527}" ]; echo $?)" != 0 ]; then
        write_file__6_v0 "${file_528}" "${next_session_530}"
    fi
}

# mirror_worker(state: Text, directory: Text, destination: Text)
mirror_worker__23_v0() {
    local state_573="${1}"
    local directory_574="${2}"
    local destination_575="${3}"
    local worker_lock_576="${directory_574}/worker.lock"
    test ! -L "${worker_lock_576}" && exec 8>>"${worker_lock_576}" && /usr/bin/lockf -s -t 0 8
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit 1
    fi
    while :
    do
        file_exists__3_v0 "${directory_574}/stop"
        local ret_file_exists3_v0__160_12="${ret_file_exists3_v0}"
        if [ "${ret_file_exists3_v0__160_12}" != 0 ]; then
            exit 0
        fi
        test -d "${destination_575}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            exit 0
        fi
        directory_is_safe__18_v0 "${destination_575}"
        local ret_directory_is_safe18_v0__162_16="${ret_directory_is_safe18_v0}"
        if [ "$(( ! ret_directory_is_safe18_v0__162_16 ))" != 0 ]; then
            exit 1
        fi
        load_session__17_v0 "${directory_574}/session.json"
        local session_577="${ret_load_session17_v0}"
        reconcile_mirror__22_v0 "${state_573}" "${directory_574}" "${destination_575}" "${session_577}"
        /bin/sleep 1
        __status=$?
    done
}

# mirror_destination(input: Text, start: Bool)
mirror_destination__24_v0() {
    local input_486="${1}"
    local start_487="${2}"
    local command_21
    command_21="$(/bin/realpath -- "${input_486}" 2>/dev/null)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        if [ "${start_487}" != 0 ]; then
            ensure_directory__4_v0 "${input_486}"
        fi
        local command_19
        command_19="$(/usr/bin/dirname -- "${input_486}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid mirror destination" 1
        fi
        local parent_489="${command_19}"
        local command_20
        command_20="$(/usr/bin/basename -- "${input_486}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid mirror destination" 1
        fi
        local base_490="${command_20}"
        real_path__2_v0 "${parent_489}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid mirror destination: ${input_486}" 1
        fi
        local resolved_493="${ret_real_path2_v0}"
        ret_mirror_destination24_v0="${resolved_493}/${base_490}"
        return 0
    fi
    local existing_494="${command_21}"
    ret_mirror_destination24_v0="${existing_494}"
    return 0
}

# mirror_command(state: Text, args: [Text])
mirror_command__25_v0() {
    local state_478="${1}"
    local args_479=("${!2}")
    local path_480=""
    local action_481="start"
    local write_back_482=0
    local inputs_483=()
    local index_484=2
    local __length_23=("${args_479[@]}")
    while [ "$(( index_484 < ${#__length_23[@]} ))" != 0 ]; do
        local flag_485="${args_479[${index_484}]?"Index out of bounds (at src/mirror.ab:187:27)"}"
        index_484="$(( index_484 + 1 ))"
        if [ "$([ "_${flag_485}" != "_--to" ]; echo $?)" != 0 ]; then
            local __length_24=("${args_479[@]}")
            if [ "$(( $([ "_${path_480}" == "_" ]; echo $?) || $(( index_484 >= ${#__length_24[@]} )) ))" != 0 ]; then
                error__0_v0 "Specify one --to <directory>" 2
            fi
            path_480="${args_479[${index_484}]?"Index out of bounds (at src/mirror.ab:191:25)"}"
            index_484="$(( index_484 + 1 ))"
            continue
        fi
        if [ "$(( $([ "_${flag_485}" != "_--stop" ]; echo $?) || $([ "_${flag_485}" != "_--status" ]; echo $?) ))" != 0 ]; then
            if [ "$([ "_${action_481}" == "_start" ]; echo $?)" != 0 ]; then
                error__0_v0 "Use one mirror operation" 2
            fi
            action_481="${flag_485}"
            continue
        fi
        if [ "$([ "_${flag_485}" != "_--write-back" ]; echo $?)" != 0 ]; then
            write_back_482=1
            continue
        fi
        if [ "$([ "_${flag_485}" != "_--" ]; echo $?)" != 0 ]; then
            local __length_25=("${args_479[@]}")
            while [ "$(( index_484 < ${#__length_25[@]} ))" != 0 ]; do
                inputs_483+=("${args_479[${index_484}]?"Index out of bounds (at src/mirror.ab:206:33)"}")
                index_484="$(( index_484 + 1 ))"
            done
            break
        fi
        error__0_v0 "Unknown mirror option: ${flag_485}" 2
    done
    local __length_27=("${inputs_483[@]}")
    local __length_28=("${inputs_483[@]}")
    if [ "$(( $(( $([ "_${path_480}" != "_" ]; echo $?) || $(( $([ "_${action_481}" != "_start" ]; echo $?) && $(( ${#__length_27[@]} == 0 )) )) )) || $(( $([ "_${action_481}" == "_start" ]; echo $?) && $(( $(( ${#__length_28[@]} != 0 )) || write_back_482 )) )) ))" != 0 ]; then
        error__0_v0 "Usage: file-sync.sh mirror --to <directory> [--write-back] -- <file>... | mirror --to <directory> --status|--stop" 2
    fi
    mirror_destination__24_v0 "${path_480}" "$([ "_${action_481}" != "_start" ]; echo $?)"
    local destination_495="${ret_mirror_destination24_v0}"
    if [ "$([ "_${destination_495}" != "_/" ]; echo $?)" != 0 ]; then
        error__0_v0 "Choose a mirror directory below /" 2
    fi
    local command_29
    command_29="$(printf '%s' "${destination_495}" | /usr/bin/shasum -a 256 | /usr/bin/awk '{print $1}')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not identify mirror destination" 1
    fi
    local key_496="${command_29}"
    if [ "$([ "_${key_496}" != "_" ]; echo $?)" != 0 ]; then
        error__0_v0 "Could not identify mirror destination" 1
    fi
    local directory_497="${state_478}/mirror/${key_496}"
    if [ "$([ "_${action_481}" != "_start" ]; echo $?)" != 0 ]; then
        ensure_directory__4_v0 "${directory_497}"
    fi
    test -d "${directory_497}" && test ! -L "${directory_497}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "No mirror for: ${destination_495}" 1
    fi
    lock_file__5_v0 "${directory_497}/control.lock"
    load_session__17_v0 "${directory_497}/session.json"
    local session_502="${ret_load_session17_v0}"
    running__16_v0 "${directory_497}"
    local is_running_504="${ret_running16_v0}"
    if [ "$([ "_${action_481}" != "_--status" ]; echo $?)" != 0 ]; then
        /usr/bin/jq -c --argjson running "${is_running_504}" '. + {running: ($running == 1)}' <<< "${session_502}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not show mirror state" 1
        fi
        if [ "$(( ! is_running_504 ))" != 0 ]; then
            exit 1
        fi
        exit 0
    fi
    if [ "$([ "_${action_481}" != "_--stop" ]; echo $?)" != 0 ]; then
        if [ "${is_running_504}" != 0 ]; then
            : > "${directory_497}/stop"
            __status=$?
            if [ "${__status}" != 0 ]; then
                error__0_v0 "Could not request mirror stop" 1
            fi
            for (( _attempt_505=0; _attempt_505 < 50; _attempt_505++ )); do
                running__16_v0 "${directory_497}"
                local ret_running16_v0__235_24="${ret_running16_v0}"
                if [ "$(( ! ret_running16_v0__235_24 ))" != 0 ]; then
                    exit 0
                fi
                /bin/sleep 0.1
                __status=$?
done
            error__0_v0 "Mirror is still stopping: ${destination_495}" 1
        fi
        exit 0
    fi
    local sources_506=()
    for input_507 in "${inputs_483[@]}"; do
        real_path__2_v0 "${input_507}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "File not found: ${input_507}" 1
        fi
        local source_508="${ret_real_path2_v0}"
        test -f "${source_508}" && [[ "${source_508}" != "${destination_495}/"* ]]
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid mirror source: ${source_508}" 1
        fi
        sources_506+=("${source_508}")
    done
    local command_34
    command_34="$(/usr/bin/jq -nc --arg dst "${destination_495}" --argjson back "${write_back_482}" '
        {destination:$dst,writeBack:($back == 1),pairs:($ARGS.positional | unique | map({source:.,copy:($dst + .),baseline:null}))}
    ' --args -- "${sources_506[@]}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not encode mirror paths" 1
    fi
    local requested_509="${command_34}"
    if [ "${is_running_504}" != 0 ]; then
        printf '%s
' "${requested_509}" "${session_502}" | /usr/bin/jq -es '
            def settings: del(.pairs[].baseline,.pairs[].problem);
            (.[0] | settings) == (.[1] | settings)
        ' >/dev/null
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Stop the current mirror before changing its settings" 1
        fi
        printf '%s\n' "${destination_495}"
        exit 0
    fi
    local command_35
    command_35="$(printf '%s
' "${requested_509}" "${session_502}" | /usr/bin/jq -cs '
        .[1].pairs as $old | .[0] | .pairs |= map(. as $p |
        .baseline = ([$old[] | select(.source == $p.source and .copy == $p.copy) | .baseline] | last))
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not restore mirror baseline" 1
    fi
    local pending_510="${command_35}"
    local command_36
    command_36="$(/usr/bin/jq -r '.pairs | length' <<< "${pending_510}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not count files" 1
    fi
    local count_511="${command_36}"
    local pair_index_512=0
    while :
    do
        test "${pair_index_512}" -lt "${count_511}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            break
        fi
        local command_37
        command_37="$(/usr/bin/jq -c --argjson i "${pair_index_512}" '.pairs[$i]' <<< "${pending_510}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid mirror pair" 1
        fi
        local pair_513="${command_37}"
        local command_38
        command_38="$(/usr/bin/jq -er '.source' <<< "${pair_513}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid mirror source" 1
        fi
        local source_514="${command_38}"
        local command_39
        command_39="$(/usr/bin/jq -er '.copy' <<< "${pair_513}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid mirror copy" 1
        fi
        local copy_515="${command_39}"
        local command_40
        command_40="$(/usr/bin/jq -r '.baseline // ""' <<< "${pair_513}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid mirror baseline" 1
        fi
        local previous_516="${command_40}"
        hash_file__14_v0 "${copy_515}"
        local copy_hash_520="${ret_hash_file14_v0}"
        hash_file__14_v0 "${source_514}"
        local ret_hash_file14_v0__273_98="${ret_hash_file14_v0}"
        if [ "$(( $([ "_${copy_hash_520}" != "_invalid" ]; echo $?) || $(( $(( $([ "_${copy_hash_520}" == "_missing" ]; echo $?) && $([ "_${previous_516}" != "_" ]; echo $?) )) && $([ "_${copy_hash_520}" == "_${ret_hash_file14_v0__273_98}" ]; echo $?) )) ))" != 0 ]; then
            error__0_v0 "Existing copy differs; mirror was not started: ${copy_515}" 1
        fi
        pair_index_512="$(( pair_index_512 + 1 ))"
    done
    /bin/rm -f -- "${directory_497}/stop"
    __status=$?
    write_file__6_v0 "${directory_497}/session.json" "${pending_510}"
    reconcile_mirror__22_v0 "${state_478}" "${directory_497}" "${destination_495}" "${pending_510}"
    real_path__2_v0 "${args_479[0]?"Index out of bounds (at src/mirror.ab:281:35)"}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not locate file-sync.sh" 1
    fi
    local script_566="${ret_real_path2_v0}"
    (exec 9>&-; exec /usr/bin/nohup /bin/bash "${script_566}" --mirror-worker "${directory_497}" "${destination_495}") </dev/null >>"${directory_497}/worker.log" 2>&1 &
    __status=$?
    for (( _attempt_567=0; _attempt_567 < 50; _attempt_567++ )); do
        running__16_v0 "${directory_497}"
        local ret_running16_v0__284_12="${ret_running16_v0}"
        if [ "${ret_running16_v0__284_12}" != 0 ]; then
            printf '%s\n' "${destination_495}"
            exit 0
        fi
        /bin/sleep 0.1
        __status=$?
done
    error__0_v0 "Mirror worker did not start: ${directory_497}/worker.log" 1
}

# stored_targets(path: Text)
stored_targets__36_v0() {
    local path_588="${1}"
    file_exists__3_v0 "${path_588}"
    local ret_file_exists3_v0__4_12="${ret_file_exists3_v0}"
    if [ "$(( ! ret_file_exists3_v0__4_12 ))" != 0 ]; then
        ret_stored_targets36_v0="{\"version\":1,\"targets\":[]}"
        return 0
    fi
    test -f "${path_588}" && test ! -L "${path_588}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid targets file: ${path_588}" 1
    fi
    local command_41
    command_41="$(/usr/bin/jq -ces '
        if length == 1 and (.[0] | .version == 1 and (.targets | type == "array" and all(.[];
          type == "object" and (.path | type == "string" and startswith("/")) and
          (.plugin | type == "string" and test("^[a-z0-9][a-z0-9-]*\\z")) and (.url | type == "string" and startswith("https://"))
        ) and (map(.path) | length == (unique | length)) and (map(.url) | length == (unique | length))))
        then .[0] else error("Invalid file-sync registry") end
    ' -- "${path_588}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid targets file: ${path_588}" 1
    fi
    local targets_589="${command_41}"
    ret_stored_targets36_v0="${targets_589}"
    return 0
}

# canonical_file(file: Text)
canonical_file__37_v0() {
    local file_657="${1}"
    real_path__2_v0 "${file_657}">/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "File not found: ${file_657}" 1
    fi
    local path_658="${ret_real_path2_v0}"
    test -f "${path_658}" && [[ "${path_658}" == *.[mM][dD] ]]
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Expected a regular Markdown file: ${file_657}" 1
    fi
    ret_canonical_file37_v0="${path_658}"
    return 0
}

# registered_path(input: Text)
registered_path__38_v0() {
    local input_603="${1}"
    real_path__2_v0 "${input_603}">/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        [[ "${input_603}" == /* ]]
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Use the registered absolute path for a missing file" 2
        fi
        ret_registered_path38_v0="${input_603}"
        return 0
    fi
    local path_604="${ret_real_path2_v0}"
    ret_registered_path38_v0="${path_604}"
    return 0
}

# find_target(file: Text, path: Text)
find_target__39_v0() {
    local file_829="${1}"
    local path_830="${2}"
    stored_targets__36_v0 "${file_829}"
    local targets_831="${ret_stored_targets36_v0}"
    local command_42
    command_42="$(/usr/bin/jq -cer --arg path "${path_830}" '.targets[] | select(.path == $path)' <<< "${targets_831}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "File has no registered sync target: ${path_830}" 1
    fi
    local target_832="${command_42}"
    ret_find_target39_v0="${target_832}"
    return 0
}

# load_plugin(config: Text, id: Text)
load_plugin__40_v0() {
    local config_660="${1}"
    local id_661="${2}"
    LC_ALL=C; [[ "${id_661}" =~ ^[a-z0-9][a-z0-9-]*$ ]]
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid plugin ID: ${id_661}" 2
    fi
    local path_662="${config_660}/plugins/${id_661}.json"
    test -f "${path_662}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin configuration not found: ${path_662}" 1
    fi
    local command_43
    command_43="$(/usr/bin/jq -ces '
        select(length == 1) | .[0] | select(type == "object"
          and (.command | type == "string" and (startswith("/") or startswith("~/"))
          and (test("[[:cntrl:]]") | not))
          and (if has("settings") then (.settings | type == "object") else true end))
    ' -- "${path_662}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid plugin configuration: ${path_662}" 1
    fi
    local manifest_663="${command_43}"
    local command_44
    command_44="$(/usr/bin/jq -er '.command' <<< "${manifest_663}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Missing plugin command: ${id_661}" 1
    fi
    local command_664="${command_44}"
    local tool_665="${command_664}"
    [[ "${command_664}" == "~/"* ]]
    __status=$?
    if [ "${__status}" = 0 ]; then
        local command_45
        command_45="$(value="${command_664}"; printf '%s/%s' "$HOME" "${value:2}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Invalid plugin command: ${id_661}" 1
        fi
        tool_665="${command_45}"
    fi
    test -f "${tool_665}" && test -x "${tool_665}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin command is not executable: ${tool_665}" 1
    fi
    local command_46
    command_46="$(/usr/bin/jq -ce --arg tool "${tool_665}" '{command:$tool,settings:(.settings // {})}' <<< "${manifest_663}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read plugin settings: ${id_661}" 1
    fi
    local plugin_666="${command_46}"
    ret_load_plugin40_v0="${plugin_666}"
    return 0
}

# plugin_call(plugin: Text, operation: Text, url: Text)
plugin_call__41_v0() {
    local plugin_669="${1}"
    local operation_670="${2}"
    local url_671="${3}"
    local command_47
    command_47="$(/usr/bin/jq -er '.command' <<< "${plugin_669}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Missing plugin command" 1
    fi
    local tool_672="${command_47}"
    local command_48
    command_48="$(/usr/bin/jq -ce --arg op "${operation_670}" --arg url "${url_671}" '
        {version:1, operation:$op, url:$url, settings}
    ' <<< "${plugin_669}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not build plugin request" 1
    fi
    local request_673="${command_48}"
    local command_49
    command_49="$(printf '%s
' "${request_673}" | "${tool_672}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin failed: ${operation_670}" 1
    fi
    local response_674="${command_49}"
    local command_50
    command_50="$(printf '%s' "${response_674}" | /usr/bin/jq -ces '
        select(length == 1) | .[0] | select(.version == 1 and (.result | type == "object")) | .result
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid plugin response: ${operation_670}" 1
    fi
    local result_675="${command_50}"
    ret_plugin_call41_v0="${result_675}"
    return 0
}

# link_target(config: Text, id: Text, input: Text, url: Text)
link_target__42_v0() {
    local config_653="${1}"
    local id_654="${2}"
    local input_655="${3}"
    local url_656="${4}"
    canonical_file__37_v0 "${input_655}"
    local file_659="${ret_canonical_file37_v0}"
    load_plugin__40_v0 "${config_653}" "${id_654}"
    local plugin_667="${ret_load_plugin40_v0}"
    local command_51
    command_51="$(/usr/bin/jq -ner --arg url "${url_656}" '
        $url | select(test("^https://[^/[:space:][:cntrl:]]+[^[:space:][:cntrl:]]*\\z"))
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Expected a HTTPS URL: ${url_656}" 2
    fi
    local source_668="${command_51}"
    plugin_call__41_v0 "${plugin_667}" "resolve" "${source_668}"
    local resolved_676="${ret_plugin_call41_v0}"
    local command_52
    command_52="$(/usr/bin/jq -ce --arg path "${file_659}" --arg plugin "${id_654}" '
        select(.url | type == "string" and test("^https://[^/[:space:][:cntrl:]]+[^[:space:][:cntrl:]]*\\z"))
        | {$path, $plugin, url:.url}
    ' <<< "${resolved_676}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin did not return a valid HTTPS URL" 1
    fi
    local target_677="${command_52}"
    ensure_directory__4_v0 "${config_653}"
    lock_file__5_v0 "${config_653}/.targets.lock"
    local registry_678="${config_653}/targets.json"
    stored_targets__36_v0 "${registry_678}"
    local current_679="${ret_stored_targets36_v0}"
    local command_53
    command_53="$(printf '%s
' "${current_679}" "${target_677}" | /usr/bin/jq -ces '
        .[0] as $current | .[1] as $target
        | if any($current.targets[]; . == $target) then $current
          elif any($current.targets[]; .path == $target.path or .url == $target.url) then error("File or URL already registered")
          else $current | .targets += [$target] end
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not register: ${file_659}" 1
    fi
    local updated_680="${command_53}"
    if [ "$([ "_${updated_680}" == "_${current_679}" ]; echo $?)" != 0 ]; then
        write_file__6_v0 "${registry_678}" "${updated_680}"
    fi
    printf '%s\n' "${file_659}"
}

# unlink_target(config: Text, input: Text)
unlink_target__43_v0() {
    local config_601="${1}"
    local input_602="${2}"
    registered_path__38_v0 "${input_602}"
    local path_605="${ret_registered_path38_v0}"
    ensure_directory__4_v0 "${config_601}"
    lock_file__5_v0 "${config_601}/.targets.lock"
    local registry_606="${config_601}/targets.json"
    stored_targets__36_v0 "${registry_606}"
    local current_607="${ret_stored_targets36_v0}"
    local command_54
    command_54="$(/usr/bin/jq -ce --arg path "${path_605}" '
        if any(.targets[]; .path == $path) then .targets |= map(select(.path != $path))
        else error("File has no registered sync target") end
    ' <<< "${current_607}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not unlink: ${path_605}" 1
    fi
    local updated_608="${command_54}"
    write_file__6_v0 "${registry_606}" "${updated_608}"
    printf '%s\n' "${path_605}"
}

# list_targets(config: Text, as_json: Bool)
list_targets__44_v0() {
    local config_586="${1}"
    local as_json_587="${2}"
    stored_targets__36_v0 "${config_586}/targets.json"
    local current_590="${ret_stored_targets36_v0}"
    if [ "${as_json_587}" != 0 ]; then
        /usr/bin/jq -c '{targets:(.targets | sort_by(.path))}' <<< "${current_590}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not list targets" 1
        fi
    else
        /usr/bin/jq -r '.targets | sort_by(.path) | .[] | [.path,.plugin,.url] | @tsv' <<< "${current_590}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not list targets" 1
        fi
    fi
}

# local_document(path: Text)
local_document__59_v0() {
    local path_837="${1}"
    local command_55
    command_55="$(/usr/bin/jq -nce --rawfile raw "${path_837}" '
      def document: capture("^# (?<title>[^\r\n]+)(?:\r?\n|\\z)(?<body>[\\s\\S]*)\\z");
      (if ($raw | test("^---\r?\n")) then $raw | capture("^(?<front>---\r?\n(?:[^\n]*\n)*?---(?:\r?\n|\\z))(?<doc>[\\s\\S]*)\\z")
       else {front:"",doc:$raw} end) as $split
      | ($split.doc | sub("^(?:\r?\n)*"; "") | document) + {front:$split.front,raw:$raw}
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Markdown must have an initial # heading: ${path_837}" 1
    fi
    local result_838="${command_55}"
    if [ "$([ "_${result_838}" != "_" ]; echo $?)" != 0 ]; then
        error__0_v0 "Markdown must have an initial # heading: ${path_837}" 1
    fi
    ret_local_document59_v0="${result_838}"
    return 0
}

# write_markdown(path: Text, value: Text)
write_markdown__60_v0() {
    local path_877="${1}"
    local value_878="${2}"
    local command_56
    command_56="$(/usr/bin/stat -f "%Lp" -- "${path_877}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read permissions: ${path_877}" 1
    fi
    local mode_879="${command_56}"
    local command_57
    command_57="$(/usr/bin/mktemp "${path_877}.XXXXXX")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not stage: ${path_877}" 1
    fi
    local temp_880="${command_57}"
    printf '%s' "${value_878}" | /usr/bin/jq -ej '.' > "${temp_880}" &&
        /bin/chmod "${mode_879}" "${temp_880}" && /bin/mv -f -h -- "${temp_880}" "${path_877}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        /bin/rm -f -- "${temp_880}"
        __status=$?
        error__0_v0 "Could not save: ${path_877}" 1
    fi
}

# state_records(path: Text)
state_records__61_v0() {
    local path_851="${1}"
    file_exists__3_v0 "${path_851}"
    local ret_file_exists3_v0__27_12="${ret_file_exists3_v0}"
    if [ "$(( ! ret_file_exists3_v0__27_12 ))" != 0 ]; then
        ret_state_records61_v0="[]"
        return 0
    fi
    test -f "${path_851}" && test ! -L "${path_851}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid sync record: ${path_851}" 1
    fi
    local command_58
    command_58="$(/usr/bin/jq -ces 'select(length == 1) | .[0] | select(type == "array" and all(.[]; type == "object" and (.target | type == "object") and (.baseline.title | type == "string") and (.baseline.body | type == "string")))' -- "${path_851}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid sync record: ${path_851}" 1
    fi
    local result_852="${command_58}"
    ret_state_records61_v0="${result_852}"
    return 0
}

# record_sync(state: Text, target: Text, baseline: Text)
record_sync__62_v0() {
    local state_865="${1}"
    local target_866="${2}"
    local baseline_867="${3}"
    local file_868="${state_865}/state.json"
    state_records__61_v0 "${file_868}"
    local current_869="${ret_state_records61_v0}"
    local command_59
    command_59="$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read the clock" 1
    fi
    local now_870="${command_59}"
    local command_60
    command_60="$(printf '%s
' "${current_869}" "${target_866}" "${baseline_867}" | /usr/bin/jq -cs --arg now "${now_870}" '
        .[1] as $target | .[2] as $baseline
        | (.[0] | map(select(.target != $target))) + [{$target,$baseline,syncedAt:$now}]
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not update sync record" 1
    fi
    local updated_871="${command_60}"
    write_file__6_v0 "${file_868}" "${updated_871}"
}

# normalized(doc: Text)
normalized__63_v0() {
    local doc_845="${1}"
    local command_61
    command_61="$(printf '%s' "${doc_845}" | /usr/bin/jq -ce '
        {title, body:(.body | gsub("\r\n"; "\n") | rtrimstr("\n"))}
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read Markdown" 1
    fi
    local payload_846="${command_61}"
    ret_normalized63_v0="${payload_846}"
    return 0
}

# read_remote(plugin: Text, url: Text)
read_remote__64_v0() {
    local plugin_840="${1}"
    local url_841="${2}"
    plugin_call__41_v0 "${plugin_840}" "read" "${url_841}"
    local response_842="${ret_plugin_call41_v0}"
    local command_62
    command_62="$(/usr/bin/jq -ce '
        select((.title | type == "string" and test("^[^\r\n\u0000]+\\z"))
          and (.body | type == "string" and (contains("\u0000") | not)))
        | {title,body}
    ' <<< "${response_842}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Plugin did not return a Markdown title and body" 1
    fi
    local document_843="${command_62}"
    ret_read_remote64_v0="${document_843}"
    return 0
}

# diff_document(before: Text, after: Text, before_label: Text, after_label: Text)
diff_document__65_v0() {
    local before_861="${1}"
    local after_862="${2}"
    local before_label_863="${3}"
    local after_label_864="${4}"
    # jq writes the Markdown to diff through pipes, preserving escaping in JSON.
    /usr/bin/diff -u -L "${before_label_863}" -L "${after_label_864}"         <(printf '%s' "${before_861}" | /usr/bin/jq -r '"# " + .title + "\n" + .body')         <(printf '%s' "${after_862}" | /usr/bin/jq -r '"# " + .title + "\n" + .body')
    __status=$?
    if [ "${__status}" != 0 ]; then
        if [ "$(( __status != 1 ))" != 0 ]; then
            error__0_v0 "Could not compare documents" 1
        fi
    fi
}

# saved_baseline(state: Text, target: Text)
saved_baseline__66_v0() {
    local state_849="${1}"
    local target_850="${2}"
    state_records__61_v0 "${state_849}/state.json"
    local current_853="${ret_state_records61_v0}"
    local command_63
    command_63="$(printf '%s
' "${current_853}" "${target_850}" | /usr/bin/jq -cs '.[1] as $target | [.[0][] | select(.target == $target) | .baseline] | last')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read the comparison baseline" 1
    fi
    local value_854="${command_63}"
    ret_saved_baseline66_v0="${value_854}"
    return 0
}

# compare_status(local: Text, remote: Text, baseline: Text)
compare_status__67_v0() {
    local local_856="${1}"
    local remote_857="${2}"
    local baseline_858="${3}"
    local command_64
    command_64="$(printf '%s
' "${local_856}" "${remote_857}" "${baseline_858}" | /usr/bin/jq -rs '
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
    local result_859="${command_64}"
    ret_compare_status67_v0="${result_859}"
    return 0
}

# sync_document(config: Text, state: Text, action: Text, input: Text, option: Bool)
sync_document__68_v0() {
    local config_823="${1}"
    local state_824="${2}"
    local action_825="${3}"
    local input_826="${4}"
    local option_827="${5}"
    canonical_file__37_v0 "${input_826}"
    local path_828="${ret_canonical_file37_v0}"
    if [ "$([ "_${action_825}" == "_status" ]; echo $?)" != 0 ]; then
        ensure_directory__4_v0 "${config_823}"
        lock_file__5_v0 "${config_823}/.targets.lock"
    fi
    find_target__39_v0 "${config_823}/targets.json" "${path_828}"
    local target_833="${ret_find_target39_v0}"
    local command_65
    command_65="$(/usr/bin/jq -er '.url' <<< "${target_833}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Target URL missing" 1
    fi
    local url_834="${command_65}"
    local command_66
    command_66="$(/usr/bin/jq -er '.plugin' <<< "${target_833}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Target plugin missing" 1
    fi
    local id_835="${command_66}"
    load_plugin__40_v0 "${config_823}" "${id_835}"
    local plugin_836="${ret_load_plugin40_v0}"
    local_document__59_v0 "${path_828}"
    local body_839="${ret_local_document59_v0}"
    read_remote__64_v0 "${plugin_836}" "${url_834}"
    local response_844="${ret_read_remote64_v0}"
    normalized__63_v0 "${body_839}"
    local local_847="${ret_normalized63_v0}"
    normalized__63_v0 "${response_844}"
    local remote_848="${ret_normalized63_v0}"
    saved_baseline__66_v0 "${state_824}" "${target_833}"
    local baseline_855="${ret_saved_baseline66_v0}"
    compare_status__67_v0 "${local_847}" "${remote_848}" "${baseline_855}"
    local change_860="${ret_compare_status67_v0}"
    if [ "$([ "_${action_825}" != "_status" ]; echo $?)" != 0 ]; then
        printf '%s\n' "${change_860}"
        if [ "$(( option_827 && $([ "_${change_860}" == "_equal" ]; echo $?) ))" != 0 ]; then
            if [ "$([ "_${baseline_855}" != "_null" ]; echo $?)" != 0 ]; then
                diff_document__65_v0 "${local_847}" "${remote_848}" "local" "remote"
            else
                diff_document__65_v0 "${baseline_855}" "${local_847}" "last sync" "local"
                diff_document__65_v0 "${baseline_855}" "${remote_848}" "last sync" "remote"
            fi
        fi
        exit 0
    fi
    ensure_directory__4_v0 "${state_824}"
    if [ "$([ "_${change_860}" != "_equal" ]; echo $?)" != 0 ]; then
        lock_sync_writes__15_v0 "${state_824}"
        record_sync__62_v0 "${state_824}" "${target_833}" "${local_847}"
        echo "equal"
        exit 0
    fi
    if [ "$([ "_${action_825}" != "_push" ]; echo $?)" != 0 ]; then
        diff_document__65_v0 "${remote_848}" "${local_847}" "remote" "proposed remote"
        printf '%s\n' "${url_834}"
        error__0_v0 "Apply the displayed change at the sync target, then run push again to record the match" 1
    fi
    diff_document__65_v0 "${local_847}" "${remote_848}" "local" "proposed local"
    if [ "$(( $([ "_${change_860}" == "_remote-changed" ]; echo $?) && $(( ! option_827 )) ))" != 0 ]; then
        error__0_v0 "Use --overwrite to select the remote content explicitly" 1
    fi
    confirm__7_v0 "Apply this change to ${path_828}?"
    lock_sync_writes__15_v0 "${state_824}"
    local_document__59_v0 "${path_828}"
    local current_873="${ret_local_document59_v0}"
    read_remote__64_v0 "${plugin_836}" "${url_834}"
    local current_remote_874="${ret_read_remote64_v0}"
    if [ "$(( $([ "_${current_873}" == "_${body_839}" ]; echo $?) || $([ "_${current_remote_874}" == "_${response_844}" ]; echo $?) ))" != 0 ]; then
        error__0_v0 "Contents changed; review the new diff before applying" 1
    fi
    ensure_directory__4_v0 "${state_824}/backup"
    local command_67
    command_67="$(/usr/bin/mktemp "${state_824}/backup/document.XXXXXX")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not stage backup" 1
    fi
    local backup_875="${command_67}"
    /bin/cp -- "${path_828}" "${backup_875}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not save backup" 1
    fi
    local command_68
    command_68="$(printf '%s
' "${body_839}" "${response_844}" | /usr/bin/jq -cs '
        (.[0].front | if . == "" or endswith("\n") then . else . + "\n" end) + "# " + .[1].title + "\n" + .[1].body
    ')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not render Markdown" 1
    fi
    local updated_876="${command_68}"
    write_markdown__60_v0 "${path_828}" "${updated_876}"
    local_document__59_v0 "${path_828}"
    local ret_local_document59_v0__144_30="${ret_local_document59_v0}"
    normalized__63_v0 "${ret_local_document59_v0__144_30}"
    local saved_881="${ret_normalized63_v0}"
    if [ "$([ "_${saved_881}" == "_${remote_848}" ]; echo $?)" != 0 ]; then
        error__0_v0 "Saved Markdown does not match the sync target; backup: ${backup_875}" 1
    fi
    record_sync__62_v0 "${state_824}" "${target_833}" "${remote_848}"
    printf '%s\n' "${path_828}"
}

# usage()
usage__70_v0() {
    echo "Usage: file-sync link <file> <url> --plugin <id> | unlink <file> | list [--json]"
    echo "       file-sync status <file> [--diff] | pull <file> [--overwrite] | push <file> [--overwrite]"
    echo "       file-sync mirror --to <directory> [--write-back] -- <file>..."
}

typeset -r args_0=("$0" "$@")
umask 077
__status=$?
env_or__1_v0 "HOME" ""
home_7="${ret_env_or1_v0}"
if [ "$([ "_${home_7}" != "_" ]; echo $?)" != 0 ]; then
    error__0_v0 "HOME is required" 1
fi
env_or__1_v0 "FILE_SYNC_CONFIG_HOME" "${home_7}/.config/file-sync"
config_12="${ret_env_or1_v0}"
env_or__1_v0 "FILE_SYNC_STATE_HOME" "${home_7}/.local/state/file-sync"
state_13="${ret_env_or1_v0}"
__length_70=("${args_0[@]}")
if [ "$(( ${#__length_70[@]} == 1 ))" != 0 ]; then
    error__0_v0 "Expected a file-sync command; use --help" 2
fi
action_14="${args_0[1]?"Index out of bounds (at src/main.ab:19:25)"}"
if [ "$([ "_${action_14}" != "_mirror" ]; echo $?)" != 0 ]; then
    mirror_command__25_v0 "${state_13}" args_0[@]
    exit 0
fi
if [ "$([ "_${action_14}" != "_--mirror-worker" ]; echo $?)" != 0 ]; then
    __length_71=("${args_0[@]}")
    if [ "$(( ${#__length_71[@]} != 4 ))" != 0 ]; then
        exit 2
    fi
    mirror_worker__23_v0 "${state_13}" "${args_0[2]?"Index out of bounds (at src/main.ab:26:35)"}" "${args_0[3]?"Index out of bounds (at src/main.ab:26:44)"}"
    exit 0
fi
if [ "$(( $([ "_${action_14}" != "_--help" ]; echo $?) || $([ "_${action_14}" != "_-h" ]; echo $?) ))" != 0 ]; then
    usage__70_v0 
    exit 0
fi
if [ "$([ "_${action_14}" != "_list" ]; echo $?)" != 0 ]; then
    as_json_578=0
    __length_72=("${args_0[@]}")
    if [ "$(( ${#__length_72[@]} == 3 ))" != 0 ]; then
        as_json_578="$([ "_${args_0[2]?"Index out of bounds (at src/main.ab:35:44)"}" != "_--json" ]; echo $?)"
    fi
    __length_73=("${args_0[@]}")
    __length_74=("${args_0[@]}")
    if [ "$(( $(( ${#__length_73[@]} > 3 )) || $(( $(( ${#__length_74[@]} == 3 )) && $(( ! as_json_578 )) )) ))" != 0 ]; then
        error__0_v0 "Usage: file-sync list [--json]" 2
    fi
    list_targets__44_v0 "${config_12}" "${as_json_578}"
    exit 0
fi
if [ "$([ "_${action_14}" != "_unlink" ]; echo $?)" != 0 ]; then
    __length_75=("${args_0[@]}")
    if [ "$(( ${#__length_75[@]} != 3 ))" != 0 ]; then
        error__0_v0 "Usage: file-sync unlink <file>" 2
    fi
    unlink_target__43_v0 "${config_12}" "${args_0[2]?"Index out of bounds (at src/main.ab:42:36)"}"
    exit 0
fi
if [ "$([ "_${action_14}" != "_link" ]; echo $?)" != 0 ]; then
    __length_76=("${args_0[@]}")
    if [ "$(( $(( ${#__length_76[@]} != 6 )) || $([ "_${args_0[4]?"Index out of bounds (at src/main.ab:47:35)"}" == "_--plugin" ]; echo $?) ))" != 0 ]; then
        error__0_v0 "Usage: file-sync link <file> <url> --plugin <id>" 2
    fi
    link_target__42_v0 "${config_12}" "${args_0[5]?"Index out of bounds (at src/main.ab:50:34)"}" "${args_0[2]?"Index out of bounds (at src/main.ab:50:43)"}" "${args_0[3]?"Index out of bounds (at src/main.ab:50:52)"}"
    exit 0
fi
if [ "$([ "_${action_14}" != "_watch" ]; echo $?)" != 0 ]; then
    error__0_v0 "External watch is unavailable; use mirror for local files" 1
fi
if [ "$(( $(( $([ "_${action_14}" != "_status" ]; echo $?) || $([ "_${action_14}" != "_push" ]; echo $?) )) || $([ "_${action_14}" != "_pull" ]; echo $?) ))" != 0 ]; then
    option_681=0
    flag_682="--overwrite"
    if [ "$([ "_${action_14}" != "_status" ]; echo $?)" != 0 ]; then
        flag_682="--diff"
    fi
    __length_77=("${args_0[@]}")
    if [ "$(( ${#__length_77[@]} == 4 ))" != 0 ]; then
        option_681="$([ "_${args_0[3]?"Index out of bounds (at src/main.ab:58:43)"}" != "_${flag_682}" ]; echo $?)"
    fi
    __length_78=("${args_0[@]}")
    __length_79=("${args_0[@]}")
    __length_80=("${args_0[@]}")
    if [ "$(( $(( $(( ${#__length_78[@]} < 3 )) || $(( ${#__length_79[@]} > 4 )) )) || $(( $(( ${#__length_80[@]} == 4 )) && $(( ! option_681 )) )) ))" != 0 ]; then
        error__0_v0 "Usage: file-sync ${action_14} <file> [${flag_682}]" 2
    fi
    sync_document__68_v0 "${config_12}" "${state_13}" "${action_14}" "${args_0[2]?"Index out of bounds (at src/main.ab:62:51)"}" "${option_681}"
    exit 0
fi
error__0_v0 "Unknown file-sync command: ${action_14}" 2
