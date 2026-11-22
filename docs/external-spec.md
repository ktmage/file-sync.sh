# External specification

[日本語](external-spec.ja.md) · [README](../README.md) · [Internal specification](internal-spec.md)

## Overview

`file-sync` mirrors local files and compares local Markdown with a configured remote source. A **target** associates a local file with the HTTPS URL returned by a plugin. A **baseline** is content the command last recorded as matching on both sides.

## Prerequisites

See [runtime requirements](../README.md#requirements). Mirroring requires readable source files and a writable destination. To compare Markdown with a remote service, [configure a plugin](#plugin-interface) with access to that service.

## Features

| ID | Feature | Observable result |
| --- | --- | --- |
| F-001 | Register sync targets | Link a Markdown file to a URL, list links, or remove a link. |
| F-002 | Compare and apply Markdown changes | Inspect differences, apply a remote change locally, or apply a local change through a writable plugin. |
| F-003 | Mirror local files | Start a background mirror, check its status, or stop it. |

## Command reference

| Command | Result |
| --- | --- |
| `file-sync --help` or `file-sync -h` | Prints usage. |
| `file-sync --check` | Reports the installed Bash version and required commands. Exits with status 1 if a required dependency is unavailable. |
| `file-sync link <file> <url> --plugin <id>` | Resolves the HTTPS URL, saves the association, and prints the path. |
| `file-sync unlink <file>` | Removes the association and prints the path. The file may be missing if you pass its registered absolute path. |
| `file-sync list [--json]` | Lists registered targets by path as TSV or JSON. |
| `file-sync status <file> [--diff]` | Prints the comparison status and optional unified diffs. |
| `file-sync pull <file> [--overwrite]` | Shows the proposed local change. After confirmation it saves a backup, updates the local file, and records the new baseline. |
| `file-sync push <file> [--overwrite]` | Shows the patch and target URL. With a writable plugin, applies the change after confirmation. Records the baseline when both sides match. |
| `file-sync mirror --to <directory> [--write-back] -- <file>...` | Starts mirroring the selected local files and prints the destination path. |
| `file-sync mirror --status --to <directory>` | Prints the session as JSON, including `running` and the problem for each pair, if any. |
| `file-sync mirror --stop --to <directory>` | Requests a stop, waits for the worker to release its lock, and leaves the copies in place. |

Register an existing regular `.md` file. Each physical file path and resolved URL can appear once. Repeating the same association succeeds. TSV output from `list` contains `path`, `plugin`, and `url` in that order. JSON output has the shape `{"targets":[{"path":"/path/to/spec.md","plugin":"my-docs","url":"https://docs.example.com/spec"}]}`.

## Markdown comparison

The local file starts with a single `# ` title line. YAML front matter delimited by `---` may come before the title and is preserved on pull. Comparison uses the title and body, converts CRLF to LF in the body, and trims one trailing LF.

| Status | Condition |
| --- | --- |
| `equal` | Local and remote content match. |
| `untracked-difference` | The two sides differ and there is no saved baseline. |
| `local-changed` | Only local content differs from the baseline. |
| `remote-changed` | Only remote content differs from the baseline. |
| `conflict` | Both sides differ from the baseline and from each other. |

With `--diff`, `status` compares each side with the baseline, or compares both sides directly if there is no baseline. `pull` accepts the remote change after confirmation. For `untracked-difference`, `local-changed`, or `conflict`, it also requires `--overwrite`. If either side changes during review, the pull stops before replacing the local file. When the files already match, either `pull` or `push` records the match without rewriting the Markdown.

`push` displays the patch and URL. When the manifest sets `"writable": true`, confirmation authorizes a plugin write. For `untracked-difference`, `remote-changed` or `conflict`, also pass `--overwrite` to choose the local content. Read-only plugins retain the default preview behavior and exit with code 1 on differences. Apply the patch in the service and rerun `push`.

## Sync jobs

Create `jobs/<name>.json` in the configuration directory. Job names follow the same rules as plugin IDs.

```json
{"plugin":"github","mode":"manual","settings":{"file":"/Users/example/note.md","url":"https://github.com/example/repo/issues/1","direction":"pull"}}
```

`file-sync run <name>` runs a manual job once or starts a watch job in the background. The delay after each pass is 1–86400 seconds (default 5). `file-sync job-status <name>` reports the live lock status and log path. `file-sync stop <name>` requests a stop after the current pass. A configuration change, conflict or plugin error stops the worker. Inspect its log, resolve the problem and run it again.

The top-level plugin manifest field `"allowedModes": ["manual"]` restricts jobs to manual runs. The standard GitHub plugin uses this policy. Valid values are `manual` and `watch`; both are allowed when omitted. The CLI checks the installed manifest before starting a job and before each watch pass.

Markdown jobs take an absolute `file`, an HTTPS `url` and a `direction` of `pull` or `push`. The job can establish its baseline on matching content without a separate link. For an initial difference, link the same file and URL to inspect the diff and choose a side manually. Unattended pushes require both `writable: true` and `backgroundWrite: true` in the plugin manifest.

A plugin with `protocol: "sync"` implements one complete pass. It receives `{"version":1,"operation":"sync","settings":{...}}` on stdin and returns `{"version":1,"result":{"synced":true}}` on success. Job settings override same-named manifest settings. The bundled `local-mirror` plugin takes an array of absolute source paths in `files`, an absolute `destination` directory, and an optional `writeBack` flag (default false).

## Mirror behavior

The compatibility command `file-sync mirror` forwards its arguments to the registered `local-mirror` plugin. The plugin registers a watch job named `mirror-<SHA-256>` from the destination and starts the common job runner. The interval and flags below describe that command.

The copy path is the canonical destination followed by the source's physical absolute path. For example, `/Users/example/project/spec.md` mirrored to `/Users/example/mirror` has the copy path `/Users/example/mirror/Users/example/project/spec.md`. Keep the source files outside the destination directory.

On first start, a different existing copy blocks the mirror before any files are changed. Once running, the worker checks the files with a one-second pause between passes. It refreshes the copy when the source changes and the copy still matches the last shared content. It restores a missing copy when the source still exists. If the source goes missing, the copy stays in place and the job stops with a diagnostic in its log.

Copy-side edits propagate only with `--write-back` and when the source still matches the last shared content. A write-back saves the previous source under `backup/`. If both files diverge, the worker preserves both and reports the conflict. Resolve the differences, then start the job again. Each destination has one worker under the selected state directory. Stop it before changing its file list or direction.

## Plugin interface

A plugin is an executable provided by the user. Put its configuration in `plugins/<id>.json` under the configuration directory. An ID starts with a lowercase ASCII letter or digit and continues with lowercase ASCII letters, digits, or hyphens.

```json
{
  "command": "~/bin/my-docs-plugin",
  "settings": {"origin": "https://docs.example.com"}
}
```

`command` is a path to an executable, either absolute or beginning with `~/`. Optional `settings` is a JSON object and defaults to `{}`. Run plugins you trust. They execute with your user permissions. The executable reads one JSON object from standard input and returns one response object on standard output. Send diagnostics to standard error and return a nonzero exit status on failure.

```json
{"version":1,"operation":"read","url":"https://docs.example.com/spec","settings":{}}
```

| Operation | Successful response |
| --- | --- |
| `resolve` | `{"version":1,"result":{"url":"https://docs.example.com/spec"}}` |
| `read` | `{"version":1,"result":{"title":"Specification","body":"Markdown body"}}` |

`resolve` runs during registration and returns an HTTPS URL. `read` uses the saved URL and returns a nonempty, single-line title without the Markdown heading marker and the Markdown body as a string. The request gives the plugin the URL and its settings.

A writable plugin opts in with the boolean manifest field `writable` (default `false`). A `write` request includes `url`, `settings`, the reviewed remote snapshot in `expected`, and the proposed `document`. Both snapshots have the shape `{"title":"Heading","body":"Markdown body"}`. Verify the target, permissions and expected content before changing the service. Return `{"version":1,"result":{"written":true}}` after saving. The CLI reads the remote again and records a baseline only when the local and saved content still match.

## Exit status and data

| Exit status | Meaning |
| --- | --- |
| 0 | Success. A valid `status` comparison returns 0 for any comparison state. |
| 1 | An operation did not complete, a push needs manual application, or the requested mirror is stopped. |
| 2 | Invalid arguments. |

Diagnostics go to standard error. Configuration defaults to `~/.config/file-sync/` and includes `plugins/` and `targets.json`. State defaults to `~/.local/state/file-sync/` and holds the saved baselines, backups, and mirror sessions. Override those roots with `FILE_SYNC_CONFIG_HOME` and `FILE_SYNC_STATE_HOME` respectively. Use the same state root for a mirror's start, status, and stop commands.
