Param(
    $Function,
    $targetserver,
    $targetdatabase,
    $targetuser,
    $targetpw
)

if(-not(Get-Module MSSQLCICDHelper)){
    try{
        $isGitInstalled = $null -ne ( (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*) + (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*) | Where-Object { $null -ne $_.DisplayName -and $_.Displayname.Contains('Git') })
        if($isGitInstalled){
            git clone https://github.com/tsteenbakkers/MSSQL-CICD-Helper.git
        }
        else{
            Write-Error "Git is not installed. Make sure it is installed and try again!"
        }
        
        $curdir = Get-Location
        $modulefile = "{0}\MSSQL-CICD-Helper\MSSQLCICDHelper.psd1" -f $curdir
        
        Import-Module -name $modulefile -Verbose
    }
    catch{
        write-error "something wnet wrong cloning or importing the MSSQL-CICD-helper module. please check and retry"
        Throw;
    }
    
    
}

switch ($function) {
    "build"{
        Invoke-MSSQLCICDHelperMSBuild -Verbose -keeplogfiles
    }
    "Deploy"{
        Invoke-MSSQLCICDHelperSQLPackage -Verbose -keeplogfiles -tsn $targetserver -tdn $targetdatabase -tu $targetuser -tp $targetpw
    }
    Default {
        Write-Error "invalid function chosen."
        break;
    }
}