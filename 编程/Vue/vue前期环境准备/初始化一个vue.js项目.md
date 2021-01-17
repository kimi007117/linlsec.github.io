# 初始化一个vue.js项目

### macOS：

**1、自己创建并进入一个项目目录，创建一个名为VueDemo的vue项目**

```shell
cd /usr/local/projects/vue/
vue init webpack VueDemo # 创建一个新项目
```

**创建项目可能会报错“vue-cli · Failed to download repo vuejs-templates/webpack: tunneling socket could not be established, cause=Parse Error”，可以尝试如下：**

**（1）清空npm代理，重新执行**

```shell
npm config set proxy null
vue init webpack VueDemo
```

**（2）或者sudo执行（webpack是构建工具，也就是整个项目是基于webpack的）**

```shell
sudo vue init webpack VueDemo
```

**创建项目成功的结果：**

```shell
? Project name helloword
? Project description A Vue.js project
? Author linl-sec <linlxxxx@163.com>
? Vue build standalone
? Install vue-router? Yes
? Use ESLint to lint your code? Yes
? Pick an ESLint preset Standard
? Set up unit tests Yes
? Pick a test runner jest
? Setup e2e tests with Nightwatch? Yes
? Should we run `npm install` for you after the project has been created? (recommended) npm

Running eslint --fix to comply with chosen preset rules...
# ========================


> helloword@1.0.0 lint /Users/linlsec/Desktop/Vue/VueDemo
> eslint --ext .js,.vue src test/unit test/e2e/specs "--fix"


# Project initialization finished!
# ========================

To get started:

  cd VueDemo
  npm run dev
  
Documentation can be found at https://vuejs-templates.github.io/webpack
```

**2、启动项目 **

**（1）安装项目依赖，启动项目需要先安装项目所需依赖，就跟java的maven项目需要先更新dependencies一样，具体项目都依赖了什么，在项目根目录下package.json中的devDependencies标签下可以看到**

```shell
linlsec@linlsecdeMacBook-Pro Vue % sudo cnpm install
Password:
npminstall WARN package.json not exists: /Users/linlsec/Desktop/Vue/package.json
✔ Installed 0 packages
✔ Linked 0 latest versions
✔ Run 0 scripts
✔ All packages installed (used 6ms(network 4ms), speed 0B/s, json 0(0B), tarball 0B)
```

**在Mac下，有些项目执行install时可能会报错“libtool: unrecognized option `-static’”，解决方法：在~/.bash_profile中添加“PATH="/Library/Developer/CommandLineTools/usr/bin:$PATH”，再重新打开一个终端，重新运行install命令**

**安装成功之后，项目根目录会多出一个node_modules文件夹，这里边就是项目需要的依赖包资源（文件挺多的）。**

**（2）运行项目，用热加载的方式启动项目，在修改完代码后不用手动刷新浏览器就能实时看到修改后的效果。**

```shell
linlsec@linlsecdeMacBook-Pro Vue % cd VueDemo # 进入项目
linlsec@linlsecdeMacBook-Pro VueDemo % cnpm run dev # 运行项目
```

**启动成功的结果：**

```shell
> helloword@1.0.0 dev /Users/linlsec/Desktop/Vue/VueDemo
> webpack-dev-server --inline --progress --config build/webpack.dev.conf.js

 13% building modules 28/31 modules 3 active ...nlsec/Desktop/Vue/VueDemo/src/App.vue{ parser: "babylon" } is deprecated; we now treat it as { parser: "babel" }.
 95% emitting                                                                        

 DONE  Compiled successfully in 1788ms                                                                                下午5:48:59

 I  Your application is running here: http://localhost:8080
```

**打开http://localhost:8080就是vue默认的模板**

![img](https://github.com/linl-sec/linlsec.github.io/blob/main/images/%E7%BC%96%E7%A8%8B/WX20210117-175104%402x.png)

