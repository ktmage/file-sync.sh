# Internal specification

[日本語](internal-spec.ja.md) · [README](../README.md) · [External specification](external-spec.md)

## Overview

The CLI keeps target registrations, Markdown comparison records, and local mirror sessions on the filesystem. It calls a user-provided executable for remote content and uses a background Bash process for local mirrors. [The external specification](external-spec.md#features) defines the public behavior.

## Architecture and source layout

`bin/file-sync` points to the generated `file-sync.sh`. The command modules use `io.ab` for filesystem operations.

| File | Responsibility |
| --- | --- |
| [main.ab](../src/main.ab) | Read configuration roots, validate top-level arguments, and dispatch commands. |
| [targets.ab](../src/targets.ab) | Read and update the registry, validate plugin configuration, and exchange JSON with the plugin. |
| [sync.ab](../src/sync.ab) | Parse Markdown, compare snapshots, and save backup files and baselines. |
| [mirror.ab](../src/mirror.ab) | Identify mirror sessions, start and stop the worker, and reconcile file pairs. |
| [io.ab](../src/io.ab) | Resolve paths, acquire locks, and stage file updates. |

Edit the Amber source and [rebuild the shell script](../README.md#rebuild-from-source).

## Processing

- **F-001 Register sync targets.** The CLI canonicalizes the local path and uses the configured executable to resolve the URL. It checks for duplicate paths and URLs under the registry lock and writes the registry when the association changes.
- **F-002 Compare and apply Markdown changes.** The CLI parses local Markdown and reads the plugin response. It compares the normalized title and body with the baseline for the registered target. A confirmed pull rereads both snapshots under the write lock, saves the current file as a backup, and stages the new file with the original mode. It records the baseline after confirming the saved title and body match the remote snapshot.
- **F-003 Mirror local files.** The CLI keys the session by SHA-256 of the physical destination path. It validates the source and destination pairs, reconciles them once, and launches a worker using `nohup`. Each pass hashes the files with SHA-256 and compares the hashes with the last shared hash. Before replacing a file, the worker checks the staged copy and current target again.

## Storage

| Root | Path | Contents |
| --- | --- | --- |
| Configuration | `plugins/<id>.json` | Plugin executable path and optional settings. |
| Configuration | `targets.json` | Object with `version: 1` and a `targets` array of path, plugin ID, and URL records. |
| State | `state.json` | Array of `{target, baseline, syncedAt}` records keyed by the entire target object. The baseline holds `title` and `body`. |
| State | `backup/` | Previous contents from pulls and mirror write-backs. |
| State | `mirror/<key>/session.json` | Destination, direction, and file pairs with paths, baseline hashes, and any current problem. |
| State | `mirror/<key>/worker.log` | Worker output and diagnostics. |

## Plugin process

The CLI executes the configured path directly and sends [the request object](external-spec.md#plugin-interface) on standard input. It checks that standard output contains one versioned response with a result object, then validates the fields for the operation. A nonzero plugin exit or an invalid response aborts the action.

## Concurrency and recovery

`.targets.lock` serializes mutations in one configuration root. `mirror/<key>/control.lock` serializes session commands. The worker holds `worker.lock` for its lifetime, which is how the CLI checks whether it is running. The stop command writes a `stop` marker. The worker checks for it before each pass and between pairs.

A state root's `.write.lock` serializes Markdown updates and baseline writes with mirror reconciliation. Lock acquisition waits up to 15 seconds for the registry, control, and write locks. Writes use temporary sibling files and rename. A pull saves the Markdown and the baseline in separate steps. If it stops between them, the backup remains available and the baseline stays as it was. Review the comparison before retrying.

## Configuration and permissions

[The configuration and state roots](external-spec.md#exit-status-and-data) default to directories under `HOME`. The CLI uses `umask 077` for files it creates. It copies the original mode for a pulled Markdown file and uses `cp -p` for mirror copies. Plugins inherit the current user's permissions. Mirror workers continue after the command returns and are started explicitly.

## Verification

From a clean checkout, compare the distributed script with the output of Amber 0.6.0-alpha.

```sh
amber build --target bash-3.2 --no-proc bshchk src/main.ab - | cmp - file-sync.sh
/bin/bash -n file-sync.sh
```

Use temporary configuration and state roots. Exercise the [README mirror example](../README.md#quick-start), then verify update propagation, write-back, an existing copy with different content, and stopping the worker. Use a fixture executable for `resolve` and `read` to check comparison states, pull confirmation and backups, and the push preview.
