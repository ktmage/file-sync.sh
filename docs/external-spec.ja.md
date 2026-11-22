# 外部仕様書

[English](external-spec.md) · [README](../README.ja.md) · [内部仕様書](internal-spec.ja.md)

## 概要

`file-sync`はローカルファイルをミラーし、手元のMarkdownと同期先を比較します。同期先とは、ローカルファイルに関連付けたHTTPSのURLです。比較基準には、両側で最後に一致を記録した内容を使います。

## 前提と制約

[動作環境](../README.ja.md#動作環境)を参照してください。ミラーには元ファイルの読み取り権限とコピー先への書き込み権限が必要です。Markdownを比較するときは、同期先にアクセスできる[プラグインを設定](#プラグインとの通信)します。

## 機能一覧

| ID | 機能 | 結果 |
| --- | --- | --- |
| F-001 | 同期先の登録 | MarkdownファイルとURLを関連付け、登録内容を一覧表示または解除できます。 |
| F-002 | Markdownの比較と反映 | 差分の確認、リモートの変更の取り込み、書き込み対応プラグインによる同期先の更新ができます。 |
| F-003 | ローカルファイルのミラー | ミラーの起動、状態確認、停止ができます。 |

## コマンド

| コマンド | 結果 |
| --- | --- |
| `file-sync --help` または `file-sync -h` | 使い方を表示します。 |
| `file-sync --check` | Bashのバージョンと必要なコマンドを確認する。必須の依存が揃っていなければ終了コード1を返す。 |
| `file-sync link <file> <url> --plugin <id>` | プラグインが解決したHTTPSのURLを登録し、ファイルのパスを表示します。 |
| `file-sync unlink <file>` | 登録を解除してパスを表示します。元ファイルがなければ、登録時の絶対パスを指定します。 |
| `file-sync list [--json]` | 登録内容をパス順にTSVまたはJSONで表示します。 |
| `file-sync status <file> [--diff]` | 比較結果を表示します。`--diff`を指定するとunified diffも表示します。 |
| `file-sync pull <file> [--overwrite]` | 手元に適用する差分を表示します。確認後にバックアップを作り、ファイルと比較基準を更新します。 |
| `file-sync push <file> [--overwrite]` | 差分と同期先URLを表示します。書き込み対応プラグインでは確認後に反映し、両側が一致すると比較基準を記録します。 |
| `file-sync mirror --to <directory> [--write-back] -- <file>...` | 指定ファイルのミラーを起動し、コピー先ディレクトリの絶対パスを表示します。 |
| `file-sync mirror --status --to <directory>` | 稼働中かどうかと、ファイルごとの問題をJSONで表示します。 |
| `file-sync mirror --stop --to <directory>` | 停止を要求し、監視プロセスがロックを解放するまで待ちます。コピーは残ります。 |

登録できるのは実体がある`.md`ファイルです。同じ実パスや解決後のURLを複数の登録に使えません。同じ組み合わせの再登録は成功します。`list`のTSVは`path`、`plugin`、`url`の順です。JSONの形式は`{"targets":[{"path":"/path/to/spec.md","plugin":"my-docs","url":"https://docs.example.com/spec"}]}`です。

## Markdownの比較

ローカルの文書は`# `の1行見出しから始めます。`---`で囲んだYAMLフロントマターを見出しの前に置けます。`pull`で反映する際もフロントマターは保ちます。比較には見出しと本文を使います。本文のCRLFをLFにそろえ、末尾のLFを1つ除いて比較します。

| 状態 | 条件 |
| --- | --- |
| `equal` | 手元と同期先の内容が一致する。 |
| `untracked-difference` | 内容が異なり、保存済みの比較基準がない。 |
| `local-changed` | 手元の内容だけが比較基準から変わった。 |
| `remote-changed` | 同期先の内容だけが比較基準から変わった。 |
| `conflict` | 両側が比較基準から変わり、現在の内容も異なる。 |

`status --diff`は両側をそれぞれ比較基準と照合します。基準がなければ両側を直接比較します。`pull`は確認後に変更を取り込みます。`untracked-difference`、`local-changed`、`conflict`では`--overwrite`も必要です。確認中にどちらかが変わった場合は、手元のファイルを置き換える前に停止します。すでに一致していれば、`pull`と`push`はいずれもMarkdownを更新せずに一致を記録します。

`push`は差分とURLを表示します。設定に`"writable": true`があれば、端末で確認した後、プラグインに更新を依頼します。比較結果が`untracked-difference`、`remote-changed`、`conflict`の場合は、手元の内容を選ぶ`--overwrite`も必要です。既定の読み取り専用設定では差分を表示して終了コード1を返すので、同期先で適用してから再度`push`します。

## 同期ジョブ

`~/.config/file-sync/jobs/<名前>.json` にプラグインと実行方法を設定します。ジョブ名はプラグインIDと同じ文字を使えます。

```json
{"plugin":"github","mode":"manual","settings":{"file":"/Users/example/note.md","url":"https://github.com/example/repo/issues/1","direction":"pull"}}
```

`file-sync run <名前>` は `manual` なら1回実行し、`watch` ならバックグラウンドで繰り返します。各回の終了後に待つ秒数は1〜86400、既定は5です。`file-sync job-status <名前>` は実際の稼働状態とログのパスを返します。`file-sync stop <名前>` は処理中の同期が終わってから停止します。設定変更、競合、プラグインの失敗で監視は止まります。ログを読んで解消してから再実行します。

プラグイン設定の最上位に `"allowedModes": ["manual"]` を指定すると、そのプラグインのジョブは手動実行に限られます。GitHub標準プラグインはこの設定を使います。指定できる値は `manual` と `watch` で、省略時は両方を許可します。CLIはジョブ設定の読み込み時に判定し、監視中も各回の同期前に再確認します。

Markdownプラグインは `file`・`url`・`direction`（`pull` または `push`）を使い、ジョブだけで同期できます。初回は両側の一致を確認して比較基準を作ります。初回に差分がある場合は同じURLを `link` して差分を確認し、手動で内容を選びます。監視時のpushを許すにはプラグイン設定に `writable: true` と `backgroundWrite: true` の両方が必要です。

`protocol: "sync"` のプラグインは1回の同期を実装します。CLIは標準入力に `{"version":1,"operation":"sync","settings":{...}}` を送り、成功時に `{"version":1,"result":{"synced":true}}` を受け取ります。設定はプラグインの `settings` にジョブの `settings` をキー単位で重ねます。同梱の `local-mirror` は `files`（絶対パスの配列）と `destination`（コピー先の絶対パス）を受け取り、`writeBack` は既定で `false` です。

## ミラーの動作

従来の `file-sync mirror` は登録済みの `local-mirror` プラグインに引数を渡します。プラグインはコピー先から決めた `mirror-<SHA-256>` という名前で監視ジョブを登録し、同じジョブ実行処理を呼びます。以下の間隔とオプションは互換コマンドのものです。

コピーのパスは、コピー先のディレクトリに元ファイルの実パスをつないだものです。たとえば`/Users/example/project/spec.md`を`/Users/example/mirror`にミラーすると、コピーは`/Users/example/mirror/Users/example/project/spec.md`になります。元ファイルはコピー先の外に置きます。

初回の起動時に内容の異なるコピーが見つかった場合は、ファイルを変更する前に停止します。監視プロセスは1巡ごとに1秒待機します。コピーが最後に一致した内容のままで、元ファイルが変わった場合はコピーを更新します。元ファイルがあれば、削除されたコピーも作り直します。元ファイルがなくなった場合、コピーを保ち、ジョブのログに理由を残して停止します。

`--write-back`を有効にしていて、元ファイルが最後に一致した内容のままであれば、コピー側の編集を元に反映します。反映前の元ファイルは`backup/`に保存します。両側が異なる内容に変わると、両方を保持して競合を表示します。両側を同じ内容にそろえて再実行すると監視を再開します。保存先とコピー先の組み合わせごとに監視プロセスは1つです。対象ファイルや反映方向を変えるときは、一度停止します。

## プラグインとの通信

プラグインは利用者が用意する実行ファイルです。設定ディレクトリの`plugins/<id>.json`に設定を置きます。IDはASCIIの小文字か数字で始まり、続けて小文字、数字、ハイフンを使えます。

```json
{
  "command": "~/bin/my-docs-plugin",
  "settings": {"origin": "https://docs.example.com"}
}
```

`command`には絶対パスか`~/`で始まる実行ファイルのパスを指定します。`settings`は任意のJSONオブジェクトで、省略時は`{}`です。プラグインは利用者と同じ権限で動くため、信頼できるものを設定してください。標準入力からJSONを1件受け取り、標準出力へJSONを1件返します。診断は標準エラーに出し、処理に失敗したときは非ゼロで終了します。

```json
{"version":1,"operation":"read","url":"https://docs.example.com/spec","settings":{}}
```

| 操作 | 成功時の応答 |
| --- | --- |
| `resolve` | `{"version":1,"result":{"url":"https://docs.example.com/spec"}}` |
| `read` | `{"version":1,"result":{"title":"仕様書","body":"Markdownの本文"}}` |

登録時は`resolve`を呼び出してHTTPSのURLを受け取ります。比較時の`read`には登録済みのURLを渡します。応答の`title`は見出し記号を含まない空でない1行の文字列、`body`はMarkdownの本文です。リクエストにはURLとプラグインの設定を含めます。

書き込み対応のプラグインは、設定に真偽値の `writable` を追加します。既定値は `false` です。`write` の要求には `url`、`settings`、差分確認時の同期先の内容 `expected`、更新する内容 `document` が入ります。本文の形式はどちらも `{"title":"見出し","body":"本文"}` です。プラグインは対象と権限を確認し、`expected` から変わっていれば中断します。保存後は `{"version":1,"result":{"written":true}}` を返します。CLIは `read` で読み直し、ローカルと同期先の一致を確認して比較基準を更新します。

## 終了コードとデータ

| 終了コード | 意味 |
| --- | --- |
| 0 | 成功。`status`は正常に比較できれば、差分の有無に関わらず0を返します。 |
| 1 | 処理エラー、同期先で適用すべき差分あり、またはミラーが停止中。 |
| 2 | 引数が不正。 |

診断は標準エラーに出力します。既定では設定を`~/.config/file-sync/`、比較基準、バックアップ、ミラーの記録を`~/.local/state/file-sync/`に置きます。前者は`FILE_SYNC_CONFIG_HOME`、後者は`FILE_SYNC_STATE_HOME`で変更できます。ミラーの起動、状態確認、停止には同じ保存先を使います。
