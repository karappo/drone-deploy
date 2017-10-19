# drone-deploy

This is a useful scripts collection for deploying with Drone CI.

![How "drone-deploy" works](./img/how-works.png)

## Fatures

- Uploading files with rsync or lftp
- Auto editing in each environments before uploading (Ref: [include file](#include-file))

## Dependency

- [Drone OSS](https://github.com/drone/drone)
- [GitHub](http://github.com)

Ref: [INSTALLATION.md](https://github.com/karappo/drone-deploy/blob/master/INSTALLATION.md).

## Usage

1. [Setup your Drone server](https://github.com/karappo/drone-deploy/blob/master/INSTALLATION.md)
1. Activate your project on Drone.
2. [Add `.drone.yml` file into your project root](#droneyml)
3. [Optional] Add [include file](#include-file) and [ignore file](#ignore-file)
4. Commit and push as usual

## .drone.yml

最低限、下記の様な内容が必要です。

.drone.yml
```yml
clone:
  depth: 1
build:
  image: karappo/dronedeploy
  environment:
    - DEP_MASTER_HOST=[ftphost]
    - DEP_MASTER_USER=[username]
    - DEP_MASTER_PASSWORD=[password]
    - DEP_MASTER_HOST_DIR=www
  commands:
    - curl https://raw.githubusercontent.com/karappo/drone-deploy/master/deploy.sh | bash
```

各変数について説明します。


#### clone.depth

git cloneする時の引数を指定できます。`1`にしておくと、履歴情報は取得せず最新の内容だけ取ってくるので動作が早くなります。特別なことをしない限り付けておくのが良いでしょう。

#### build.image

テストの実行などがなく、単にファイルの転送だけしたい場合は[karappo/dronedeploy](https://hub.docker.com/r/karappo/dronedeploy/)を指定して下さい。
必要なツールがインストール済みのイメージなので、`bradrydzewski/base`よりも高速です。
`karappo/dronedeployの`Dockerfileは[こちら](https://github.com/karappo/docker-dronedeploy/blob/master/Dockerfile)にあります。

#### build.environment

上記スクリプト等の中で仕様する環境変数です。**`[BRANCH]`には対象とするブランチ名を大文字で代入してください。これによりブランチ毎に設定を変更できます**。

| 環境変数                    | 値                   | 説明                                      |
|:------------------------- |:-------------------- |:---------------------------------------- |
| `DEP_[BRANCH]_COMMAND`      | `lftp`または`rsync`   | 同期コマンド（デフォルトは`lftp`）              |
| `DEP_[BRANCH]_FTPS`         | `no`                 | リモート側がFTPS接続未対応の場合のみ`no`を指定    |
| `DEP_[BRANCH]_HOST`         | 例：`ftp.sample.com`  | ***[required]*** 同期先リモートホストのアドレス |
| `DEP_[BRANCH]_PORT`         | 例：`2222`            | `DEP_COMMAND`が`rsync`の場合のみ有効。ポートが22でない場合に使用  |
| `DEP_[BRANCH]_USER`         |                      | ***[required]*** FTPまたはSSHのユーザ名      |
| `DEP_[BRANCH]_PASSWORD`     |                      | ***(required)*** FTPまたはSSHのパスワード 同期コマンドがrsyncかつ公開鍵で認証する場合は不要です |
| `DEP_[BRANCH]_HOST_DIR`     | 例：`www`             | ***[required]*** 同期先リモートホストの展開先 同期コマンドがrsyncの場合は絶対パスになります |
| `DEP_[BRANCH]_INCLUDE_FILE` | 例：`./.depinc.sh`    | URLでも指定可能 → [詳細](#include-file) |
| `DEP_[BRANCH]_IGNORE_FILE`  | 例：`./.depignore`    | URLでも指定可能 → [詳細](#ignore-file) [デフォルト](https://raw.githubusercontent.com/karappo/drone-deploy/master/.depignore) |

##### DEP_REMOTE_XXX

`DEP_[BRANCH]_XXX`が見つからない場合、`DEP_REMOTE_XXX`を探し見つかればその値を使います。ブランチ間で共通する値がある場合などは、`REMOTE`を活用してください。

#### build.commands

ここがシステムの起点になっています。必ず、この通りに記述して下さい。


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
build:
  environment:
    - DEP_MASTER_INCLUDE_FILE=./.depinc.sh
```

URLを指定することもできます。

.drone.yml
```yml
build:
  environment:
    - DEP_MASTER_INCLUDE_FILE=https://raw.githubusercontent.com/karappo/drone-deploy/master/include-files/php/.depinc.sh
```

上記のファイルを指定すると、同期の前段階で下記の処理が実行されます。[詳しくはこちら](https://github.com/karappo/drone-deploy/blob/master/include-files/php/.depinc.sh)

1. `.htaccess`ファイル内の`#DEP_REMOTE_RM ` `#DEP_[BRANCH]_RM `を削除
2. phpファイル内の`//DEP_REMOTE_RM ` `//DEP_[BRANCH]_RM `を削除

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

// stagingブランチのデプロイ先でのみ有効
//DEP_STAGING_RM define('DB_NAME', 'STAGING_DATABASE');
//DEP_STAGING_RM define('DB_USER', 'STAGING_USER');
//DEP_STAGING_RM define('DB_PASSWORD', 'STAGING_PASSWORD');
//DEP_STAGING_RM define('DB_HOST', 'STAGING_HOST');

// Common

define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// -----------　/ Database Settings
```

下記のように記述しておけば、stagingブランチの同期先のみBASIC認証をかけられます。

.htaccess
```sh
# Basic Authentication -----------
#DEP_STAGING_RM <Files ~ "^\.(htaccess|htpasswd)$">
#DEP_STAGING_RM deny from all
#DEP_STAGING_RM </Files>
#DEP_STAGING_RM AuthUserFile /home/example/www/.htpasswd
#DEP_STAGING_RM AuthGroupFile /dev/null
#DEP_STAGING_RM AuthName "Please enter your ID and password"
#DEP_STAGING_RM AuthType Basic
#DEP_STAGING_RM require valid-user
#DEP_STAGING_RM order deny,allow
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
build:
  environment:
    - DEP_MASTER_IGNORE_FILE=./.depignore
```

こちらもURLを指定でき、デフォルトでは下記のように指定されています。オリジナルで作成する場合は、[.depignore](https://github.com/karappo/drone-deploy/blob/master/.depignore)を参考にして下さい。

.drone.yml
```yml
build:
  environment:
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
