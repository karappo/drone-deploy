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
env:
  - DEP_HOST=<ftphost>
  - DEP_USER=<username>
  - DEP_PASSWORD=<password>
  - DEP_HOST_DIR=www
deploy:
  bash:
    command: curl https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/deploy.sh | bash
```

各変数について説明します。


**image**

テストの実行などがなく、単にファイルの転送だけしたい場合は`bradrydzewski/base`を指定して下さい。

**deploy**

ここがシステムの起点になっています。必ず、この通りに記述して下さい。

**env**

上記スクリプト等の中で仕様する環境変数です。

| 環境変数           | 値                   | 説明                                      |
|:---------------- |:-------------------- |:---------------------------------------- |
| DEP_COMMAND      | `lftp`または`rsync`   | 同期コマンド（デフォルトは`lftp`）              |
| DEP_HOST         | 例：`ftp.sample.com`  | ***[required]*** 同期先リモートホストのアドレス |
| DEP_USER         |                      | ***[required]*** FTPまたはSSHのユーザ名      |
| DEP_PASSWORD     |                      | ***[required]*** FTPまたはSSHのパスワード     |
| DEP_HOST_DIR     | 例：`www`             | ***[required]*** 同期先リモートホストの展開先。同期コマンドがrsyncの場合は絶対パスになります。   |
| DEP_INCLUDE_FILE | 例：`./.depinc.sh`    | URLでも指定可能。[デフォルト](https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/.depignore) → [詳細](#include-file)   |
| DEP_IGNORE_FILE  | 例：`./.depignore`    | URLでも指定可能 → [詳細](#ignore-file)    |

## include file

同期の前後に任意の処理を挿入することができ、これらの処理をincludeファイルに記述します。

### 用途

- ローカルとリモートでDBの設定など違う場合に、自動的に切り替えたい
- リモートのテスト環境のみBASIC認証をかけたい

### 記述例

.depinc.sh
```sh
before_sync(){
  # 同期前に行いたい処理
}
after_sync(){
  # 同期後に行いたい処理
}
```

例えば、プロジェクトのルートに上記のファイルを設置した場合は、次のように指定します。

.drone.yml
```yml
env:
  - DEP_INCLUDE_FILE=./.depinc.sh
```

予めホストされたファイルをダウンロードすることもできます。

.drone.yml
```yml
env:
  - DEP_INCLUDE_FILE=https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/include-files/php/.depinc.sh
```

上記のファイルを指定すると、同期の前段階で下記の処理が実行されます。[詳しくはこちら](https://github.com/KarappoInc/drone-deploy/blob/master/include-files/php/.depinc.sh)

1. `.htaccess`ファイル内の`#RM_SYNC_REMOTE ` `#RM_SYNC_[BRANCH_NAME] `を削除
2. phpファイル内の`//RM_SYNC_REMOTE ` `//RM_SYNC_[BRANCH_NAME] `を削除

例えば、Wordpressを使ったプロジェクトで下記の様に記述することができます。

wp-config.php
```php
// Database Settings　-----------

// Local

// ローカル環境でのみ有効
//RM_SYNC_REMOTE /*
define('DB_NAME', 'LOCAL_DATABASE');
define('DB_USER', 'root');
define('DB_PASSWORD', 'root');
define('DB_HOST', 'localhost');
//RM_SYNC_REMOTE */

// Remote

// masterブランチのデプロイ先でのみ有効
//RM_SYNC_MASTER define('DB_NAME', 'PROD_DATABASE');
//RM_SYNC_MASTER define('DB_USER', 'PROD_USER');
//RM_SYNC_MASTER define('DB_PASSWORD', 'PROD_PASSWORD');
//RM_SYNC_MASTER define('DB_HOST', 'PROD_HOST');

// testブランチのデプロイ先でのみ有効
//RM_SYNC_TEST define('DB_NAME', 'TEST_DATABASE');
//RM_SYNC_TEST define('DB_USER', 'TEST_USER');
//RM_SYNC_TEST define('DB_PASSWORD', 'TEST_PASSWORD');
//RM_SYNC_TEST define('DB_HOST', 'TEST_HOST');

// Common

define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// -----------　/ Database Settings
```

下記のように記述しておけば、testブランチの同期先のみBASIC認証をかけられます。

.htaccess
```sh
# Basic Authentication -----------
#RM_SYNC_TEST <Files ~ "^\.(htaccess|htpasswd)$">
#RM_SYNC_TEST deny from all
#RM_SYNC_TEST </Files>
#RM_SYNC_TEST AuthUserFile /home/example/www/.htpasswd
#RM_SYNC_TEST AuthGroupFile /dev/null
#RM_SYNC_TEST AuthName "Please enter your ID and password"
#RM_SYNC_TEST AuthType Basic
#RM_SYNC_TEST require valid-user 
#RM_SYNC_TEST order deny,allow
# ----------- / Basic Authentication
```


## ignore file

同期時に無視したいものを指定するためのファイルです。

デフォルト: `https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/.depignore`

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
  - DEP_IGNORE_FILE=./.depignore
```

こちらもホストされたファイルをダウンロードでき、デフォルトでは下記のように指定されています。オリジナルで作成する場合は、[こちらのファイル](https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/.depignore)を参考にして下さい。

.drone.yml
```yml
env:
  - DEP_IGNORE_FILE=https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/.depignore
```


# For Developpers

このスクリプト集は、droneが提供する[Deployments](https://github.com/drone/drone#deployments)トリガーの中で`deploy.sh`を読み込むことで動作します。
***プロジェクト内のスクリプトの仕様が変わると意図した動作をしないことがあるので、利用する場合はforkして、各読込先を変更してください。***
変更が必要な箇所は[こちら](https://github.com/KarappoInc/drone-deploy/search?utf8=%E2%9C%93&q=https%3A%2F%2Fraw.githubusercontent.com%2FKarappoInc%2Fdrone-deploy)で確認して下さい。