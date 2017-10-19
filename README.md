# drone-deploy

This is a useful scripts collection for deploying with [Drone CI](https://github.com/drone/drone).

_Compatible: Drone v0.4_

![How "drone-deploy" works](./img/how-works.png)

## Features

- Uploading files with rsync or lftp
- [Auto editing in each environments before uploading](#include-file)

## Setup

### 1. Fork this repository

This scripts are triggered by Drone's [Deployments](https://github.com/drone/drone#deployments). It will get [this file](https://raw.githubusercontent.com/karappo/drone-deploy/update-readme/deploy.sh) hosted on this repository. This means that changes on this repository may affect your deployment immediately. So you shouldn't use this directly, you should fork this at first, then change [these parts](https://github.com/karappo/drone-deploy/search?utf8=%E2%9C%93&q=https%3A%2F%2Fraw.githubusercontent.com%2Fkarappo%2Fdrone-deploy) to yours. (just replace `karappo/drone-deploy/` to `your-acocunt/drone-deploy/`)

### 2. Setup Drone

Please install following [this instruction](http://readme.drone.io/0.4/setup/overview/).

Ref: [Easily install Drone on Digital Ocean (Japanese)](https://qiita.com/naokazuterada/items/d040ad27e77b587ef49f)

_[This branch list shows drone compatibles.](https://github.com/karappo/drone-deploy/branches/all?utf8=%E2%9C%93&query=drone-compatible)_

## Usage

1. Activate your project on Drone.
2. [Add `.drone.yml` file into your project root](#droneyml)
3. [Optional] Add [include file](#include-file) and [ignore file](#ignore-file)
4. Commit and push as usual


## .drone.yml

The following contents are recommended.

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

### Explaination of variables


##### clone.depth

Setting it `1` is recommended, because of making cloning faster.

##### build.image

Setting `karappo/dronedeploy` is recommended, because it's been installed necessary tools already, so this makes builds fater.
Ref: [karappo/dronedeploy](https://hub.docker.com/r/karappo/dronedeploy/~/dockerfile/)

##### build.environment \[required\]

These environment variables will be used in scripts.
Replace `[BRANCH]` to your target branch name.
If `DEP_[BRANCH]_XXX` won't be found, the scripts will use `DEP_REMOTE_XXX` instead.
It's useful if you have some common settings between remote environments.

**Required**

| Key                     | Value                 | Description          |
|:----------------------- |:--------------------  |:-------------------- |
| `DEP_[BRANCH]_HOST`     | e.g. `ftp.sample.com` | Target remote host   |
| `DEP_[BRANCH]_USER`     |                       | FTP or SSH username  |
| `DEP_[BRANCH]_PASSWORD` |                       | Not Necessary if command is rsync without password |
| `DEP_[BRANCH]_HOST_DIR` | e.g. `www`(lftp)      | Set **absolute path** if command is rsync |

**Optional**

| Key                         | Value                      | Description                                            |
|:--------------------------- |:-------------------------- |:------------------------------------------------------ |
| `DEP_[BRANCH]_COMMAND`      | `lftp`(default) or `rsync` | Command                                                |
| `DEP_[BRANCH]_FTPS`         | `no`                       | [Set `no` only if remote doesn't accept FTPS](#disable-deployment-on-particular-timing) |
| `DEP_[BRANCH]_PORT`         | default: `22`              | Activate only if command is rsync                      |
| `DEP_[BRANCH]_INCLUDE_FILE` | e.g. `./.depinc.sh`        | [URL allowed](#include-file)                           |
| `DEP_[BRANCH]_IGNORE_FILE`  | e.g. `./.depignore`, [default](https://raw.githubusercontent.com/karappo/drone-deploy/master/.depignore) | [URL allowed](#ignore-file) |

##### build.commands \[required\]

This is the entry point of this system. **Do NOT change**.



## Include file

You can define custom processes before and after syncing in this file.

### Examples purpose

- Switch DB settings by each environments
- Activate Basic Auth only on stating environment

### Usage

Include file should have two methods like this.

.depinc.sh

```sh
before_sync(){
  # process you want to do before syncing
}
after_sync(){
  # process you want to do after syncing
}
```

You should set your include file with related path from your project's root.

.drone.yml

```yml
build:
  environment:
    - DEP_MASTER_INCLUDE_FILE=./.depinc.sh
```

Or you can set this as URL.

.drone.yml

```yml
build:
  environment:
    - DEP_MASTER_INCLUDE_FILE=https://raw.githubusercontent.com/karappo/drone-deploy/master/include-files/php/.depinc.sh
```

If you set like above, these process below will be executed.


1. Remove `#DEP_REMOTE_RM ` and `#DEP_[BRANCH]_RM ` in `.htaccess` file
2. Remove `//DEP_REMOTE_RM ` and `//DEP_[BRANCH]_RM ` in `.php` files

Ref: [.depinc.sh](https://github.com/karappo/drone-deploy/blob/master/include-files/php/.depinc.sh)

In WordPress project, you can write code like this.

wp-config.php

```php
// Database Settings　-----------

// Local

// Activate only in local environment
//DEP_REMOTE_RM /*
define('DB_NAME', 'LOCAL_DATABASE');
define('DB_USER', 'root');
define('DB_PASSWORD', 'root');
define('DB_HOST', 'localhost');
//DEP_REMOTE_RM */

// Remote

// Activate only in master branch's deploy target
//DEP_MASTER_RM define('DB_NAME', 'PROD_DATABASE');
//DEP_MASTER_RM define('DB_USER', 'PROD_USER');
//DEP_MASTER_RM define('DB_PASSWORD', 'PROD_PASSWORD');
//DEP_MASTER_RM define('DB_HOST', 'PROD_HOST');

// Activate only in staging branch's deploy target
//DEP_STAGING_RM define('DB_NAME', 'STAGING_DATABASE');
//DEP_STAGING_RM define('DB_USER', 'STAGING_USER');
//DEP_STAGING_RM define('DB_PASSWORD', 'STAGING_PASSWORD');
//DEP_STAGING_RM define('DB_HOST', 'STAGING_HOST');

// Common

define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// -----------　/ Database Settings
```

And you can activate Basic Auth only in staging branch's target environment with this below.

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

### Prepared include files

There are some files for particular purposes or environments under the directory [`include-files`](https://github.com/karappo/drone-deploy/tree/master/include-files).


## Ignore file

This is a file for exclusion in syncing.

### Example

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

You should set your ignore file with related path from your project's root.

.drone.yml

```yml
build:
  environment:
    - DEP_MASTER_IGNORE_FILE=./.depignore
```

## FAQ

### Got `Fatal error: Certificate verification: Not trusted`

If you got these errors, your remote server may not accept FTPS connection. Please set `DEP_[BRANCH]_FTPS=no`.

```sh
[DEPLOY] - sync -> via FTPS
ftp://user:password@host.com
mirror: Fatal error: Certificate verification: Not trusted
[DEPLOY] - sync -> [ERROR]
```

### Disable deployment on particular timing

You can skip deployment with `[skip ci]` in your last commit comment. Ammend your last commit or just add empty commit and push.

```sh
git commit --allow-empty -m '[skip ci]'
```

Ref: [Skip Commits (Drone Document)](http://docs.drone.io/hooks/#skip-commits)