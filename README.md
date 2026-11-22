# file-sync.sh

![Platform: macOS](https://img.shields.io/badge/platform-macOS-41454a?logo=apple)
[![Built with Amber](https://img.shields.io/badge/built%20with-Amber-f59e0b)](https://amber-lang.com/)
[![License: MIT](https://img.shields.io/badge/license-MIT-2e7d32)](LICENSE)

[日本語](README.ja.md)

Synchronize files on macOS with manual or watched jobs. GitHub and local mirror are standard plugins, maintained in independent repositories and included as Git submodules.

The CLI and local mirror plugin use Bash and standard macOS commands. Amber is only needed to [rebuild from source](#rebuild-from-source).

## Requirements

After installation, check that Bash and the commands the script needs are available on your Mac.

```sh
file-sync --check
```

When setting up a plugin for remote Markdown comparison, check the requirements for that plugin as well.

The included shell script runs on macOS with Bash 3.2 or newer and system utilities including `/usr/bin/jq`, `/usr/bin/lockf`, and `/bin/realpath`. Local mirroring uses `/usr/bin/shasum` to detect changes. Markdown comparison uses `/usr/bin/diff` to show the patch.

The included script runs without Git, GitHub CLI (`gh`), or Homebrew. Remote comparison also requires a [plugin executable](docs/external-spec.md#plugin-interface) and any tools that plugin calls.

## Quick start

Run this from the checkout in a temporary configuration. Set `mode` to `manual` to copy once with the same command.

```sh
git submodule update --init -- plugins/github plugins/local-mirror
export PATH="$PWD/bin:$PATH"
demo=$(mktemp -d)
export FILE_SYNC_CONFIG_HOME="$demo/config" FILE_SYNC_STATE_HOME="$demo/state"
mkdir -p "$demo/config/plugins" "$demo/config/jobs"
jq -n --arg command "$PWD/plugins/local-mirror/plugin.sh" '{command:$command,protocol:"sync"}' > "$demo/config/plugins/local-mirror.json"
printf 'example\n' > "$demo/note.txt"
jq -n --arg src "$demo/note.txt" --arg dst "$demo/copies" \
  '{plugin:"local-mirror",mode:"watch",settings:{files:[$src],destination:$dst}}' > "$demo/config/jobs/notes.json"
file-sync run notes
file-sync job-status notes
file-sync stop notes
```

## Install the command

Run this from the checkout to install `file-sync.sh` as the `file-sync` command.

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 file-sync.sh "$HOME/.local/bin/file-sync"
export PATH="$HOME/.local/bin:$PATH"
```

To run both standard plugins from this checkout, link their entry points and install their manifests. Company dotfiles perform this during installation.

```sh
git submodule update --init -- plugins/github plugins/local-mirror
mkdir -p "$HOME/.config/file-sync/plugins"
for name in github local-mirror; do
  mkdir -p "$HOME/.tools/file-sync-plugins/$name"
  ln -s "$PWD/plugins/$name/plugin" "$HOME/.tools/file-sync-plugins/$name/plugin"
  cp -n "plugins/$name/manifest.json" "$HOME/.config/file-sync/plugins/$name.json"
done
```

## Compare Markdown with a remote copy

[Configure a plugin](docs/external-spec.md#plugin-interface) to read from your service. With that plugin in place, link a local Markdown file to an HTTPS URL and inspect the differences.

```sh
file-sync link ./spec.md https://docs.example.com/spec --plugin my-docs
file-sync status ./spec.md --diff
file-sync pull ./spec.md
```

`pull` previews changes and asks before updating your file. `push` shows the patch and URL. With a writable plugin it asks for confirmation, applies the change and verifies the saved content. With a read-only plugin, apply the patch in the service and rerun `push` to record the match.

## Documentation

- [External specification](docs/external-spec.md) covers command behavior, mirror conflicts, and the plugin interface.
- [Internal specification](docs/internal-spec.md) covers the source, storage, locks, and background worker.

## Rebuild from source

Use Amber 0.6.0-alpha and run these commands from the checkout.

```sh
amber build --target bash-3.2 --no-proc bshchk src/main.ab file-sync.sh
(cd plugins/local-mirror && amber build --target bash-3.2 --no-proc bshchk src/main.ab plugin.sh)
/bin/bash -n file-sync.sh && /bin/bash -n plugins/local-mirror/plugin.sh
```

## License

[MIT](LICENSE)
