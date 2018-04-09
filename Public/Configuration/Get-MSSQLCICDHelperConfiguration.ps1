function Get-MSSQLCICDHelperConfiguration  {
    Write-Output ' This Function will only display the config file. To assign a variable use ImportConfig'
    $ConfigFile = ImportConfig

    Write-Output $ConfigFile
}

