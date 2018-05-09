function Invoke-MSSQLCICDHelperMSBuild {
<#
	.SYNOPSIS
	Builds the given Visual Studio solution or project file using MsBuild.

	.DESCRIPTION
	Executes the MsBuild.exe tool against the specified Visual Studio solution or project file.
	Returns a hash table with properties for determining if the build succeeded or not, as well as other information (see the OUTPUTS section for list of properties).

	.PARAMETER filename
    The path of the Visual Studio solution or project to build (e.g. a .sln or .csproj file). 
    If left empty the Module will search Recursively for the nearest Solution file where the basepath will the path where the script is Ran (not to be confused with script location)

	.PARAMETER MSBuildArguments
	Additional parameters to pass to the MsBuild command-line tool. This can be any valid MsBuild command-line parameters except for the path of
	the solution/project to build.

	See http://msdn.microsoft.com/en-ca/library/vstudio/ms164311.aspx for valid MsBuild command-line parameters.

    .PARAMETER hidden
    Switch to use when output from the MSBuild command line tool needs to be hidden instead of shown. 
    When using the Invoke-MSBuild feature you need to explicitly tell it to show info with "-ShowBuildOutputInCurrentWindow" or something similar given to Parameter -InvokeMSBuildParameters


    .PARAMETER keeplogfiles
    Switch to specify that log files should be deleted. only applies on successfull builds.


    .PARAMETER UseInvokeMSBuildModule
    Instead of using the MSBuildfeatures from MSSQL-CICD-Helper the more advanced Invoke-MSBuild can be called.

    .PARAMETER InvokeMSBuildParameters
    This Parameter is used as a string to pass additional parameters to the Invoke-MSBuild function.
    Default we pass -Path, -LogDirectory and -KeepBuildLogOnSuccessfulBuilds so keep away from those.

	.OUTPUTS
	a hashtable with the following details is returned (whether or not using Invoke-MSBuild as the executor):

	BuildSucceeded = $true if the build passed, $false if the build failed, and $null if we are not sure.
	BuildLogFilePath = The path to the build's log file.
	BuildErrorsLogFilePath = The path to the build's error log file.
	FiletoBuild = The item that MsBuild ran against.
	CommandUsedToBuild = The full command that was used to invoke MsBuild. This can be useful for inspecting what parameters are passed to MsBuild.exe.
	Message = A message describing any problems that were encoutered by Invoke-MsBuild. This is typically an empty string unless something went wrong.
	MsBuildProcess = The process that was used to execute MsBuild.exe.
	BuildDuration = The amount of time the build took to complete, represented as a TimeSpan.

    .EXAMPLE
    
    Invoke-MSSQLCICDHelperMSBuild
    
    Will Run Invoke-MSSQLCICDHelperMSBuild with the default settings
    Filename = Autodetect
    Non hidden
    Delete logfiles when successfull.
    
    .EXAMPLE
    
    Invoke-MSSQLCICDHelperMSBuild -Verbose
    
    Will Run Invoke-MSSQLCICDHelperMSBuild with the default settings but show verbose output. (this goes for other CMDLetbindings aswell)
    Filename = Autodetect
    Non hidden
    Delete logfiles when successfull.

    .EXAMPLE
    
    Invoke-MSSQLCICDHelperMSBuild -filename <path to file to build>
    
    Will Run Invoke-MSSQLCICDHelperMSBuild with the default settings other than filename
    Filename = given file
    Non hidden
    Delete logfiles when successfull.

    .EXAMPLE
    
    Invoke-MSSQLCICDHelperMSBuild -KeepLogfiles -hidden
    
    Will Run Invoke-MSSQLCICDHelperMSBuild with not showing ouput and keeping logfiles when done.
    Filename = Autodetect
    hidden
    Don't Delete logfiles when successfull.

    .EXAMPLE
    
    Invoke-MSSQLCICDHelperMSBuild -MSBuildArguments "t:build"
    
    Will Run Invoke-MSSQLCICDHelperMSBuild with additional msbuild parameters. 
    See http://msdn.microsoft.com/en-ca/library/vstudio/ms164311.aspx for valid MsBuild command-line parameters.

    Filename = Autodetect
    Non hidden
    Delete logfiles when successfull.

    .EXAMPLE
    
    Invoke-MSSQLCICDHelperMSBuild -UseInvokeMSBuildModule
    
    Will Run Invoke-MSBuild with the default settings. The Following parameters will automatically be supplied to Invoke-MSBuild: -Path $filename (or auto-detect), -LogDirectory Parent of $filename and -KeepBuildLogOnSuccessfulBuilds because we want to have files to check.
    Filename = Auto-Detect
    Hidden by default
    Delete logfiles when successfull.

    .EXAMPLE
    
    Invoke-MSSQLCICDHelperMSBuild -UseInvokeMSBuildModule -InvokeMSBuildParameters <params to pass in valid powershell formatting -paramname value>
    
    Will Run Invoke-MSBuild with the additional settings specified. keep away from below settings because we automatically feed them to the function and can't be specified twice
    The Following parameters will automatically be supplied to Invoke-MSBuild: -Path $filename (or auto-detect), -LogDirectory Parent of $filename and -KeepBuildLogOnSuccessfulBuilds because we want to have files to check.

    See https://github.com/deadlydog/Invoke-MsBuild for valid optional Parameters.

    Filename = Auto-Detect
    Hidden by default
    Delete logfiles when successfull.

    .LINK
	Project home: https://github.com/tsteenbakkers/MSSQL-CICD-Tools

	.NOTES
	Name:   MSSQLCICDHelper
	Author: Tobi Steenbakkers (partly based on the Invoke-MSBuild Module by Daniel Schroeder https://github.com/deadlydog/Invoke-MsBuild)
	Version: 1.0.0
#>
    
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false,
               HelpMessage='Filename which should be used for building. If empty it will find the nearest Solution based on the directory it was invoked from.',
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
               HelpMessage='Switch to only retrieve the outcome of MSBuild. Hides the MSBuildProces on screen. When using Invoke-MSBuild the default setting for invoking the function will be hidden.',
               Position=0)]
        #[Alias("Parameters","Params","P")]
        [ValidateNotNullOrEmpty()]
        [switch] $hidden,

        [Parameter(Mandatory=$false,
        HelpMessage='Switch to keep the log files after checking them. for results.',
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
        $curdir = Get-location
        
        if($null -eq $filename){
            
            write-verbose "No filename given. Running Get-MSSQLCICDHelperFiletoBuildDeploy based to find the Solution in current script path $curdir"
            $filename = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind 'Solution' -RootPath $curdir | Get-ChildItem
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
            
            $CommandtoExecute += " -MsBuildParameters ""$($MSBuildArguments)"""

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
        EXIT 1;
    }
    
    Write-verbose "MSBuild Started. Continue Checking results..."
 

    if(!(Test-Path -Path $result.BuildLogFile)){
        $Result.BuildSucceeded = $false
        $result.Message = "Could not find file at '$($result.BuildLogFile)' unable to check for correct build."

        Write-Error "$($result.message)"
        return $result
        EXIT 1;
    }

    if($UseInvokeMSBuildModule){
        [bool] $buildReturnedSuccessfulExitCode = $result.MsBuildProcess.MsBuildProcess.ExitCode -eq 0
        $result.BuildDuration = $result.MsBuildProcess.MsBuildProcess.ExitTime - $result.MsBuildProcess.MsBuildProcess.StartTime
    }else{
        [bool] $buildReturnedSuccessfulExitCode = $result.MsBuildProcess.ExitCode -eq 0
        $result.BuildDuration = $result.MsBuildProcess.ExitTime - $result.MsBuildProcess.StartTime
    }
    
    [bool] $buildOutputDoesNotContainFailureMessage = (Select-String -Path $($result.BuildLogFile) -Pattern "Build FAILED." -SimpleMatch) -eq $null
    
    $buildSucceeded = $buildOutputDoesNotContainFailureMessage -and $buildReturnedSuccessfulExitCode

    if ($buildSucceeded -eq $true){
        $result.BuildSucceeded = $true
        $result.Message = "Build Passed Successfully"

        if (!$keeplogfiles)
			{
                if (Test-Path $($result.BuildLogFile) -PathType Leaf) { Remove-Item -Path $($result.BuildLogFile) -Force }
                
                $result.BuildLogFile = $null
			}


    }else{
        $result.BuildSucceeded = $false
        $result.Message = "Building ""$($result.FiletoBuild)"" Failed! Please check ""$($result.BuildLogFile)"" "
        Write-Error "$($result.message)"
        return $result
        EXIT 1;
    }

    Write-Verbose "MSBuild passed. See results below..."
    $result

}

