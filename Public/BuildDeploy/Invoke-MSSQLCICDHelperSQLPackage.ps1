function Invoke-MSSQLCICDHelperSQLPackage {
    <#
        .SYNOPSIS
        publishes a given DacPac file to specified target.
    
        .DESCRIPTION
        Executes the SQLPackage.exe tool against the specified DacPac file. If no DacPac file is specified the tool will search for one from current directory (root of the Source Code.)
        Returns a hash table with properties for determining if the publish succeeded or not, as well as other information (see the OUTPUTS section for list of properties).
    
        .PARAMETER filename
        The path including file of the DacPac file to publish (e.g. a .dacpac file). 
        If left empty the Module will search Recursively for the nearest Solution file where the basepath will the path where the script is Ran (not to be confused with script location)
    
        .PARAMETER AdditionalArguments
        Additional parameters to pass to the SQLPackage command-line tool. This can be any valid sqlpackage command-line parameter(s) except for the ones mentioned below.
    
        See https://msdn.microsoft.com/library/hh550080(vs.103).aspx#Publish%20Parameters,%20Properties,%20and%20SQLCMD%20Variables for valid SQLPackage command-line parameters.

        Please note that the following parameters are already used / reserverd and should not be used:

        /action
        /SourceFile
        /TargetConnectionString
        /TargetServerName
        /TargetDatabaseName
        /TargetUsername
        /TargetPassword
        
        .PARAMETER logfilepath
        Determines the basepath where logfileoutput will be stored. If left empty the directory will be used where the script is ran.
        
        .PARAMETER TargetConnectionString
        Identifies the Connectionstring to be used for the Target. Will overrule any other $Target<xxx>parameter.
        
        .PARAMETER TargetServerName
        Identifies the Server to be used for the Target. If $TargetConnectionString is used this parameter will be overruled by the connectionstring.
        
        .PARAMETER TargetDBName
        Identifies the Database Name to be used for the Target. If $TargetConnectionString is used this parameter will be overruled by the connectionstring.
        
        .PARAMETER TargetUserName
        Identifies the Username to be used for the Target. If $TargetConnectionString is used this parameter will be overruled by the connectionstring.
        
        .PARAMETER TargetPassword
        Identifies the password to be used for the Target. If $TargetConnectionString is used this parameter will be overruled by the connectionstring.
        
        .PARAMETER hidden
        Switch to use when output from the command line tool needs to be hidden instead of shown.
    
        .PARAMETER keeplogfiles
        Switch to specify that log files should be deleted. only applies on successfull output.
    
    
        .OUTPUTS
        a hashtable with the following details is returned (whether or not using Invoke-MSBuild as the executor):
    
        BuildSucceeded = $true if the process Succeeded, $false if the Process failed, and $null if we are not sure.
        LogFilePath = The path to the process log file.
        Logfile = filename of logfile which was used in the process.
        ErrorLogFilePath = The path to the Process error log file.
        ErrorLogfile = filename of the errorlogfile.
        FiletoBuild = The item that SQLPackage ran against.
        CommandUsedToBuild = The full command that was used to invoke SQLPackage. This can be useful for inspecting what parameters are passed to SQLPackage.exe.
        Message = A message describing any problems that were encoutered by the process. This is typically an empty string unless something went wrong.
        Duration = The amount of time the process took to complete, represented as a TimeSpan.
        
    
        .EXAMPLE
        
        Invoke-MSSQLCICDHelperSQLPackage -filename <path to file to publish> -TargetconnectionString -logfilepath c:\logs\builds
        
        Will Run Invoke-MSSQLCICDHelperSQLPackage with the default settings other than filename and logfilepath
        Filename = given file
        logfiles will be stored in c:\logs\builds\
        Non hidden
        Delete logfiles when successfull.
        Will use the designated Connection string.

        .EXAMPLE
        
        Invoke-MSSQLCICDHelperSQLPackage -TargetServerName <local or azure machine> -TargetDBName myawesomedb -TargetUsername sa -targetPassword Very_Str0nPa$$W0rd01
        
        Will Run Invoke-MSSQLCICDHelperSQLPackage with the default settings
        Filename = will search for a dacpac from the current directory.
        Non hidden
        Delete logfiles when successfull.
        Will use the mentioned credentials

        .EXAMPLE
        
        Invoke-MSSQLCICDHelperSQLPackage -KeepLogfiles -hidden -TargetServerName <local or azure machine> -TargetDBName myawesomedb -TargetUsername sa -targetPassword Very_Str0nPa$$W0rd01
        
        Will Run Invoke-MSSQLCICDHelperSQLPackage with the default settings
        Filename = will search for a dacpac from the current directory.
        hidden
        Don't Delete logfiles when successfull.
        Will use the mentioned credentials

        .EXAMPLE
        
        Invoke-MSSQLCICDHelperSQLPackage -Verbose -TargetServerName <local or azure machine> -TargetDBName myawesomedb -TargetUsername sa -targetPassword Very_Str0nPa$$W0rd01
        
        Will Run Invoke-MSSQLCICDHelperSQLPackage with the default settings with added verbosity in it's output.
        Filename = will search for a dacpac from the current directory.
        Not hidden
        Delete logfiles when successfull.
        Will use the mentioned credentials
    
        .EXAMPLE
        
        Invoke-MSSQLCICDHelperSQLPackage -AdditionalArguments "/TargetTimeout:600" -TargetServerName <local or azure machine> -TargetDBName myawesomedb -TargetUsername sa -targetPassword Very_Str0nPa$$W0rd01
        
        Will Run Invoke-MSSQLCICDHelperSQLPackage with additional SQLPackage parameters. 
        See https://msdn.microsoft.com/library/hh550080(vs.103).aspx#Publish%20Parameters,%20Properties,%20and%20SQLCMD%20Variables for valid SQLPackage command-line parameters.

        Please note that the following parameters are already used / reserverd and should not be used:

        /action
        /SourceFile
        /TargetConnectionString
        /TargetServerName
        /TargetDatabaseName
        /TargetUsername
        /TargetPassword

        Filename = Autodetect
        Non hidden
        Delete logfiles when successfull.
    
    
        .LINK
        Project home: https://github.com/tsteenbakkers/MSSQL-CICD-Tools
    
        .NOTES
        Name:   MSSQLCICDHelper
        Author: Tobi Steenbakkers
        Version: 1.0.0
    #>
        
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$false,
                   HelpMessage='Filename which should be used for publish. If empty it will find the nearest Solution based on the directory it was invoked from.',
                   Position=0)]
            
            [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
            $filename,

            [Parameter(Mandatory=$false,
                   HelpMessage='Provides additional Arguments. Example "/TargetTimeout:600"',
                   Position=0)]
            [Alias("Parameters","Params","P")]
            [ValidateNotNullOrEmpty()]
            [String] $AdditionalArguments,

            [Parameter(Mandatory=$false,
                   HelpMessage='Determines the basepath where logfiles should be stored. if empty the directory where the script is running will be used',
                   Position=0)]
            [Alias("lfp")]
            [ValidateNotNullOrEmpty()]
            [String] $logfilepath,
            
            [Parameter(Mandatory=$false,
                   HelpMessage='Determines Target for publishing based on a connectionstring',
                   Position=0)]
            [Alias("tconstr")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetConnectionString,

            
            [Parameter(Mandatory=$false,
                   HelpMessage='Determines Target Server for publishing',
                   Position=0)]
            [Alias("tsn", "TargetServer")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetServerName,

            
            
            [Parameter(Mandatory=$false,
                   HelpMessage='Determines Target Database for publishing',
                   Position=0)]
            [Alias("tdn","TargetDB")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetDBName,
            
            
            
            [Parameter(Mandatory=$false,
                   HelpMessage='Determines Target Username for publishing',
                   Position=0)]
            [Alias("tu", "TargetUser")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetUserName,
            
            
            [Parameter(Mandatory=$false,
                   HelpMessage='Determines Target Password for publishing',
                   Position=0)]
            [Alias("tp", "TargetPass")]
            [ValidateNotNullOrEmpty()]
            [String] $TargetPassWord,

            [Parameter(Mandatory=$false,
                   HelpMessage='Switch to only retrieve the outcome of sqlpackage. Hides the SQLPackage.exe on screen.',
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
                $logfile = "{0}\$($filename.name).SQLPackage.log" -f $logfilepath
                $errorlogfile = "{0}\$($filename.name).SQLPackage.errors.log" -f $logfilepath
            }else{
                $logfile = "{0}\$($filename.name).SQLPackage.log" -f $curdir
                $errorlogfile = "{0}\$($filename.name).SQLPackage.errors.log" -f $curdir
            }
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
                    $shownarguments = "$arguments /tsn:$($targetservername) /tdn:$($TargetDBName) /tu:$($targetUsername) /tp:******"
                }else{
                    #Write-Error "Some of the target Credentials are not filled"
                    #break;
                }
            }

            if($AdditionalArguments){
                Write-Verbose "The following additional build arguments will be used: $AdditionalArguments"
                $arguments += " $additionalarguments"
                $shownarguments += " $additionalarguments"
            }
            
            #closing arguments with an exit statement to return to powershell
            $arguments += " & Exit"" "
            $shownarguments += " & Exit"" "
            
            Write-Verbose "The following Arguments will be used: $shownarguments"
            $result.CommandUsedToBuild = "cmd.exe $shownarguments"
            
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
        if(!$hidden){
            
            $output

        }
        
    
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
    
    