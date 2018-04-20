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
        
        Write-Verbose "The following build arguments will be used: $MSBuildArguments"
        $configfile['MSBuildExe']

        Write-Verbose "Constructing Command to build..."
        if(-not($UseInvokeMSBuildModule)){

            $CommandtoExecute = "/k "" ""$($configfile['MSBuildExe'])"" ""$($filename.FullName)"" /fl /flp:logfile=""$($logfile)"" $($MSBuildArguments) & Exit"" " 

            Write-Verbose "Command to be Executed is: cmd.exe $commandtoexecute"
            $result.CommandUsedToBuild = "Command to be Executed is: cmd.exe $commandtoexecute"

            if($hidden){
                $result.MsBuildProcess = Start-Process cmd.exe -ArgumentList $CommandtoExecute -Wait -WindowStyle Hidden -PassThru
            }else{
                $result.MsBuildProcess = Start-Process cmd.exe -ArgumentList $CommandtoExecute -Wait -NoNewWindow -PassThru
            }
        }else{
            if ($InvokeMSBuildParameters){
                $CommandtoExecute = "Invoke-MSBuild -Path $($filename.FullName) -logdirectory $($logbase) $($InvokeMSBuildParameters)"
            }else{
                $CommandtoExecute = "Invoke-MSBuild -Path $($filename.FullName) -logdirectory $($logbase)"
            }

            if($keeplogfiles){
                $CommandtoExecute += " -KeepBuildLogOnSuccessfulBuilds"
            }
            $result.CommandUsedToBuild = "Command to be Executed is: $commandtoexecute"
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
    
    Write-verbose "result exit code was: $($result.ExitCode)"
    #$result
    $result
}

