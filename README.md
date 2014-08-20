# Drone deploy

[drone.io(OSS ver.)](https://github.com/drone/drone)を使った、deployを便利にするスクリプト集です。

droneが提供する[Deployments](https://github.com/drone/drone#deployments)トリガーの中で`deploy.sh`を読み込むことで動作します。

***プロジェクト内のスクリプトの仕様が変わると意図した動作をしないことがあるので、利用する場合はforkして、各読込先を変更してください。***

---

## 使い方

1. droneにdeployしたい対象プロジェクトを追加
2. 対象プロジェクトのルートディレクトリに`.drone.yml`ファイルを追加 → [.drone.yml file](#droneyml-file)
3. 対象プロジェクトにcommitしてpush


## .drone.yml file

下記の様な内容で作成します。

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

任意のdocker imageを指定します。
テストなどを走らせず、単にファイルの転送だけしたい場合は`bradrydzewski/base`を指定して下さい。

**deploy**

ここがシステムの起点になっています。

***forkしている場合は、必ずcurlのアドレスを変更して下さい。***

**env**

上記スクリプト等の中で仕様する環境変数です。

| 環境変数           | 値                   | 説明                                     |
|:---------------- |:-------------------- |:--------------------------------------- |
| DEP_COMMAND      | `lftp`または`rsync`   | 同期コマンド（デフォルトは`lftp`）            |
| DEP_HOST         | 例：`ftp.sample.com`  | ***required*** 同期先リモートホストのアドレス |
| DEP_USER         |                      | ***required*** FTPまたはSSHのユーザ名      |
| DEP_PASSWORD     |                      | ***required*** FTPまたはSSHのパスワード     |
| DEP_HOST_DIR     | 例：`www`             | ***required*** 同期先リモートホストの展開先   |
| DEP_INCLUDE_FILE | 例：`./.depinc.sh`    | → [include file](#include-file)   |
| DEP_IGNORE_FILE  | 例：`./.depignore`    | → [ignore file](#ignore-file)     |

## include file

同期の前後に任意の処理を挿入することができ、これらの処理をincludeファイルに記述します。

### 用途

- ローカルとリモートでDBの設定など違う場合に、自動的に切り替えたい
- リモートのテスト環境のみBASIC認証をかけたい

### 記述例

例えば、プロジェクトのルートに`.depinc.sh`という名前でファイルを作った場合は、次のように指定します。

```yml
env:
  - DEP_INCLUDE_FILE=./.depinc.sh
  ...
```

予めホストされたファイルをダウンロードすることもできます。

```yml
env:
  - DEP_INCLUDE_FILE=https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/php/.depinc.sh
  ...
```

上記のファイルを指定すると、同期の前段階で下記の処理が実行されます。

1. `.htaccess`ファイル内の`#RM_SYNC_REMOTE ` `#RM_SYNC_[BRANCH_NAME] `を削除
2. phpファイル内の`//RM_SYNC_REMOTE ` `//RM_SYNC_[BRANCH_NAME] `を削除

例えば、Wordpressの`wp-config.php`で下記の様に記述することができます。

```php
// Database Settings　-----------

// Local
//RM_SYNC_REMOTE /*
define('DB_NAME', 'LOCAL_DATABASE');
define('DB_USER', 'root');
define('DB_PASSWORD', 'root');
define('DB_HOST', 'localhost');
//RM_SYNC_REMOTE */

// Remote
//RM_SYNC_MASTER define('DB_NAME', 'PROD_DATABASE');
//RM_SYNC_MASTER define('DB_USER', 'PROD_USER');
//RM_SYNC_MASTER define('DB_PASSWORD', 'PROD_PASSWORD');
//RM_SYNC_MASTER define('DB_HOST', 'PROD_HOST');

//RM_SYNC_TEST define('DB_NAME', 'TEST_DATABASE');
//RM_SYNC_TEST define('DB_USER', 'TEST_USER');
//RM_SYNC_TEST define('DB_PASSWORD', 'TEST_PASSWORD');
//RM_SYNC_TEST define('DB_HOST', 'TEST_HOST');

// Common
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// / Database Settings　---------
```

`.htaccess`に下記のように記述しておけば、TESTブランチの同期先のみBASIC認証をかけられます。

```sh
# Basic Authentication -----------
#RM_SYNC_TEST <Files ~ "^\.(htaccess|htpasswd)$">
#RM_SYNC_TEST deny from all
#RM_SYNC_TEST </Files>
#RM_SYNC_TEST AuthUserFile /home/hoge/.htpasswd
#RM_SYNC_TEST AuthGroupFile /dev/null
#RM_SYNC_TEST AuthName "Please enter your ID and password"
#RM_SYNC_TEST AuthType Basic
#RM_SYNC_TEST require valid-user 
#RM_SYNC_TEST order deny,allow
# ----------- / Basic Authentication
```


## ignore file

同期時に転送したくないファイルを指定するためのファイルです。

### 記述例

例えば、プロジェクトのルートに`.depignore`という名前でファイルを作った場合は、次のように指定します。

```yml
env:
  - DEP_IGNORE_FILE=./.depignore
  ...
```

こちらもホストファイルをダウンロードでき、デフォルトでは下記のように指定されています。オリジナルで作成する場合は、[こちらのファイル](https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/.depignore)を参考にして下さい。

```yml
env:
  - DEP_IGNORE_FILE=https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/.depignore
  ...
```