Function Save-MSSQLCICDHelperConfiguration {
<#
	.SYNOPSIS
	Saves the paths to MSBuild and SQLPackage executables for lates usage.

	.DESCRIPTION
    Stores the paths for both SQLPackage.Exe and MSBuild.Exe for later use. Both paths are mandatory to store.
    The function tests both paths given for existance and stores it in a XML file on APPDATA for windows or Home on Linux.


    .PARAMETER SQLPackageExePath
    Determines the kind of file to find. Accepts MSBuild, SQLPackage or Both as inputs
    Mandatory

    .PARAMETER MSBuildExePath
    Specifies the path where the function needs to start looking for the $typetofind
    Mandatory

	.OUTPUTS
	None
    
    .EXAMPLE
    Save-MSSQLCICDHelperConfiguration -SQLPackageExePath c:\SQLPackage.Exe
    
    Will Store c:\SQLPackage.Exe as the configured path for SQLPackage

    .EXAMPLE
    
    Save-MSSQLCICDHelperConfiguration -MSBuildExePath c:\MSBuild.Exe
    
    Will Store c:\SQLPackage.Exe as the configured path for SQLPackage
    
    .LINK
	Project home: https://github.com/tsteenbakkers/MSSQL-CICD-Helper

	.NOTES
	Name:   MSSQLCICDHelper
	Author: Tobi Steenbakkers
	Version: 1.0.0
#>
[cmdletbinding()]
    param(
    [Parameter(Mandatory=$true,
               HelpMessage='Path can be with or without including *.exe file. You can run Get-MSSQL-CICD-HelperPaths to find the paths for MSBUild / SQLPackage',
               Position=0)]
    [ValidateNotNullOrEmpty()]
    $SQLPackageExePath,

    [Parameter(Mandatory=$true,
    HelpMessage='Path can be with or without including *.exe file. You can run Get-MSSQL-CICD-HelperPaths to find the paths for MSBUild / SQLPackage',
    Position=1)]
    [ValidateNotNullOrEmpty()]
    $MSBuildExePath

    )
    Write-Output 'Config saving procedure started...'
    
    Write-Verbose 'Starting to append paths when input was w/o *.exe file.'

    Write-Output "debugging SQLPackageExePath $SQLPackageExePath"

    Write-Output "debugging SQLPackageExePath $MSBuildExePath"

    $currentversion = CurrentVersion

    $PATHS = @{
        MSBuild = $MSBuildExePath
        SQLPackage = $SQLPackageExePath
    }
    
    $pathstoappend = @()
    #Write-Output "modify"
    $paths.Keys | ForEach-Object{
        if(-not($paths[$_] -like '*.exe')){
            $pathstoappend += $_
        }
    }

    Write-Verbose "The following paths will be appended: $pathstoappend"
    
    $pathstoappend | ForEach-Object{
        $paths[$_] = "$($paths[$_].trimend('\'))\$($_).exe"
    }

    Write-Verbose 'Testing if either appended paths exists with Get-ChildItem.'

    # testing if either path exists
    $paths.Keys | ForEach-Object {
        if(-not(Test-Path ($paths[$_]) ) ) {
            Write-Error "Directory: $($paths[$_]) did not contain either Msbuild or SqlPackage. Please rerun Save-MSSQLCICDHelperConfiguration with a correct path"
            
            throw;
        }    
    }
    
    Write-Verbose 'Finalized paths are:'
    Write-Verbose "$paths"
    Write-Verbose 'Starting to save config'

    if ( $IsWindows -or ( [version]$PSVersionTable.PSVersion -lt [version]"5.99.0" ) ) {
        
        # $Parameters = @{
        #     Token=(ConvertTo-SecureString -string $Token -AsPlainText -Force)
        #     Domain=$Domain;
        #     APIVersion=$APIVersion;
        # }
        
        $Parameters = @{
            MSBuildExe = $PATHS['MSBuild'];
            SQLPackageExe = $PATHS['SQLPackage'];
            Version = $currentversion
        }
        
        $ConfigFile = "$env:appdata\MSSQLCICDHelper\MSSQLCICDHelperConfiguration.xml"

    } elseif ( $IsLinux ) {


        $Parameters = @{
            MSBuildExe = $PATHS['MSBuild'];
            SQLPackageExe = $PATHS['SQLPackage'];
            Version = $currentversion
        }
        
        $ConfigFile = "{0}/.MSSQLCICDHelper/MSSQLCICDHelperConfiguration.xml" -f $HOME

    } else {
        Write-Error "Unknown Platform"
        throw;
    }

    Write-Verbose 'Testing config path.'
    if (-not (Test-Path (Split-Path $ConfigFile))) {
        New-Item -ItemType Directory -Path (Split-Path $ConfigFile) | Out-Null

    }else{
        Write-Verbose "Path $ConfigFile found. Overwriting existing file."
    }

    $Parameters | Export-Clixml -Path $ConfigFile
    Write-Output "Configuration saved in $ConfigFile"
    Remove-Variable Parameters
}
