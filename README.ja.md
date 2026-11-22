# file-sync.sh

![対応OS: macOS](https://img.shields.io/badge/platform-macOS-41454a?logo=apple)
[![Amber](https://img.shields.io/badge/built%20with-Amber-f59e0b)](https://amber-lang.com/)
[![ライセンス: MIT](https://img.shields.io/badge/license-MIT-2e7d32)](LICENSE)

[English](README.md)

同期先をプラグインで選び、ジョブごとに手動実行か監視を設定するmacOS向けCLIです。GitHubとローカルミラーは独立したリポジトリで開発し、標準プラグインとして同梱します。

本体とローカルミラーはBashとmacOS標準コマンドで動きます。Amberは[ソースからビルドする](#ソースからビルドする)ときに使います。

## 動作環境

インストール後は、次のコマンドでBashと必要なコマンドが揃っているか確認できます。

```sh
file-sync --check
```

同期先との比較を設定するときは、使うプラグインの動作環境も確認します。

同梱のシェルスクリプトは、Bash 3.2以降と`/usr/bin/jq`、`/usr/bin/lockf`、`/bin/realpath`などの標準コマンドが使えるmacOSで動作します。ミラーでは`/usr/bin/shasum`で変更を検出し、Markdownの比較では`/usr/bin/diff`で差分を出します。

同梱のスクリプトの実行にGit、GitHub CLI（`gh`）、Homebrewは不要です。同期先のMarkdownを比較する場合は、[プラグインの実行ファイル](docs/external-spec.ja.md#プラグインとの通信)と、そのプラグインが呼び出すコマンドを用意します。

## 使ってみる

リポジトリのルートで、作例専用の設定と保存先を用意します。設定の `mode` を `manual` にすると、同じコマンドで1回だけ同期します。

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

## コマンドをインストールする

リポジトリのルートから、`file-sync.sh`を`file-sync`という名前でコマンド置き場にコピーします。

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 file-sync.sh "$HOME/.local/bin/file-sync"
export PATH="$HOME/.local/bin:$PATH"
```

チェックアウトから2つの標準プラグインを配置する。会社用dotfilesはこの配置をインストール時に行う。

```sh
git submodule update --init -- plugins/github plugins/local-mirror
mkdir -p "$HOME/.config/file-sync/plugins"
for name in github local-mirror; do
  mkdir -p "$HOME/.tools/file-sync-plugins/$name"
  ln -s "$PWD/plugins/$name/plugin" "$HOME/.tools/file-sync-plugins/$name/plugin"
  cp -n "plugins/$name/manifest.json" "$HOME/.config/file-sync/plugins/$name.json"
done
```

## 同期先のMarkdownと比較する

利用するサービスを読み取る[プラグインを設定](docs/external-spec.ja.md#プラグインとの通信)します。設定したらローカルのMarkdownにHTTPSのURLを関連付け、差分を確認します。

```sh
file-sync link ./spec.md https://docs.example.com/spec --plugin my-docs
file-sync status ./spec.md --diff
file-sync pull ./spec.md
```

`pull`は確認後に手元のファイルを更新します。`push`は差分とURLを表示します。書き込み対応のプラグインでは、確認後に同期先へ反映し、保存された内容を照合します。読み取り専用のプラグインでは、表示された差分を同期先で適用してから再度`push`で一致を記録します。

## ドキュメント

- [外部仕様書](docs/external-spec.ja.md)にコマンド、ミラーの競合、プラグインとの通信を記載しています。
- [内部仕様書](docs/internal-spec.ja.md)にコードの構成、保存データ、ロック、監視プロセスを記載しています。

## ソースからビルドする

Amber 0.6.0-alphaを用意し、リポジトリのルートで実行します。

```sh
amber build --target bash-3.2 --no-proc bshchk src/main.ab file-sync.sh
(cd plugins/local-mirror && amber build --target bash-3.2 --no-proc bshchk src/main.ab plugin.sh)
/bin/bash -n file-sync.sh && /bin/bash -n plugins/local-mirror/plugin.sh
```

## ライセンス

[MIT](LICENSE)
