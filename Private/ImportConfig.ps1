Function ImportConfig {
<#
.Synopsis
   Check for configuration and output the information.
.DESCRIPTION
   Check for configuration and output the information. Goes into the $env:appdata for the configuration file.
.EXAMPLE
    ImportConfig
#>

    if ( $IsWindows -or ( [version]$PSVersionTable.PSVersion -lt [version]"5.99.0" ) ) {
        $ConfigFile = "{0}\MSSQLCICDHelper\MSSQLCICDHelperConfiguration.xml" -f $env:appdata
    } elseif ( $IsLinux ) {
        $ConfigFile = "{0}/.MSSQLCICDHelper/MSSQLCICDHelperConfiguration.xml" -f $HOME
    } else {
        Write-Error "Unknown Platform"
    }
    if (Test-Path $ConfigFile) {
        Import-Clixml $ConfigFile

    } else {
        Write-Warning 'No saved configuration information found. Run Save-MSSQL-CICD-HelperConfiguration.'
        break;
    }
}
