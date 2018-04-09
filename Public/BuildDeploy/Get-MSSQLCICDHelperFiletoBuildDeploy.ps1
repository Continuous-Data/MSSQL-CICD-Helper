function Get-MSSQLCICDHelperFiletoBuildDeploy {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,
               HelpMessage='What to find: *.sln, *.dacpac, *.dtspac or *.sqlproject File. Options are: Solution, DacPac, DTSPack or Project',
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
        "DTSPac"{
            $buildfilextension = '*.dtspac'
        }
        default {
            Write-Error "Invalid option given for input param -Projecttype. valid options are: Solution, Project, dacpac, dtspac"
            break;
        }
    }

    $results = Get-ChildItem -Path $rootpath -Filter $buildfilextension -Recurse -ErrorAction SilentlyContinue
    
    Write-Verbose "Found $($results.Count) $buildfilextension files in $rootpath"
    
    if($results.Count -lt 1){
        Write-Error 'No Files found! Please check path and re-run Get-MSSQLCICDHelperFiletoBuild. Exiting'
        break;
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