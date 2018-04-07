Function Save-MSSQLCICDHelperConfiguration {
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

    $PATHS = @{
        MSBuild = $MSBuildExePath
        SQLPackage = $SQLPackageExePath
    }
    
    $pathstoappend = @()
    Write-Output "modify"
    $paths.Keys | ForEach-Object{
        if(-not($paths[$_] -like '*.exe')){
            $pathstoappend += $_
        }
    }
    
    $pathstoappend | ForEach-Object{
        $paths[$_] = "$($paths[$_].trimend('\'))\$($_).exe"
    }

    # testing if either path exists
    $paths.Keys | ForEach-Object {
        if(-not(Test-Path (Split-Path $paths[$_]) ) ) {
            Write-Error "Directory for either MSBuild or SQlPackage was not found."
        }    
    }
    
    

    # Determine if *.exe was supplied or just a path.

    if ( $IsWindows -or ( [version]$PSVersionTable.PSVersion -lt [version]"5.99.0" ) ) {
        
        # $Parameters = @{
        #     Token=(ConvertTo-SecureString -string $Token -AsPlainText -Force)
        #     Domain=$Domain;
        #     APIVersion=$APIVersion;
        # }
        
        $Parameters = @{
            MSBuildExe = $MSBuildExePath;
            SQLPackageExe = $SQLPackageExePath
        }
        
        $ConfigFile = "$env:appdata\MSSQLCICDHelper\MSSQLCICDHelperConfiguration.xml"

    } elseif ( $IsLinux ) {


        $Parameters = @{
            MSBuildExe = $MSBuildExePath;
            SQLPackageExe = $SQLPackageExePath
        }
        
        $ConfigFile = "{0}/.MSSQLCICDHelper/MSSQLCICDHelperConfiguration.xml" -f $HOME

    } else {
        Write-Error "Unknown Platform"
    }

    if (-not (Test-Path (Split-Path $ConfigFile))) {
        New-Item -ItemType Directory -Path (Split-Path $ConfigFile) | Out-Null

    }

    $Parameters | Export-Clixml -Path $ConfigFile
    Remove-Variable Parameters

}
