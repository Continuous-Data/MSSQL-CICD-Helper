Function Get-MSSQLCICDHelperPaths {
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
            EXIT 1
        }
    }
    Write-verbose "searching for $exestofind in $rootpath"

    $exestofind | ForEach-Object{
        $results += Get-ChildItem -Path $rootpath -filter $_ -Recurse -ErrorAction SilentlyContinue
    }
    Write-Output 'Found the following full paths for given parameters. Please take note of these and use the desired path in Save-MSSQLCICDHelperConfiguration'
    $results.FullName
}