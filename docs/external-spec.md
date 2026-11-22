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
| F-002 | Compare and apply Markdown changes | Inspect differences, apply a remote change locally, or get a patch to apply at the remote service. |
| F-003 | Mirror local files | Start a background mirror, check its status, or stop it. |

## Command reference

| Command | Result |
| --- | --- |
| `file-sync --help` or `file-sync -h` | Prints usage. |
| `file-sync link <file> <url> --plugin <id>` | Resolves the HTTPS URL, saves the association, and prints the path. |
| `file-sync unlink <file>` | Removes the association and prints the path. The file may be missing if you pass its registered absolute path. |
| `file-sync list [--json]` | Lists registered targets by path as TSV or JSON. |
| `file-sync status <file> [--diff]` | Prints the comparison status and optional unified diffs. |
| `file-sync pull <file> [--overwrite]` | Shows the proposed local change. After confirmation it saves a backup, updates the local file, and records the new baseline. |
| `file-sync push <file>` | Prints the patch to apply remotely and the URL. If both sides are equal, records the baseline and prints `equal`. |
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

A divergent `push` leaves application of the patch to the user and exits with status 1. After applying it, rerun `push` to record the match. The CLI accepts `--overwrite` on `push` with the same preview behavior.

## Mirror behavior

The copy path is the canonical destination followed by the source's physical absolute path. For example, `/Users/example/project/spec.md` mirrored to `/Users/example/mirror` has the copy path `/Users/example/mirror/Users/example/project/spec.md`. Keep the source files outside the destination directory.

On first start, a different existing copy blocks the mirror before any files are changed. Once running, the worker checks the files with a one-second pause between passes. It refreshes the copy when the source changes and the copy still matches the last shared content. It restores a missing copy when the source still exists. If the source goes missing, the copy stays in place and `--status` reports the problem.

Copy-side edits propagate only with `--write-back` and when the source still matches the last shared content. A write-back saves the previous source under `backup/`. If both files diverge, the worker preserves both and reports the conflict. Make the files match to allow the worker to resume from that content. Each destination has one worker under the selected state directory. Stop it before changing its file list or direction.

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

## Exit status and data

| Exit status | Meaning |
| --- | --- |
| 0 | Success. A valid `status` comparison returns 0 for any comparison state. |
| 1 | An operation did not complete, a push needs manual application, or the requested mirror is stopped. |
| 2 | Invalid arguments. |

Diagnostics go to standard error. Configuration defaults to `~/.config/file-sync/` and includes `plugins/` and `targets.json`. State defaults to `~/.local/state/file-sync/` and holds the saved baselines, backups, and mirror sessions. Override those roots with `FILE_SYNC_CONFIG_HOME` and `FILE_SYNC_STATE_HOME` respectively. Use the same state root for a mirror's start, status, and stop commands.
