# 部署Vue

### macOS部署：

**首先，下载并安装vue安装包**

[node安装包](http://nodejs.cn/download/)

**安装都是遵循傻瓜式安装方式，一直下一步就好，安装完成之后在终端执行：**

```shell
linlsec@linlsecdeMacBook-Pro ~ % npm -v  # 执行 npm -v
6.14.10
```

**由于node npm是在国外的镜像下使用，是比较慢的，淘宝为我们提供了一套指令**

**执行:**

```shell
linlsec@linlsecdeMacBook-Pro ~ % npm install -g cnpm --registry=https://registry.npm.taobao.org
npm WARN deprecated request@2.88.2: request has been deprecated, see https://github.com/request/request/issues/3142
npm WARN deprecated har-validator@5.1.5: this library is no longer supported
npm WARN checkPermissions Missing write access to /usr/local/lib/node_modules
npm ERR! code EACCES
npm ERR! syscall access
npm ERR! path /usr/local/lib/node_modules
npm ERR! errno -13
npm ERR! Error: EACCES: permission denied, access '/usr/local/lib/node_modules'
npm ERR!  [Error: EACCES: permission denied, access '/usr/local/lib/node_modules'] {
npm ERR!   errno: -13,
npm ERR!   code: 'EACCES',
npm ERR!   syscall: 'access',
npm ERR!   path: '/usr/local/lib/node_modules'
npm ERR! }
npm ERR! 
npm ERR! The operation was rejected by your operating system.
npm ERR! It is likely you do not have the permissions to access this file as the current user
npm ERR! 
npm ERR! If you believe this might be a permissions issue, please double-check the
npm ERR! permissions of the file and its containing directories, or try running
npm ERR! the command again as root/Administrator.

npm ERR! A complete log of this run can be found in:
npm ERR!     /Users/linlsec/.npm/_logs/2021-01-17T08_48_45_971Z-debug.log
```

**会发现报错了，原因是没有权限在该文件夹下写入文件，需要用root权限**

**解决办法：执行:**

```shell
linlsec@linlsecdeMacBook-Pro ~ % sudo npm install -g cnpm --registry=https://registry.npm.taobao.org
Password:
npm WARN deprecated request@2.88.2: request has been deprecated, see https://github.com/request/request/issues/3142
npm WARN deprecated har-validator@5.1.5: this library is no longer supported
/usr/local/bin/cnpm -> /usr/local/lib/node_modules/cnpm/bin/cnpm
+ cnpm@6.1.1
added 689 packages from 974 contributors in 13.958s
```

**输入root账户的密码，成功！**

**接下来执行命令:**

```shell
linlsec@linlsecdeMacBook-Pro ~ % sudo cnpm install -g vue-cli                                       
Downloading vue-cli to /usr/local/lib/node_modules/vue-cli_tmp
Copying /usr/local/lib/node_modules/vue-cli_tmp/_vue-cli@2.9.6@vue-cli to /usr/local/lib/node_modules/vue-cli
Installing vue-cli's dependencies to /usr/local/lib/node_modules/vue-cli/node_modules
[1/20] commander@^2.9.0 installed at node_modules/_commander@2.20.3@commander
[2/20] minimatch@^3.0.0 installed at node_modules/_minimatch@3.0.4@minimatch
[3/20] chalk@^2.1.0 installed at node_modules/_chalk@2.4.2@chalk
[4/20] consolidate@^0.14.0 installed at node_modules/_consolidate@0.14.5@consolidate
[5/20] rimraf@^2.5.0 existed at node_modules/_rimraf@2.7.1@rimraf
[6/20] multimatch@^2.1.0 installed at node_modules/_multimatch@2.1.0@multimatch
[7/20] async@^2.4.0 installed at node_modules/_async@2.6.3@async
[8/20] semver@^5.1.0 installed at node_modules/_semver@5.7.1@semver
[9/20] handlebars@^4.0.5 installed at node_modules/_handlebars@4.7.6@handlebars
[10/20] read-metadata@^1.0.0 installed at node_modules/_read-metadata@1.0.0@read-metadata
[11/20] coffee-script@1.12.7 existed at node_modules/_coffee-script@1.12.7@coffee-script
[12/20] uid@0.0.2 installed at node_modules/_uid@0.0.2@uid
[13/20] user-home@^2.0.0 installed at node_modules/_user-home@2.0.0@user-home
[14/20] tildify@^1.2.0 installed at node_modules/_tildify@1.2.0@tildify
[15/20] metalsmith@^2.1.0 installed at node_modules/_metalsmith@2.3.0@metalsmith
[16/20] validate-npm-package-name@^3.0.0 installed at node_modules/_validate-npm-package-name@3.0.0@validate-npm-package-name
[17/20] ora@^1.3.0 installed at node_modules/_ora@1.4.0@ora
[18/20] inquirer@^6.0.0 installed at node_modules/_inquirer@6.5.2@inquirer
[19/20] request@^2.67.0 installed at node_modules/_request@2.88.2@request
[20/20] download-git-repo@^1.0.1 installed at node_modules/_download-git-repo@1.1.0@download-git-repo
deprecate metalsmith@2.3.0 › gray-matter@2.1.1 › coffee-script@^1.12.4 CoffeeScript on NPM has moved to "coffeescript" (no hyphen)
deprecate request@^2.67.0 request has been deprecated, see https://github.com/request/request/issues/3142
deprecate request@2.88.2 › har-validator@~5.1.3 this library is no longer supported
All packages installed (233 packages installed from npm registry, used 7s(network 6s), speed 799.03kB/s, json 220(483.51kB), tarball 4.57MB)
[vue-cli@2.9.6] link /usr/local/bin/vue@ -> /usr/local/lib/node_modules/vue-cli/bin/vue
[vue-cli@2.9.6] link /usr/local/bin/vue-init@ -> /usr/local/lib/node_modules/vue-cli/bin/vue-init
[vue-cli@2.9.6] link /usr/local/bin/vue-list@ -> /usr/local/lib/node_modules/vue-cli/bin/vue-list
```

**安装vue的客户端命令，安装完毕！**