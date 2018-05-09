![CICD Logo](/Private/Images/CICD.png "CICD Logo")
![SQL Logo](/Private/Images/sql.png "SQL Logo")

# MSSQL-CICD-Helper

- [Introduction](#introduction)
- [Support / Contribution](#support--contribution)
- [Installation](#installation)
- [Configuration](#configuration)
- [Functions](#functions)

----

# Introduction

This repo contains a powershell module which helps and aids in CI / CD processes specifically for MSSQL (Microsoft SQL Server). 
The module was born because not every CI / CD tool supports the quirks often presented when trying to implement CI / CD in combination with SQL Server Projects (more on this in Background).

The main issue is that most current CI systems do not help in discovery of files to build / deploy which makes it difficult to automate building processes because your pipeline code needs to be customized for each solution / Database which you want running in your pipeline.

MSSQL-CICD-Helper helps you automate further by not worrying how your SQL Solution is configured. Something i found which would often differ in each project / solution (definitely not a best practice ^^)

## Features

- Find any \*.sln, \*.sqlproject, \*.dacpac, \*.publish.XML or \*.dtspac on a runner / container based on the pulled sourcecode (so no need to worry about hard-coded paths)
- run MSBuild for SQLProjects / SLN files (with above mentioned auto-discovery)
  - supports SSDT, SSIS, SSAS, SSRS solutions (\*.sln files)
  - Supports SSDT Projects (\*.sqlproj files)
  - Call either built-in MSBuild function or use [Invoke-MSBuild](https://github.com/deadlydog/Invoke-MsBuild)
  - Support for adding custom arguments to MSBuild / Invoke-MSBuild
- Deploy / Publish DacPac files (with above mentioned discovery)
  - Support for connectionstrings
  - Support for publishing profiles
  - Support for custom credentials
  - Support for adding any custom arguments to SQLPackage.exe
- Discover and save MsBuild.exe / SQLPackage.exe on runner system

## Upcoming Features

- Add example kicker script
- Add example CI / Pipeline scripts
  - Gitlab
  - Jenkins
  - TeamCity
  - VSTS/TFS
- Add ability to use Windows Credentials instead of SQL Authentication.
- Enable deploying SSIS packages
- Enable deploying SSAS packages
- Enable deploying SSRS packages
- Enable deploying Azure Data Factory code
- Test Automation (such as [T-SQLT](http://tsqlt.org/))
- Support for Azure SQL Database / Datawarehouse (it does support Azure VMs with SQL installed on it)
- Maintaining / exporting dacpac prior to deploy
- Support for saving environments for deploying (which you should do in your CI system if possible)
- Code improvement / refactoring / cleaning up

## Supported CI Systems

The following CI systems were tested and are supported:

- [Jenkins](https://jenkins.io/)
- [Gitlab CI](https://about.gitlab.com/)
- [Teamcity](https://www.jetbrains.com/teamcity/)
- [TFS / VSTS](https://www.visualstudio.com/team-services/)

Please [let me know](MSSQL-CICD-Helper@protonmail.com) if you have this module in place in another CI system so I can add it to the list!

## Background

One of the challenges I faced was when we switched CI systems and having to change a lot of the pipeline code because of hardcoded references to either solution / dacpac files. having to change all these references broke code a lot and as such I decided to make a powershell module which is versatile and exchangable when you switch CI systems.

----

# Support / Contribution

If you want features added or find an issue please let me know by raising an issue on github. You are welcome to contribute if you have additional features or want to refactor. Pull requests are welcome!

By no means am I a experienced Powershell programmer so please point me towards good code convention if you feel my code lacks in some kind. I am eager to learn to improve my code.

Also i'd like some help in automated Powershell testing (pester etc.). So if you can and want to help please let me know!

You can always contact me in regards of this repo on MSSQL-CICD-Helper@protonmail.com

----

# Installation

## Prerequisites

In order for this module to work, your SQL Data products must be maintained / developed in Visual Studio (previously known as SSDT / SQL Server Data Tools). DDL definitions must be defined in a solution (\*.sln) containing one or more Projects (\*.sqlproj) files.

Obviously for best results a true CI system as mentioned aboved should be used alongside this module. However the module can be used on its own for starting out companies. Depending on your architecture a seperate packaging / deployment tool (like [Octopus Deploy](https://octopus.com/)) is advised.

## Download and install

Either download this repo and save it with your source code (can be in or outside your solution) or make a git clone at runtime within your pipeline (especially needed when running in docker containers). 

A kicker script is recommended for orchestrating your pipeline (Not yet added, if you need help with this [contact](MSSQL-CICD-Helper@protonmail.com) me.)

### Downloading / Cloning the module

```git
$ git clone https://github.com/tsteenbakkers/MSSQL-CICD-Helper.git
```
or download / clone a specific release from [Releases page](https://github.com/tsteenbakkers/MSSQL-CICD-Helper/releases)

```git
$ git clone https://github.com/tsteenbakkers/MSSQL-CICD-Helper.git --branch v1.0.0
```

### Importing the module

after cloning (or if you store it with your database code) you need to import this module in order to make the functions available:

```Powershell
Import-Module <path>\MSSQL-CICD-Helper\MSSQLCICDHelper.PSD1
```

if you add a -verbose switch it will also display all the functions exported

be advised that if you use a CI system or Docker that you need to clone / import at each seperate build (this is why you want a kicker script :) ).

----

# Configuration

MSSQL-CICD-Helper uses a config file which does not exist when you first install / import the module.

In order to use the functions we need to generate and save a config file. 

if you use [Save-MSSQLCICDHelperConfiguration](#save-mssqlcicdhelperconfiguration) it will let you store the filepath to SQLPackage.exe and MSBuild.exe for later use.

example:

```Powershell
Save-MSSQLCICDHelperConfiguration -SQLPackageExePath c:\SQLPackage.Exe -MSBuildExePath c:\MSBuild.exe
```

This will store `c:\MSBuild.exe` for calling *MSBuild* and `C:\SQLPackage.exe` for calling *SQLPackage*. The configuration is stored in an PSXML file in the local users *AppData* folder called `MSSQLCICDHelperConfiguration.xml`.

```windows
Example:

C:\Users\<user>\AppData\Roaming\MSSQLCICDHelper\MSSQLCICDHelperConfiguration.xml
```

You don't need to store both executables if you only want to partial functionality but it is advised to store them both. After you've saved the configuration you are set to go.

If you are unsure where either MSBuild / SQLPackage is located on your system (or on the runners system) you can use [Get-MSSQLCICDHelperPaths](#get-mssqlcicdhelperpaths). 

To review your saved config file use [Get-MSSQLCICDHelperConfiguration](#get-mssqlcicdhelperconfiguration).

*Note: when using docker (or any non persistant tooling) you need to inject your config file after you generate it with below function. This is not covered by this readme but i am willing to help. just [contact](MSSQL-CICD-Helper@protonmail.com) me!*

----

# Functions

## Configuration related functions

- [Save-MSSQLCICDHelperConfiguration](#save-mssqlcicdhelperconfiguration)
- [Get-MSSQLCICDHelperConfiguration](#get-mssqlcicdhelperconfiguration)
- [Get-MSSQLCICDHelperPaths](#get-mssqlcicdhelperpaths)

## Build / Deploy related functions

- [Get-MSSQLCICDHelperFiletoBuildDeploy](#get-mssqlcicdhelperfiletobuilddeploy)
- [Invoke-MSSQLCICDHelperMSBuild](#invoke-mssqlcicdhelpermsbuild)
- [Invoke-MSSQLCICDHelperSQLPackage](#invoke-mssqlcicdhelpersqlpackage)

----

## Save-MSSQLCICDHelperConfiguration

#### Parameters

*-SQLPackagePath (String) - Mandatory: False*

`Usage: -SQLPackagePath C:\yourpath\SqlPackage.exe`

*-MSBuildPath (String) - Mandatory: False*

`Usage: -MSBuildPath C:\yourpath\MSBuild.exe`

#### Usage

```Powershell
Save-MSSQLCICDHelperConfiguration -MSBuildPath <yourpath>.msbuild.exe -SQLPackagePath <yourpath>SqlPackage.exe
```

#### Examples

Save both MSBuild and SQLPackage Paths:

```Powershell
Save-MSSQLCICDHelperConfiguration -MSBuildPath C:\yourpath\MSBuild.exe -SQLPackagePath C:\yourpath\SqlPackage.exe
```

Save just MSBuild path:

```Powershell
Save-MSSQLCICDHelperConfiguration -MSBuildPath C:\yourpath\MSBuild.exe
```


----

## Get-MSSQLCICDHelperConfiguration

#### Parameters

None

#### Usage

```Powershell
Get-MSSQLCICDHelperConfiguration
```

#### Examples

Return saved configuration:

```Powershell
Get-MSSQLCICDHelperConfiguration
```

----

## Get-MSSQLCICDHelperPaths

#### Parameters

*-typetofind  (String) - Mandatory: True*

`Usage: -typetofind MSBuild`

Values Allowed:

- MSBuild -- searches for MSBuild.exe from -rootpath
- SQLPackage -- searches for SQLPackage.exe from -rootpath
- Both -- searches for MSBuild.exe & SQLPackage.exe from -rootpath

*-rootpath (String) - Mandatory: True*

`Usage: -SQLPackagePath C:\yourpath\`

#### Usage

```Powershell
Get-MSSQLCICDHelperPaths -typetofind <typetofind> -rootpath <path to search from>
```

#### Examples

Search for both MSBuild and SQLPackage from c:\users
```Powershell
Get-MSSQLCICDHelperPaths -typetofind Both -rootpath c:\users
```

----

## Get-MSSQLCICDHelperFiletoBuildDeploy

#### Parameters

*-typetofind  (String) - Mandatory: True*

`Usage: -typetofind MSBuild`

Values Allowed:

- Solution -- searches for a *.sln file
- Project -- searches for a *.sqlproj file
- DacPac -- searches for a *.dacpac file
- PublishProfile -- searches for a *.publish.xml file
- DTSPac -- searches for a *.dtspac file

*-rootpath (String) - Mandatory: True*

`Usage: -SQLPackagePath C:\yourpath\`

#### Usage

```Powershell
Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind <typetofind> -rootpath <path to search from>
```

#### Examples

Search for both MSBuild and SQLPackage from c:\users
```Powershell
Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Both -rootpath c:\users
```

----

## Invoke-MSSQLCICDHelperMSBuild

#### Parameters

*-filename  (String) - Mandatory: False*

`Usage: -filename c:\<path to file to build>\filetobuild.sln`

if left blank the module will find the closest \*.sln file from where the script is ran.

*-MSBuildArguments  (String) - Mandatory: False*

`Usage: -MSBuildArguments '/action:<insert your action>' `

Values **NOT** allowed:

- /fl
- /flp

U are welcome to create additional arguments. When using the [Invoke-MSBuild](https://github.com/deadlydog/Invoke-MsBuild) they will be passed to the -MsBuildParameters Parameter

See http://msdn.microsoft.com/en-ca/library/vstudio/ms164311.aspx for valid MsBuild command-line parameters.

*-hidden  (Switch) - Mandatory: False*

`Usage: -hidden`

if this switch is used the output from MSBuild will be hidden from the screen and only outcome will be presented.

*-Keeplogfiles  (Switch) - Mandatory: False*

`Usage: -Keeplogfiles`

if this switch is used the logfiles (including errorlog files will not be deleted when the outcome is successfull.)

*-UseInvokeMSBuildModule  (Switch) - Mandatory: False*

`Usage: -UseInvokeMSBuildModule`

if this switch is used the module will test for availability of the [Invoke-MSBuild](https://github.com/deadlydog/Invoke-MsBuild) module and it use it instead to build the chosen filename.

*-InvokeMSBuildParameters  (String) - Mandatory: False*

`Usage: -InvokeMSBuildParameters <params to pass in valid powershell formatting -paramname value>`

Input for passing additional Arguments to [Invoke-MSBuild](https://github.com/deadlydog/Invoke-MsBuild). Must be used in conjunction with -UseInvokeMSBuildModule

The following values are **NOT** allowed since we pass them automatically already:

- -Path (use -filename / auto discovery instead)
- -LogDirectory (automatically passed)
- -KeepBuildLogOnSuccessfulBuilds (use -KeepLogfiles instead)
- -MsBuildParameters (use -MSBuildArguments instead)

#### Usage

```Powershell
Invoke-MSSQLCICDHelperMSBuild -keeplogfiles
# or assign the output to a variable for later use
$result = Invoke-MSSQLCICDHelperMSBuild -keeplogfiles -hidden
```

#### Examples

Auto-discover Solution file and keep logfiles afterwards:

```Powershell
Invoke-MSSQLCICDHelperMSBuild -keeplogfiles
```

Build a specific project file and only show output:

```Powershell
Invoke-MSSQLCICDHelperMSBuild -filename c:\builds\32egeudsd\myawesomedatabase.sqlproj -hidden
```

Use [Invoke-MSBuild](https://github.com/deadlydog/Invoke-MsBuild) with autodiscovery and no additional arguments:

```Powershell
Invoke-MSSQLCICDHelperMSBuild -UseInvokeMSBuildModule
```

Use [Invoke-MSBuild](https://github.com/deadlydog/Invoke-MsBuild) with autodiscovery and additional arguments:

```Powershell
Invoke-MSSQLCICDHelperMSBuild -UseInvokeMSBuildModule -InvokeMSBuildParameters '-ShowBuildOutputInNewWindow -PromptForInputBeforeClosing -AutoLaunchBuildLogOnFailure'
```

----

## Invoke-MSSQLCICDHelperSQLPackage

#### Parameters

*-filename  (String) - Mandatory: False*

`Usage: -filename c:\<path to file to build>\filetodeploy.dacpac`

if left blank the module will find the closest \*.dacpac file from where the script is ran.

*-AditionalArguments  (String) - Mandatory: False*

`Usage: -AditionalArguments '/tec:True' `

Values **NOT** allowed:

- /action
- /SourceFile
- /Profile
- /TargetConnectionString
- /TargetServerName
- /TargetDatabaseName
- /TargetUsername
- /TargetPassword

Additional parameters to pass to the SQLPackage command-line tool. This can be any valid sqlpackage command-line parameter(s) except for the ones mentioned above.
    
See https://msdn.microsoft.com/library/hh550080(vs.103).aspx#Publish%20Parameters,%20Properties,%20and%20SQLCMD%20Variables for valid SQLPackage command-line parameters.

*-logfilepath  (String) - Mandatory: False*

`Usage: -logfilepath c:\<path to store log and errorlog files>`

If left blank the directory will be used where the script is being executed

*-TargetConnectionString  (String) - Mandatory: False*

`Usage: -TargetConnectionString '<your valid SQL ConnectionString>' `

Specifies a connection string to use. If you use a connection string you can not also use the following parameters:

- -TargetServerName
- -TargetDBName
- -TargetUsername
- -TargetPassword

*-PublishProfile  (String) - Mandatory: False*

`Usage: -PublishProfile c:\<path to publishprofile>.publish.xml`

Specifies a SQL Publishing profile to be used. if this parameter is used it will override results from `-DetectPublishProfile`

*-DetectPublishProfile  (Switch) - Mandatory: False*

`Usage: -DetectPublishProfile`

Triggers the Module to go and find the closest \*.publish.xml file and will use its options. Can be used in cojunction with the following parameters:

- -TargetServerName
- -TargetDBName
- -TargetUsername
- -TargetPassword

If you do they will override any settings regarding the target inside the publishing profile.

*-TargetServerName  (String) - Mandatory: False*

`Usage: -TargetServerName '<your valid SQL Target Server>' `

Specifies a Target server to which the SQL Database needs to be published. Can be local or Azure (just make sure you set up your firewall / NAT correctly when using outside connections)

*-TargetDBName  (String) - Mandatory: False*

`Usage: -TargetDBName '<your valid SQL Target Database (or to be created database)>' `

Specifies a Target Database to which the SQL Database needs to be published.

*-TargetUserName  (String) - Mandatory: False*

`Usage: -TargetUserName '<your valid SQL User>' `

Specifies a Target username (SQL Authentication) to which the SQL Database needs to be published.

*-TargetServerName  (String) - Mandatory: False*

`Usage: -TargetPassword '<your valid Password>' `

Specifies the password for `-TargetUsername`

*-hidden  (Switch) - Mandatory: False*

`Usage: -hidden`

if this switch is used the output from SQLPackage will be hidden from the screen and only outcome will be presented.

*-Keeplogfiles  (Switch) - Mandatory: False*

`Usage: -Keeplogfiles`

if this switch is used the logfiles (including errorlog files will not be deleted when the outcome is successfull.)

#### Usage

```Powershell
Invoke-MSSQLCICDHelperSQLPackage -keeplogfiles
# or assign the output to a variable for later use
$result = Invoke-MSSQLCICDHelperSQLPackage -keeplogfiles -hidden
```

#### Examples

Auto discover dacpac and use Publishing Profile for actual deployment. keep logfiles when deploy is successful:

```Powershell
Invoke-MSSQLCICDHelperSQLPackage -keeplogfiles -Detectpublishprofile
```

Manually assign a dacpac file. keep logfiles when deploy is successful. Hide the output from screen:

```Powershell
Invoke-MSSQLCICDHelperSQLPackage -keeplogfiles -hidden -filename c:\builds\987wd9d93\myawesomedb.dacpac
```

Auto discover dacpac and use manual credentials for deployment. Delete log files after deploy is successful:

```Powershell
Invoke-MSSQLCICDHelperSQLPackage -TargetServername myazure.northeurope.cloudapp.azure.com -TargetDBName myawesomedb -TargetUsername DeployServiceAccount -Targetpassword My_Sup3rStr0nPW!
```

Auto discover dacpac and, use publishingprofile for options and manual credentials for deployment. Delete log files after deploy is successful:

```Powershell
Invoke-MSSQLCICDHelperSQLPackage -PublishProfile C:\builds\828dds3\myawesomedb.publish.xml -TargetServername myazure.northeurope.cloudapp.azure.com -TargetDBName myawesomedb -TargetUsername DeployServiceAccount -Targetpassword My_Sup3rStr0nPW!
```

Auto discover dacpac and use manual credentials for deployment. Delete log files after deploy is successful and specify additional arguments (Timeout = 600 seconds) for SQLPackage:

```Powershell
Invoke-MSSQLCICDHelperSQLPackage -AdditionalArguments '/TargetTimeout:600' -TargetServername myazure.northeurope.cloudapp.azure.com -TargetDBName myawesomedb -TargetUsername DeployServiceAccount -Targetpassword My_Sup3rStr0nPW!
```