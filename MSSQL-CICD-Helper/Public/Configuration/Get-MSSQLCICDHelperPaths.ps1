Function Get-MSSQLCICDHelperPaths {
<#
	.SYNOPSIS
	Searches the system recursively for the given rootpath for the given type to find.

	.DESCRIPTION
    Searches the system recursively for the given rootpath for the given type to find.
    The function returns a full filename of the chosen type for aid in Save-MSSQLCICDHelperConfiguration
    if multiple occurrences are found for the chosen type it will return all.


    .PARAMETER typetofind
    Determines the kind of file to find. Accepts MSBuild, SQLPackage or Both as inputs
    Mandatory

    .PARAMETER rootpath
    Specifies the path where the function needs to start looking for the $typetofind
    Mandatory

	.OUTPUTS
	A filename (full path) to the file the function is supposed to find based on its rootpath and type to find. 

    .EXAMPLE
    
    Get-MSSQLCICDHelperPaths -typetofind MSBuild -rootpath C:\
    
    Will Search C:\ for MSBuild.exe.
    
    .EXAMPLE
    
    Get-MSSQLCICDHelperPaths -typetofind SQLPackage -rootpath C:\
    
    Will Search C:\ for SQLPackage.exe.
    .EXAMPLE
    
    Get-MSSQLCICDHelperPaths -typetofind Both -rootpath C:\
    
    Will Search C:\ for MSBuild.exe and SQLPackage.exe.
    
    .LINK
	Project home: https://github.com/tsteenbakkers/MSSQL-CICD-Helper

	.NOTES
	Name:   MSSQLCICDHelper
	Author: Tobi Steenbakkers
	Version: 1.0.0
#>
    [cmdletbinding()]
    [OutputType('mssqlcicd.Setting')]
    param(
        [Parameter(Mandatory=$true,
               HelpMessage='What to find: MSBuild, SQLPackage or Both',
               Position=0)]
        [ValidateNotNullOrEmpty()]
        $typetofind,

        [Parameter(Mandatory=$true,
               HelpMessage='Path where search for $typetofind should be started',
               Position=0)]
        [ValidateNotNullOrEmpty()]
        $rootpath
    )
    
    $exestofind = @()

    switch($typetofind){
        "MSBuild"{
            $exestofind += 'MSBuild.exe'
        }
        "SQLPackage"{
            $exestofind += 'SQLPackage.exe'
        }
        "Both"{
            $exestofind += 'MSBuild.exe'
            $exestofind += 'SQLPackage.exe'
        }
        default {
            Write-Error "Invalid option given for input param -typetofind. valid options are: MSBuild, SQLPackage or Both"
            throw;
        }
    }
    Write-verbose "searching for $exestofind in $rootpath"

    $exestofind | ForEach-Object{
        $results += Get-ChildItem -Path $rootpath -filter $_ -Recurse -ErrorAction SilentlyContinue
    }
    Write-Output 'Found the following full paths for given parameters. Please take note of these and use the desired path in Save-MSSQLCICDHelperConfiguration'
    $results.FullName
}