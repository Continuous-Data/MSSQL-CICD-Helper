function Get-MSSQLCICDHelperConfiguration  {

<#
	.SYNOPSIS
	Retrieves the Stored configuration file.

	.DESCRIPTION
    Calls the private ImportConfig function and returns its values. if it fails it will return an error message.

	.OUTPUTS
	A hashtable with the saved-config file.

    .EXAMPLE    
    Get-MSSQLCICDHelperConfiguration
    
    .LINK
	Project home: https://github.com/tsteenbakkers/MSSQL-CICD-Tools

	.NOTES
	Name:   MSSQLCICDHelper
	Author: Tobi Steenbakkers
	Version: 1.0.0
#>

    Write-Output ' This Function will only display the config file. To assign a variable use ImportConfig'
    try{
        $ConfigFile = ImportConfig

        Write-Output $ConfigFile
    }catch{
        
        Write-Error "Could not import config. Make sure it exists or save a new config." 
    }
    
}

