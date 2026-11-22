# file-sync.sh

![Platform: macOS](https://img.shields.io/badge/platform-macOS-41454a?logo=apple)
[![Built with Amber](https://img.shields.io/badge/built%20with-Amber-f59e0b)](https://amber-lang.com/)
[![License: MIT](https://img.shields.io/badge/license-MIT-2e7d32)](LICENSE)

[日本語](README.ja.md)

A macOS CLI for keeping copies of local files up to date and comparing local Markdown with a remote copy. Local mirroring works immediately. Remote comparisons use a plugin executable you configure.

## Requirements

- macOS with Bash 3.2 or newer and the system utilities `/usr/bin/jq`, `/usr/bin/lockf`, `/bin/realpath`, and `/usr/bin/shasum`.

The checkout includes the generated shell script. Amber is needed only to [rebuild it](#rebuild-from-source).

## Quick start

Run this from the checkout to start a mirror for a sample file. `--status` lists the source and the full path to the copy. The file remains available after `--stop`.

```sh
export PATH="$PWD/bin:$PATH"
demo=$(mktemp -d)
printf '# Example\n\nOriginal text.\n' > "$demo/spec.md"
file-sync mirror --to "$demo/mirror" -- "$demo/spec.md"
file-sync mirror --status --to "$demo/mirror"
file-sync mirror --stop --to "$demo/mirror"
```

## Install the command

Run this from the checkout to install `file-sync.sh` as the `file-sync` command.

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 file-sync.sh "$HOME/.local/bin/file-sync"
export PATH="$HOME/.local/bin:$PATH"
```

## Compare Markdown with a remote copy

[Configure a plugin](docs/external-spec.md#plugin-interface) to read from your service. With that plugin in place, link a local Markdown file to an HTTPS URL and inspect the differences.

```sh
file-sync link ./spec.md https://docs.example.com/spec --plugin my-docs
file-sync status ./spec.md --diff
file-sync pull ./spec.md
```

`pull` previews changes and asks before applying them to the local file. `push` displays a patch and the remote URL. Apply the patch in your service, then rerun `push` to record the match.

## Documentation

- [External specification](docs/external-spec.md) covers command behavior, mirror conflicts, and the plugin interface.
- [Internal specification](docs/internal-spec.md) covers the source, storage, locks, and background worker.

## Rebuild from source

Use Amber 0.6.0-alpha and run these commands from the checkout.

```sh
amber build --target bash-3.2 --no-proc bshchk src/main.ab file-sync.sh
/bin/bash -n file-sync.sh
```

## License

[MIT](LICENSE)
