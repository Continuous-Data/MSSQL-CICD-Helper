Function ImportConfig {
<#
.Synopsis
   Check for configuration and output the information.
.DESCRIPTION
   Check for configuration and output the information. Goes into the $env:appdata for the configuration file.
.EXAMPLE
    ImportConfig
#>
    $currentversion = CurrentVersion

    if ( $IsWindows -or ( [version]$PSVersionTable.PSVersion -lt [version]"5.99.0" ) ) {
        $ConfigFile = "{0}\MSSQLCICDHelper\MSSQLCICDHelperConfiguration.xml" -f $env:appdata
    } elseif ( $IsLinux ) {
        $ConfigFile = "{0}/.MSSQLCICDHelper/MSSQLCICDHelperConfiguration.xml" -f $HOME
    } else {
        Write-Error "Unknown Platform"
    }
    if (Test-Path $ConfigFile) {
        $config = Import-Clixml $ConfigFile
        #$config
        if($config.version -ne $currentversion){
            Write-Warning "Warning! current version = $currentversion. found version in config is $($config.version). This might lead to incompatibility issues. Please Run Save-MSSQL-CICD-HelperConfiguration or update your software (https://github.com/tsteenbakkers/MSSQL-CICD-Helper) if you experience issues."
            return $config
        }else{
            return $config
        }
        

    } else {
        Write-Warning 'No saved configuration information found. Run Save-MSSQL-CICD-HelperConfiguration.'
        Write-Warning "path which was looked for: $configfile"
        throw;
    }
}
