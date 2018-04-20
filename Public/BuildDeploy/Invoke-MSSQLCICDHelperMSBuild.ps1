function Invoke-MSSQLCICDHelperMSBuild {
    <#
	.SYNOPSIS
	Builds the given Visual Studio solution or project file using MsBuild.

	.DESCRIPTION
	Executes the MsBuild.exe tool against the specified Visual Studio solution or project file.
	Returns a hash table with properties for determining if the build succeeded or not, as well as other information (see the OUTPUTS section for list of properties).

	.PARAMETER Path
	The path of the Visual Studio solution or project to build (e.g. a .sln or .csproj file).

	.PARAMETER MsBuildParameters
	Additional parameters to pass to the MsBuild command-line tool. This can be any valid MsBuild command-line parameters except for the path of
	the solution/project to build.

	See http://msdn.microsoft.com/en-ca/library/vstudio/ms164311.aspx for valid MsBuild command-line parameters.

	.PARAMETER Use32BitMsBuild
	If this switch is provided, the 32-bit version of MsBuild.exe will be used instead of the 64-bit version when both are available.

	.PARAMETER BuildLogDirectoryPath
	The directory path to write the build log files to.
	Defaults to putting the log files in the users temp directory (e.g. C:\Users\[User Name]\AppData\Local\Temp).
	Use the keyword "PathDirectory" to put the log files in the same directory as the .sln or project file being built.
	Two log files are generated: one with the complete build log, and one that contains only errors from the build.

	.PARAMETER LogVerbosity
	If set, this will set the verbosity of the build log. Possible values are: q[uiet], m[inimal], n[ormal], d[etailed], and diag[nostic].

	.PARAMETER AutoLaunchBuildLogOnFailure
	If set, this switch will cause the build log to automatically be launched into the default viewer if the build fails.
	This log file contains all of the build output.
	NOTE: This switch cannot be used with the PassThru switch.

	.PARAMETER AutoLaunchBuildErrorsLogOnFailure
	If set, this switch will cause the build errors log to automatically be launched into the default viewer if the build fails.
	This log file only contains errors from the build output.
	NOTE: This switch cannot be used with the PassThru switch.

	.PARAMETER KeepBuildLogOnSuccessfulBuilds
	If set, this switch will cause the MsBuild log file to not be deleted on successful builds; normally it is only kept around on failed builds.
	NOTE: This switch cannot be used with the PassThru switch.

	.PARAMETER ShowBuildOutputInNewWindow
	If set, this switch will cause a command prompt window to be shown in order to view the progress of the build.
	By default the build output is not shown in any window.
	NOTE: This switch cannot be used with the ShowBuildOutputInCurrentWindow switch.

	.PARAMETER ShowBuildOutputInCurrentWindow
	If set, this switch will cause the build process to be started in the existing console window, instead of creating a new one.
	By default the build output is not shown in any window.
	NOTE: This switch will override the ShowBuildOutputInNewWindow switch.
	NOTE: There is a problem with the -NoNewWindow parameter of the Start-Process cmdlet; this is used for the ShowBuildOutputInCurrentWindow switch.
		  The bug is that in some PowerShell consoles, the build output is not directed back to the console calling this function, so nothing is displayed.
		  To avoid the build process from appearing to hang, PromptForInputBeforeClosing only has an effect with ShowBuildOutputInCurrentWindow when running
		  in the default "ConsoleHost" PowerShell console window, as we know it works properly with that console (it does not in other consoles like ISE, PowerGUI, etc.).

	.PARAMETER PromptForInputBeforeClosing
	If set, this switch will prompt the user for input after the build completes, and will not continue until the user presses a key.
	NOTE: This switch only has an effect when used with the ShowBuildOutputInNewWindow and ShowBuildOutputInCurrentWindow switches (otherwise build output is not displayed).
	NOTE: This switch cannot be used with the PassThru switch.
	NOTE: The user will need to provide input before execution will return back to the calling script (so do not use this switch for automated builds).
	NOTE: To avoid the build process from appearing to hang, PromptForInputBeforeClosing only has an effect with ShowBuildOutputInCurrentWindow when running
		  in the default "ConsoleHost" PowerShell console window, as we know it works properly with that console (it does not in other consoles like ISE, PowerGUI, etc.).

	.PARAMETER MsBuildFilePath
	By default this script will locate and use the latest version of MsBuild.exe on the machine.
	If you have MsBuild.exe in a non-standard location, or want to force the use of an older MsBuild.exe version, you may pass in the file path of the MsBuild.exe to use.

	.PARAMETER VisualStudioDeveloperCommandPromptFilePath
	By default this script will locate and use the latest version of the Visual Studio Developer Command Prompt to run MsBuild.
	If you installed Visual Studio in a non-standard location, or want to force the use of an older Visual Studio Command Prompt version, you may pass in the file path to
	the Visual Studio Command Prompt to use. The filename is typically VsDevCmd.bat.

	.PARAMETER BypassVisualStudioDeveloperCommandPrompt
	By default this script will locate and use the latest version of the Visual Studio Developer Command Prompt to run MsBuild.
	The Visual Studio Developer Command Prompt loads additional variables and paths, so it is sometimes able to build project types that MsBuild cannot build by itself alone.
	However, loading those additional variables and paths sometimes may have a performance impact, so this switch may be provided to bypass it and just use MsBuild directly.

	

	.PARAMETER WhatIf
	If set, the build will not actually be performed.
	Instead it will just return the result hash table containing the file paths that would be created if the build is performed with the same parameters.

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
	$buildResult = Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln"

	if ($buildResult.BuildSucceeded -eq $true)
	{
		Write-Output ("Build completed successfully in {0:N1} seconds." -f $buildResult.BuildDuration.TotalSeconds)
	}
	elseif ($buildResult.BuildSucceeded -eq $false)
	{
		Write-Output ("Build failed after {0:N1} seconds. Check the build log file '$($buildResult.BuildLogFilePath)' for errors." -f $buildResult.BuildDuration.TotalSeconds)
	}
	elseif ($buildResult.BuildSucceeded -eq $null)
	{
		Write-Output "Unsure if build passed or failed: $($buildResult.Message)"
	}

	Perform the default MsBuild actions on the Visual Studio solution to build the projects in it, and returns a hash table containing the results.
	The PowerShell script will halt execution until MsBuild completes.

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

    ####TODO####
    if(-not($keeplogfiles)){
        # delete files after running unless switch
    }
    

}

