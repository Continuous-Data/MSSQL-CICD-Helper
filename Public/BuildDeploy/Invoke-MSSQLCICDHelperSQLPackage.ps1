function Invoke-MSSQLCICDHelperSQLPackage {
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
        LogFilePath = The path to the build's log file.
        BuildErrorsLogFilePath = The path to the build's error log file.
        FiletoBuild = The item that MsBuild ran against.
        CommandUsedToBuild = The full command that was used to invoke MsBuild. This can be useful for inspecting what parameters are passed to MsBuild.exe.
        Message = A message describing any problems that were encoutered by Invoke-MsBuild. This is typically an empty string unless something went wrong.
        MsBuildProcess = The process that was used to execute MsBuild.exe.
        Duration = The amount of time the build took to complete, represented as a TimeSpan.
    
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
            [String] $AdditionalArguments,

            [Parameter(Mandatory=$false,
                   HelpMessage='Provides Build Arguments. Example /target:clean;build',
                   Position=0)]
            [Alias("lfp")]
            [ValidateNotNullOrEmpty()]
            [String] $logfilepath,
            
            [Parameter(Mandatory=$false,
                   HelpMessage='Provides Build Arguments. Example /target:clean;build',
                   Position=0)]
            [Alias("tconstr")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetConnectionString,

            
            [Parameter(Mandatory=$false,
                   HelpMessage='Provides Build Arguments. Example /target:clean;build',
                   Position=0)]
            [Alias("tsn", "TargetServer")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetServerName,

            
            
            [Parameter(Mandatory=$false,
                   HelpMessage='Provides Build Arguments. Example /target:clean;build',
                   Position=0)]
            [Alias("tdn","TargetDB")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetDBName,
            
            
            
            [Parameter(Mandatory=$false,
                   HelpMessage='Provides Build Arguments. Example /target:clean;build',
                   Position=0)]
            [Alias("tu", "TargetUser")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetUserName,
            
            
            [Parameter(Mandatory=$false,
                   HelpMessage='Provides Build Arguments. Example /target:clean;build',
                   Position=0)]
            [Alias("tp", "TargetPass")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetPassWord,

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
            [switch] $keeplogfiles 
        )
        
        $result = @{}
        $result.CommandUsedToBuild = [string]::Empty
        $result.MsBuildProcess = $null
        $result.BuildSucceeded = $null
        $result.Message = [string]::Empty
        $result.Duration = [TimeSpan]::Zero
        $result.LogFilePath = $null
        $result.LogFile = $null
        $result.ErrorLogFilePath = $null
        $result.ErrorLogFile = $null
        $result.FiletoBuild = $null

        try{
    
    
            $configfile = ImportConfig 
            $curdir = Get-location
            
            if($null -eq $filename){
                
                write-verbose "No filename given. Running Get-MSSQLCICDHelperFiletoBuildDeploy based to find the Solution in current script path $curdir"
                $filename = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind 'dacpac' -RootPath $curdir | Get-ChildItem
            }
            else{
                $filename = Get-ChildItem $filename
            }
            $filename 
            write-Verbose "The following file will be built: $($filename.Name) located in path $($filename.DirectoryName)"
            
            
            if($logfilepath){
                $logfile = "$($logfilepath)"
            }else{
                $logfile = "{0}\$($filename.name).SQLPackage.log" -f $curdir
            }
            $errorlogfile = "{0}\$($filename.name).SQLPackage.errors.log" -f $curdir
            $logbase = Split-Path -path $logfile -Parent
            $result.LogFilePath = $logbase
            $result.LogFile = $logfile
            $result.ErrorLogFilePath = $logbase
            $result.ErrorLogFile = $errorlogfile
            $result.FiletoBuild = $filename.FullName 

            
            
                
            Write-Verbose "Constructing Command to build..."

            $arguments = "/k "" ""$($configfile['SQLPackageExe'])"""

            $arguments += " /a:Publish"
            $arguments += " /sf:""$($filename)"""

            if($TargetConnectionString){

                $arguments += " /tcs:$TargetConnectionString"

            }else{
                if($TargetServerName -and $TargetDBName -and $TargetUserName -and $TargetPassWord){
                    $arguments += " /tsn:$($targetservername) /tdn:$($TargetDBName) /tu:$($targetUsername) /tp:$($targetPassword)"

                }else{
                    #Write-Error "Some of the target Credentials are not filled"
                    #break;
                }
            }

            if($AdditionalArguments){
                Write-Verbose "The following additional build arguments will be used: $AdditionalArguments"
                $arguments += " $additionalarguments"
            }
            
            #closing arguments with an exit statement to return to powershell
            $arguments += " & Exit"" " 
            Write-Verbose "The following Arguments will be used: $arguments"
            $result.CommandUsedToBuild = "cmd.exe $arguments"
            
            #constructing the process and the arguments to send:
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "cmd.exe"
            $pinfo.Arguments = $arguments
            
            #$pinfo.Passthru = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.RedirectStandardOutput = $true
            $pinfo.UseShellExecute = $false

            if($debug){
                $pinfo
            }
            #executing the command and storing the result inside $p:
            $p = New-Object System.Diagnostics.Process
            $p.StartInfo = $pinfo
            $p.Start() | Out-Null

            $output = $p.StandardOutput.ReadToEnd()
            $erroroutput =  $p.StandardError.read()
            $result.Duration = $p.ExitTime - $p.StartTime
            $output | Out-file -literalpath $logfile -Force
            $erroroutput | Out-file -literalpath $errorlogfile -Force


        }catch{
            $errorMessage = $_
            $result.Message = "Unexpected error occurred while building ""$Path"": $errorMessage"
            $result.BuildSucceeded = $false
            Write-Error ($result.Message)
            return $result
            EXIT 1;
        }
        
        Write-verbose "MSBuild Started. Continue Checking results..."
        
        $output
    
        if(!(Test-Path -Path $result.LogFile)){
            $Result.BuildSucceeded = $false
            $result.Message = "Could not find file at '$($result.LogFile)' unable to check for correct build."
    
            Write-Error "$($result.message)"
            return $result
            EXIT 1;
        }
        
        
        [bool] $buildReturnedSuccessfulExitCode = $p.ExitCode -eq 0
        [bool] $buildOutputDoesNotContainFailureMessage = (((Select-String -Path $($result.LogFile) -Pattern "Could not deploy package" -SimpleMatch) -eq $null) -or ((Select-String -Path $($result.LogFile) -Pattern "Initializing deployment (Failed)" -SimpleMatch) -eq $null))
        [bool] $buildOutputDoesContainSuccesseMessage = (Select-String -Path $($result.LogFile) -Pattern "Successfully published database." -SimpleMatch -Quiet) -eq $true
        
        $buildSucceeded = $buildOutputDoesNotContainFailureMessage -and $buildReturnedSuccessfulExitCode -and $buildOutputDoesContainSuccesseMessage
        
        if ($buildSucceeded -eq $true){

            $result.BuildSucceeded = $true
            $result.Message = "Build Passed Successfully"
    
            if (!$keeplogfiles)
                {
                    if (Test-Path $($result.LogFile) -PathType Leaf) { Remove-Item -Path $($result.LogFile) -Force }
                    if (Test-Path $($result.ErrorLogFile) -PathType Leaf) { Remove-Item -Path $($result.ErrorLogFile) -Force }

                    $result.LogFile = $null
                    $result.ErrorLogFile = $null
                }
    
    
        }else{

            $result.BuildSucceeded = $false
            $result.Message = "Building ""$($result.FiletoBuild)"" Failed! Please check ""$($result.LogFile)"" "
            $result
            Write-Error "$($result.message)"
            EXIT 1;

        }
    
        Write-Verbose "MSBuild passed. See results below..."
        $result
        
    }
    
    