# Drone deploy

[drone.ioのオープンソース版](https://github.com/drone/drone)を使った、deployを便利にするスクリプト集です。
使い方を知りたい方は、[For Users](#forusers)を、自分の環境に移植したい方は[For Developpers](#fordeveloppers)を御覧ください。


# For Users

## 使い方

1. drone.ioに、deployの対象プロジェクトを追加
2. 対象プロジェクトのルートに`.drone.yml`ファイルを追加 → [詳細](#droneyml)
3. 対象プロジェクトにcommitしてpush


## .drone.yml

最低限、下記の様な内容が必要です。必要に応じて[include file](#include-file)や[ignore file](#ignore-file)を追加しましょう。

.drone.yml
```yml
image: bradrydzewski/base
git:
  depth: 1
env:
  - DEP_MASTER_HOST=[ftphost]
  - DEP_MASTER_USER=[username]
  - DEP_MASTER_PASSWORD=[password]
  - DEP_MASTER_HOST_DIR=www
deploy:
  bash:
    command: curl https://raw.githubusercontent.com/karappo/drone-deploy/master/deploy.sh | bash
```

各変数について説明します。


**image**

テストの実行などがなく、単にファイルの転送だけしたい場合は`bradrydzewski/base`を指定して下さい。

**git**

git cloneする時の引数を指定できます。`depth: 1`にしておくと、履歴情報を取得せずに最新のソースツリーの内容だけ取ってくるので動作が早くなります。特別なことをしない限り付けておくのが良いでしょう。

**deploy**

ここがシステムの起点になっています。必ず、この通りに記述して下さい。

**env**

上記スクリプト等の中で仕様する環境変数です。**`[BRANCH]`には対象とするブランチ名を大文字で代入してください。これによりブランチ毎に設定を変更できます**。

| 環境変数                    | 値                   | 説明                                      |
|:------------------------- |:-------------------- |:---------------------------------------- |
| DEP_[BRANCH]_COMMAND      | `lftp`または`rsync`   | 同期コマンド（デフォルトは`lftp`）              |
| DEP_[BRANCH]_FTPS         | `no`                 | リモート側がFTPS接続未対応の場合のみ`no`を指定。  |
| DEP_[BRANCH]_HOST         | 例：`ftp.sample.com`  | ***[required]*** 同期先リモートホストのアドレス |
| DEP_[BRANCH]_USER         |                      | ***[required]*** FTPまたはSSHのユーザ名      |
| DEP_[BRANCH]_PASSWORD     |                      | ***[required]※*** FTPまたはSSHのパスワード。 同期コマンドがrsyncかつ公開鍵で認証する場合は不要です。 |
| DEP_[BRANCH]_HOST_DIR     | 例：`www`             | ***[required]*** 同期先リモートホストの展開先。同期コマンドがrsyncの場合は絶対パスになります。 |
| DEP_[BRANCH]_INCLUDE_FILE | 例：`./.depinc.sh`    | URLでも指定可能。[デフォルト](https://raw.githubusercontent.com/karappo/drone-deploy/master/.depignore) → [詳細](#include-file) |
| DEP_[BRANCH]_IGNORE_FILE  | 例：`./.depignore`    | URLでも指定可能 → [詳細](#ignore-file)       |

## include file

同期の前後に任意の処理を挿入することができ、これらの処理をincludeファイルに記述します。

### 用途

- ローカルとリモートでDBの設定が違うので、自動的に切り替えたい
- リモートのテスト環境のみBASIC認証をかけたい

### 記述例

.depinc.sh
```sh
before_sync(){
  # 同期前に実行したい処理
}
after_sync(){
  # 同期後に実行したい処理
}
```

例えば、プロジェクトのルートに上記のファイルを設置した場合は、次のように指定します。

.drone.yml
```yml
env:
  - DEP_MASTER_INCLUDE_FILE=./.depinc.sh
```

URLを指定することもできます。

.drone.yml
```yml
env:
  - DEP_MASTER_INCLUDE_FILE=https://raw.githubusercontent.com/karappo/drone-deploy/master/include-files/php/.depinc.sh
```

上記のファイルを指定すると、同期の前段階で下記の処理が実行されます。[詳しくはこちら](https://github.com/karappo/drone-deploy/blob/master/include-files/php/.depinc.sh)

1. `.htaccess`ファイル内の`#RM_SYNC_REMOTE ` `#RM_SYNC_[BRANCH] `を削除
2. phpファイル内の`//RM_SYNC_REMOTE ` `//RM_SYNC_[BRANCH] `を削除

例えば、Wordpressを使ったプロジェクトで下記の様に記述することができます。

wp-config.php
```php
// Database Settings　-----------

// Local

// ローカル環境でのみ有効
//DEP_REMOTE_RM /*
define('DB_NAME', 'LOCAL_DATABASE');
define('DB_USER', 'root');
define('DB_PASSWORD', 'root');
define('DB_HOST', 'localhost');
//DEP_REMOTE_RM */

// Remote

// masterブランチのデプロイ先でのみ有効
//DEP_MASTER_RM define('DB_NAME', 'PROD_DATABASE');
//DEP_MASTER_RM define('DB_USER', 'PROD_USER');
//DEP_MASTER_RM define('DB_PASSWORD', 'PROD_PASSWORD');
//DEP_MASTER_RM define('DB_HOST', 'PROD_HOST');

// testブランチのデプロイ先でのみ有効
//DEP_TEST_RM define('DB_NAME', 'TEST_DATABASE');
//DEP_TEST_RM define('DB_USER', 'TEST_USER');
//DEP_TEST_RM define('DB_PASSWORD', 'TEST_PASSWORD');
//DEP_TEST_RM define('DB_HOST', 'TEST_HOST');

// Common

define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// -----------　/ Database Settings
```

下記のように記述しておけば、testブランチの同期先のみBASIC認証をかけられます。

.htaccess
```sh
# Basic Authentication -----------
#DEP_TEST_RM <Files ~ "^\.(htaccess|htpasswd)$">
#DEP_TEST_RM deny from all
#DEP_TEST_RM </Files>
#DEP_TEST_RM AuthUserFile /home/example/www/.htpasswd
#DEP_TEST_RM AuthGroupFile /dev/null
#DEP_TEST_RM AuthName "Please enter your ID and password"
#DEP_TEST_RM AuthType Basic
#DEP_TEST_RM require valid-user
#DEP_TEST_RM order deny,allow
# ----------- / Basic Authentication
```


## ignore file

同期時に無視したいものを指定するためのファイルです。

デフォルト: `https://raw.githubusercontent.com/karappo/drone-deploy/master/.depignore`

### 記述例

.depignore
```sh
.git/
.sass-cache/
.gitignore
Procfile
README
README.*
/_assets/

# drone-deploy
.depignore
.depinc.sh
.drone.yml
```

例えば、プロジェクトのルートに上記のファイルを設置した場合は、次のように指定します。

.drone.yml
```yml
env:
  - DEP_MASTER_IGNORE_FILE=./.depignore
```

こちらもURLを指定でき、デフォルトでは下記のように指定されています。オリジナルで作成する場合は、[.depignore](https://github.com/karappo/drone-deploy/blob/master/.depignore)を参考にして下さい。

.drone.yml
```yml
env:
  - DEP_MASTER_IGNORE_FILE=https://raw.githubusercontent.com/karappo/drone-deploy/master/.depignore
```

## Errors

下記のようなエラーが出る場合は、リモートがFTPS接続できない可能性があるので、`DEP_[BRANCH]_FTPS=no`を設定して下さい。

```
[DEPLOY] - sync -> via FTPS
ftp://user:password@host.com
mirror: Fatal error: Certificate verification: Not trusted
[DEPLOY] - sync -> [ERROR]
```


# For Developpers

このスクリプト集は、droneが提供する[Deployments](https://github.com/drone/drone#deployments)トリガーの中で`deploy.sh`を読み込むことで動作します。
***プロジェクト内のスクリプトの仕様が変わると意図した動作をしないことがあるので、利用する場合はforkして、各読込先を変更してください。***
変更が必要な箇所は[こちら](https://github.com/karappo/drone-deploy/search?utf8=%E2%9C%93&q=https%3A%2F%2Fraw.githubusercontent.com%2Fkarappo%2Fdrone-deploy)で確認して下さい。