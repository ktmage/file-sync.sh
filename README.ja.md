# file-sync.sh

![対応OS: macOS](https://img.shields.io/badge/platform-macOS-41454a?logo=apple)
[![Amber](https://img.shields.io/badge/built%20with-Amber-f59e0b)](https://amber-lang.com/)
[![ライセンス: MIT](https://img.shields.io/badge/license-MIT-2e7d32)](LICENSE)

[English](README.md)

ローカルファイルのコピーを最新に保ち、手元のMarkdownと同期先の差分を確認するmacOS向けCLIです。ローカルのミラーはすぐに使えます。同期先との比較には、サービスに対応するプラグインを設定します。

## 動作環境

- Bash 3.2以降と、標準コマンド`/usr/bin/jq`、`/usr/bin/lockf`、`/bin/realpath`、`/usr/bin/shasum`を備えたmacOS。

生成済みのシェルスクリプトを同梱しています。Amberが必要なのは[ソースからビルド](#ソースからビルドする)するときだけです。

## 使ってみる

リポジトリのルートで実行すると、サンプルファイルのミラーが起動します。`--status`で元ファイルとコピーの絶対パスを確認できます。`--stop`で停止してもコピーは残ります。

```sh
export PATH="$PWD/bin:$PATH"
demo=$(mktemp -d)
printf '# サンプル\n\n元の本文。\n' > "$demo/spec.md"
file-sync mirror --to "$demo/mirror" -- "$demo/spec.md"
file-sync mirror --status --to "$demo/mirror"
file-sync mirror --stop --to "$demo/mirror"
```

## コマンドをインストールする

リポジトリのルートから、`file-sync.sh`を`file-sync`という名前でコマンド置き場にコピーします。

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 file-sync.sh "$HOME/.local/bin/file-sync"
export PATH="$HOME/.local/bin:$PATH"
```

## 同期先のMarkdownと比較する

利用するサービスを読み取る[プラグインを設定](docs/external-spec.ja.md#プラグインとの通信)します。設定したらローカルのMarkdownにHTTPSのURLを関連付け、差分を確認します。

```sh
file-sync link ./spec.md https://docs.example.com/spec --plugin my-docs
file-sync status ./spec.md --diff
file-sync pull ./spec.md
```

`pull`は差分を表示し、確認を受けてローカルファイルを更新します。`push`は変更案と同期先URLを表示します。同期先で内容を反映してからもう一度`push`を実行すると、一致した内容を記録します。

## ドキュメント

- [外部仕様書](docs/external-spec.ja.md)にコマンド、ミラーの競合、プラグインとの通信を記載しています。
- [内部仕様書](docs/internal-spec.ja.md)にコードの構成、保存データ、ロック、監視プロセスを記載しています。

## ソースからビルドする

Amber 0.6.0-alphaを用意し、リポジトリのルートで実行します。

```sh
amber build --target bash-3.2 --no-proc bshchk src/main.ab file-sync.sh
/bin/bash -n file-sync.sh
```

## ライセンス

[MIT](LICENSE)
