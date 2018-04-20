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
        [switch] $keeplogfiles,

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
    
    $result = @{}
    $result.CommandUsedToBuild = [string]::Empty
    $result.MsBuildProcess = $null
    $result.BuildSucceeded = $null
    $result.Message = [string]::Empty
	$result.BuildDuration = [TimeSpan]::Zero
    $result.BuildLogFilePath = $null
    $result.BuildLogFile = $null
    $result.FiletoBuild = $null

    try{

    
        if($UseInvokeMSBuildModule){
            if(-not(Get-Module Invoke-MSBuild)){
                Write-Error 'Invoke-MSBuild was not found on this system. Make sure it is installed with Install-Module Invoke-MSBuild'
                break;
            }
            
        }

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
        
        $logfile = "$($filename.FullName).msbuild.log"
        $logbase = Split-Path -path $logfile -Parent
        $result.BuildLogFilePath = $logbase
        $result.BuildLogFile = $logfile
        $result.FiletoBuild = $filename.FullName 
        
        Write-Verbose "The following build arguments will be used: $MSBuildArguments"
        $configfile['MSBuildExe']

        Write-Verbose "Constructing Command to build..."
        if(-not($UseInvokeMSBuildModule)){

            $CommandtoExecute = "/k "" ""$($configfile['MSBuildExe'])"" ""$($filename.FullName)"" /fl /flp:logfile=""$($logfile)"""
            if ($MSBuildArguments){
                $CommandtoExecute += " $($MSBuildArguments)"
            } 
            $CommandtoExecute += " & Exit"" " 
            #Write-Verbose "Command to be Executed is: cmd.exe $commandtoexecute"
            $result.CommandUsedToBuild = "Command to be Executed is: cmd.exe $commandtoexecute"

            if($hidden){
                Write-verbose "Starting MSBuild ..."
                $result.MsBuildProcess = Start-Process cmd.exe -ArgumentList $CommandtoExecute -Wait -WindowStyle Hidden -PassThru
            }else{
                Write-verbose "Starting MSBuild ..."
                $result.MsBuildProcess = Start-Process cmd.exe -ArgumentList $CommandtoExecute -Wait -NoNewWindow -PassThru
            }
        }else{
            $CommandtoExecute = "Invoke-MSBuild -Path $($filename.FullName) -logdirectory $($logbase)"
            
            $CommandtoExecute += " -KeepBuildLogOnSuccessfulBuilds"

            if ($InvokeMSBuildParameters){
                $CommandtoExecute += " $($InvokeMSBuildParameters)"
            }

            $result.CommandUsedToBuild = "Command to be Executed is: $commandtoexecute"
            Write-verbose "Starting MSBuild ..."
            $result.MsBuildProcess = Invoke-Expression $CommandtoExecute
        }
    }catch{
        $errorMessage = $_
		$result.Message = "Unexpected error occurred while building ""$Path"": $errorMessage"
        $result.BuildSucceeded = $false
        Write-Error ($result.Message)
        return $result
        break;
    }
    
    Write-verbose "MSBuild Started. Continue Checking results..."
 

    if(!(Test-Path -Path $result.BuildLogFile)){
        $Result.BuildSucceeded = $false
        $result.Message = "Could not find file at '$($result.BuildLogFile)' unable to check for correct build."

        Write-Error "$($result.message)"
        return $result
        break;
    }

    if($UseInvokeMSBuildModule){
		[bool] $buildReturnedSuccessfulExitCode = $result.MsBuildProcess.MsBuildProcess.ExitCode -eq 0
    }else{
		[bool] $buildReturnedSuccessfulExitCode = $result.MsBuildProcess.ExitCode -eq 0
    }
    
    [bool] $buildOutputDoesNotContainFailureMessage = (Select-String -Path $($result.BuildLogFile) -Pattern "Build FAILED." -SimpleMatch) -eq $null
    
    $buildSucceeded = $buildOutputDoesNotContainFailureMessage -and $buildReturnedSuccessfulExitCode

    if ($buildSucceeded -eq $true){
        $result.BuildSucceeded = $true
        $result.Message = "Build Passed Successfully"
    }else{
        $result.BuildSucceeded = $false
        $result.Message = "Building ""$($result.FiletoBuild)"" Failed! Please check ""$($result.BuildLogFile)"" "
        Write-Error "$($result.message)"
        return $result
        break;
    }

    Write-Verbose "MSBuild passed. See results below..."
    $result

}

