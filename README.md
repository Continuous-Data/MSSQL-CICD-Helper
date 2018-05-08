![CICD Logo](/Private/Images/CICD.png "CICD Logo")
![SQL Logo](/Private/Images/sql.png "SQL Logo")


# MSSQL-CICD-Helper

This repo contains a powershell module which helps and aids in CI / CD processes. The module was born because not every CI / CD tool supports the quirks often presented when trying to implement CI / CD in combination with SQL Server. 

The main issue is that most current CI systems do not help in discovery of files to build / deploy which makes it difficult to automate building processes because your pipeline code needs to be customized for each solution / Database which you want running in your pipeline.

MSSQL-CICD-Helper helps you automate further by not worrying how your SQL Solution is configured. Something i found which would often differ in each project / solution (definitely not a best practice ^^)

## functionality

- find any sln, sqlproject, dacpac, publish XML or dtspac on a runner / container based on the pulled sourcecode
- run MSBuild for SQLProjects / SLN files (with above mentioned auto-discovery)
  - call either built-in MSBuild function or use Invoke-MSBuild
  - Support for adding custom arguments to MSBuild / Invoke-MSBuild (https://github.com/deadlydog/Invoke-MsBuild)
- Deploy / Publish DacPac files (with above mentioned discovery)
  - Support for connectionstrings
  - support for publishing profiles
  - support for custom credentials
  - support for adding any custom arguments to SQLPackage.exe
- discover and save MsBuild.exe / SQLPackage.exe on runner system

## upcoming features

- Building and deploying SSIS packages
- Building and deploying SSAS packages
- Building and deploying SSRS packages
- call a test script such as T-SQLT
- Support for Azure SQL Database (it does support Azure VMs with SQL installed on it)
- maintaining / exporting dacpac prior to deploy
- support for saving environments for deploying (which you should do in your CI system if possible)

## Support

The following CI systems were tested and are supported:

- Jenkins
- Gitlab
- Teamcity
- TFS / VSTS

Please let me know if you have this in place in another CI system so I can add it to the list!

## background

One of the challenges I faced was when we switched CI systems and having to change a lot of the pipeline code because of hardcoded references to either solution / dacpac files. having to change all these references broke code a lot and as such I decided to make a powershell module which is versatile and exchangable when you switch CI systems.

# Installation

Either download this repo and save it with your source code or make a git clone at runtime when you want to build clone (especially needed when running in docker containers)

```Powershell
git clone https://github.com/tsteenbakkers/MSSQL-CICD-Helper.git
```

Then at runtime you need to import this module in order to make the functions available:

```Powershell
Import-Module <path>\MSSQL-CICD-Helper\MSSQLCICDHelper.PSD1
```

if you add a -verbose switch it will also display all the functions exported

# Configuration

Configuration is needed one time at first execution (or when using docker you need to inject your config file after you generate it first). using Save-MSSQLCICDHelperConfiguration will let you store the filepath to SQLPackage.exe and MSBuild.exe

example:

```Powershell
Save-MSSQLCICDHelperConfiguration -SQLPackageExePath c:\SQLPackage.Exe -MSBuildExePath c:\MSBuild.exe
```

This will store c:\MSBuild.exe for calling MSBuild and C:\SQLPackage.exe for calling SQLPackage. The configuration is stored in an PSXML file in the local users AppData folder called 'MSSQLCICDHelperConfiguration.xml'

```windows
C:\Users\<user>\AppData\Roaming\MSSQLCICDHelper\MSSQLCICDHelperConfiguration.xml
```

You don't need to store both executables if you only want to partial functionality but it is advised to store them both. After you've saved the configuration you are set to go.

# Functions