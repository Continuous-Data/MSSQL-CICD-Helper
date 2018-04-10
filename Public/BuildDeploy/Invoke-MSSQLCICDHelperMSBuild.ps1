function Invoke-MSSQLCICDHelperMSBuild {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false,
               HelpMessage='What to find: *.sln, *.dacpac, *.dtspac or *.sqlproject File. Options are: Solution, DacPac, DTSPack or Project',
               Position=0)]
        
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $filename,
        [Parameter(Mandatory=$true,
               HelpMessage='Provides Build Arguments. Example /target:clean;build',
               Position=0)]
        [Alias("Parameters","Params","P")]
        [ValidateNotNullOrEmpty()]
        $MSBuildArguments
    )

    $configfile = ImportConfig 

    if($null -eq $filename){
        $curdir = Get-location
        write-verbose "No filename given. Running Get-MSSQLCICDHelperFiletoBuildDeploy based to find the Solution in current script path $curdir"
        $filename = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind 'Solution' -RootPath $curdir
    }
    else{
        $filename = Get-ChildItem $filename
    }
    
    Write-Verbose "The following file will be built: $($filename.Name) located in path $($filename.DirectoryName)"
    
    
    Write-Verbose "The following build arguments will be used: $MSBuildArguments"
    $configfile['MSBuildExe']

    Write-Verbose "Constructing Command to build..."

    $CommandtoExecute = "/k "" ""$($configfile['MSBuildExe'])"" ""$($filename.FullName)"" "

    Write-Verbose "Command to be Executed is: cmd.exe $commandtoexecute"

    Start-Process cmd.exe -ArgumentList $CommandtoExecute -NoNewWindow -PassThru
}

