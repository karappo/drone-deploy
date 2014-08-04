# Scripts for drone deploy

[drone(OSS版)](https://github.com/drone/drone)を使ったデプロイ用のスクリプト

---

***[注意]***
このプロジェクトは、メンテナンスで頻繁に変更される可能性があるので、利用したい場合はプロジェクトをforkして、各読込先をそのdeploy.shに変更してください。


## 使い方（LFTP）

プロジェクトルートに`.drone.yml`ファイルを追加します。

```yml
image: node0.10
env:
  - DEP_COMMAND=lftp
  - DEP_HOST=<ftphost>
  - DEP_USER=<username>
  - DEP_PASSWORD=<password>
  - DEP_HOST_DIR=www
  - DEP_IGNORE_FILE=./.depignore
  - DEP_INCLUDE_FILE=https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/php/.depinc.sh
deploy:
  bash:
    command: curl https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/deploy.sh | bash
```

各変数について説明します。


### image

任意のdocker imageを指定します。

### env

deploy.sh内などで使用する環境変数の設定をします。


#### DEP_COMMAND

deployで使用する同期コマンド

- デフォルト： `lftp`
- 取りうる値： `lftp` または `rsync`

#### DEP_HOST

リモートホストのアドレス

- 例： `ftp.sample.com`

#### DEP_USER

FTPまたはSSHのユーザ名

#### DEP_PASSWORD

FTPまたはSSHのパスワード

#### DEP_IGNORE_FILE

ignoreファイル

#### DEP_INCLUDE_FILE

includeファイル


### deploy

bash > command に deploy.sh を指定します。
