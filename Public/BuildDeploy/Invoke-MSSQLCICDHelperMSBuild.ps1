function Invoke-MSSQLCICDHelperMSBuild {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false,
               HelpMessage='What to find: *.sln, *.dacpac, *.dtspac or *.sqlproject File. Options are: Solution, DacPac, DTSPack or Project',
               Position=0)]
        
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $filename,
        [Parameter(Mandatory=$false,
               HelpMessage='Provides Build Arguments. Example /target:clean;build',
               Position=0)]
        [Alias("Parameters","Params","P")]
        [ValidateNotNullOrEmpty()]
        [String] $MSBuildArguments,

        [Parameter(Mandatory=$false,
               HelpMessage='Switch to only retrieve the outcome of MSBuild. Hides the MSBuildProces',
               Position=0)]
        #[Alias("Parameters","Params","P")]
        [ValidateNotNullOrEmpty()]
        [switch] $hidden,

        [Parameter(Mandatory=$false,
               HelpMessage='Switch to use the Invoke-MSBuild Module instead of built-in process.',
               Position=0)]
        #[Alias("Parameters","Params","P")]
        [ValidateNotNullOrEmpty()]
        [switch] $UseInvokeMSBuildModule,

        [Parameter(Mandatory=$false,
               HelpMessage='Provide the optional parameters for Invoke-MSBuild ($path will be provided from this script based on $filename)',
               Position=0)]
        #[Alias("Parameters","Params","P")]
        [ValidateNotNullOrEmpty()]
        [String] $InvokeMSBuildParameters
    )

    if($UseInvokeMSBuildModule){
        if(-not(Get-Module Invoke-MSBuild)){
            Write-Error 'Invoke-MSBuild was not found on this system. Make sure it is installed with Install-Module Invoke-MSBuild'
            break;
        }
        
    }
    $result = @{}
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
    if(-not($UseInvokeMSBuildModule)){

        $CommandtoExecute = "/k "" ""$($configfile['MSBuildExe'])"" ""$($filename.FullName)"" $($MSBuildArguments) & Exit"" " 

        Write-Verbose "Command to be Executed is: cmd.exe $commandtoexecute"
        if($hidden){
            $result = Start-Process cmd.exe -ArgumentList $CommandtoExecute -Wait -WindowStyle Hidden -PassThru
        }else{
            $result = Start-Process cmd.exe -ArgumentList $CommandtoExecute -Wait -NoNewWindow -PassThru
        }
    }else{
        if ($InvokeMSBuildParameters){
            $command = "Invoke-MSBuild -Path $($filename.FullName) $($InvokeMSBuildParameters)"
            $command
            $result = Invoke-Expression $command
        }else{
            $result = Invoke-MSBuild -Path $($filename.FullName)
        }
        
    }
    
    Write-verbose "result exit code was: $($result.ExitCode)"
    #$result
    $result.BuildSucceeded
}

