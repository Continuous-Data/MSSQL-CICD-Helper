function Get-MSSQLCICDHelperFiletoBuildDeploy {
<#
	.SYNOPSIS
	Searches the system recursively for the given rootpath for the given type to find.

	.DESCRIPTION
    Searches the system recursively for the given rootpath for the given type to find.
    The function returns a full filename of the chosen type for aid in building and deploying in CICD Scenario's.
    If multiple of the same type are found it will return an error since only one can be built at once.
    For building solutions with multiple projects specify the solution instead of the project

    .PARAMETER typetofind
    Determines the kind of file to find. Accepts Solution, Project, Dacpac, PublishProfile, DTSPac
    Mandatory

    .PARAMETER rootpath
    Specifies the path where the function needs to start looking for the $typetofind
    Mandatory

	.OUTPUTS
	A filename (full path) to the file the function is supposed to find based on its rootpath and type to find. 

    .EXAMPLE
    Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath C:\
    
    Will Search C:\ for *sln files
    
    .LINK
	Project home: https://github.com/tsteenbakkers/MSSQL-CICD-Tools

	.NOTES
	Name:   MSSQLCICDHelper
	Author: Tobi Steenbakkers
	Version: 1.0.0
#>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,
               HelpMessage='What to find: *.sln, *.dacpac, *.publish.xml *.dtspac or *.sqlproject File. Options are: Solution, DacPac, DTSPack or Project',
               Position=0)]
        [ValidateNotNullOrEmpty()]
        $typetofind,

        [Parameter(Mandatory=$true,
               HelpMessage='Path where search for $typetofind should be started',
               Position=0)]
        [ValidateNotNullOrEmpty()]
        $rootpath
    )

    switch ($typetofind) {
        "solution"{
            $buildfilextension = '*.sln'
        }
        "project"{
            $buildfilextension = '*.sqlproject'
        }
        "DacPac"{
            $buildfilextension = '*.dacpac'
        }
        "PublishProfile"{
            $buildfilextension = '*.publish.xml'
        }
        "DTSPac"{
            $buildfilextension = '*.dtspac'
        }
        default {
            Write-Error "Invalid option given for input param -typetofind. valid options are: Solution, Project, dacpac, PublishProfile or dtspac"
            EXIT 1;
        }
    }

    $results = Get-ChildItem -Path $rootpath -Filter $buildfilextension -Recurse -ErrorAction SilentlyContinue
    
    Write-Verbose "Found $($results.Count) $buildfilextension files in $rootpath"
    
    if($results.Count -lt 1){
        Write-Error 'No Files found! Please check path and re-run Get-MSSQLCICDHelperFiletoBuild. Exiting'
        EXIT 1;
    }
    elseif($results.Count -gt 1){
        Write-Verbose 'Found multiple files. will return the file with the most recent writedatetime.'
        $result = $results | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-ChildItem
    }
    elseif($results.Count -eq 1){
        $result = $results
    }

    $result

}