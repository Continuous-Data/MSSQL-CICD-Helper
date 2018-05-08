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
        /Profile
        /TargetConnectionString
        /TargetServerName
        /TargetDatabaseName
        /TargetUsername
        /TargetPassword
        
        .PARAMETER logfilepath
        Determines the basepath where logfileoutput will be stored. If left empty the directory will be used where the script is ran.
        
        .PARAMETER TargetConnectionString
        Identifies the Connectionstring to be used for the Target. Will overrule any other $Target<xxx>parameter.

        .PARAMETER PublishProfile
        Identifies the filepath for a Publishprofile to be used. 
        If used in conjunction with a targetconnectionstring or any of the other target variables the settings in the Publish profile will be overuled as per default function of SQLPackage. 
        Depending on your setup you will need to use custom credentials next to using a publishing profile.

        .PARAMETER DetectPublishProfile
        Switch to use a publishing profile and have the script detect it. Publishing profiles should always be named *.publish.xml in order to be detected.
        
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
        a hashtable with the following details is returned:
    
        Succeeded = $true if the process Succeeded, $false if the Process failed, and $null if we are not sure.
        LogFilePath = The path to the process log file.
        Logfile = filename of logfile which was used in the process.
        ErrorLogFilePath = The path to the Process error log file.
        ErrorLogfile = filename of the errorlogfile.
        FiletoProcess = The item that SQLPackage ran against.
        CommandUsed = The full command that was used to invoke SQLPackage. This can be useful for inspecting what parameters are passed to SQLPackage.exe.
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
        
        Invoke-MSSQLCICDHelperSQLPackage -Publishprofile C:\builds\<yourname>.publish.xml -TargetServerName <local or azure machine> -TargetDBName myawesomedb -TargetUsername sa -targetPassword Very_Str0nPa$$W0rd01
        
        Will Run Invoke-MSSQLCICDHelperSQLPackage with the default settings
        Filename = will search for a dacpac from the current directory.
        will use the mentioned Publishing profile for non-credential settings
        Non hidden
        Delete logfiles when successfull.
        Will use the mentioned credentials

        .EXAMPLE
        
        Invoke-MSSQLCICDHelperSQLPackage -DetectPublishProfile
        
        Will Run Invoke-MSSQLCICDHelperSQLPackage with the default settings
        Filename = will search for a dacpac from the current directory.
        Publishing profile will be detected from the current directory.
        Non hidden
        Delete logfiles when successfull.
        Credentials are taken from the publishing profile.

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
        /Profile
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
                   HelpMessage='input for path + filename for publishing profile to be used.',
                   Position=0)]
            [Alias("pr")]
            [ValidateNotNullOrEmpty()]
            [String] $PublishProfile,

            [Parameter(Mandatory=$false,
                   HelpMessage='Use this switch if you want to use a publish profile but have it detected by the software. Will override a given $PublishProfile.',
                   Position=0)]
            [Alias("detectpr")]
            [ValidateNotNullOrEmpty()]
            [Switch] $DetectPublishProfile,

            
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
        $result.CommandUsed = [string]::Empty
        $result.Succeeded = $null
        $result.Message = [string]::Empty
        $result.Duration = [TimeSpan]::Zero
        $result.LogFilePath = $null
        $result.LogFile = $null
        $result.ErrorLogFilePath = $null
        $result.ErrorLogFile = $null
        $result.FiletoProcess = $null

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
            #$filename 
            write-Verbose "The following file will be built: $($filename.Name) located in path $($filename.DirectoryName)"
            
            if($DetectPublishProfile){
                write-verbose "No filename given. Running Get-MSSQLCICDHelperFiletoBuildDeploy based to find the Solution in current script path $curdir"
                $PublishProfile = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind 'PublishProfile' -RootPath $curdir | Get-ChildItem
            }
            
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
            $result.FiletoProcess = $filename.FullName 

            
            
                
            Write-Verbose "Constructing Command to execute..."

            $arguments = "/k "" ""$($configfile['SQLPackageExe'])"""

            $arguments += " /a:Publish"
            $arguments += " /sf:""$($filename)"""

            if($TargetConnectionString){

                $arguments += " /tcs:$TargetConnectionString"

            }else{
                if($TargetServerName -and $TargetDBName -and $TargetUserName -and $TargetPassWord){
                    $shownarguments = "$arguments /tsn:$($targetservername) /tdn:$($TargetDBName) /tu:$($targetUsername) /tp:******"
                    $arguments += " /tsn:$($targetservername) /tdn:$($TargetDBName) /tu:$($targetUsername) /tp:$($targetPassword)"
                    
                }else{
                    Write-Error "Some of the target Credentials are not filled"
                    exit 1;
                }
            }

            if($PublishProfile){
                $arguments += " /pr:""$($PublishProfile)"""
                $shownarguments += " /pr:""$($PublishProfile)"""
            }

            if($AdditionalArguments){
                Write-Verbose "The following additional arguments will be used: $AdditionalArguments"
                $arguments += " $additionalarguments"
                $shownarguments += " $additionalarguments"
            }
            
            #closing arguments with an exit statement to return to powershell
            $arguments += " & Exit"" "
            $shownarguments += " & Exit"" "

            Write-Verbose "The following Arguments will be used: $shownarguments"
            $result.CommandUsed = "cmd.exe $shownarguments"
            
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
            $result.Message = "Unexpected error occurred while processing ""$Path"": $errorMessage"
            $result.Succeeded = $false
            Write-Error ($result.Message)
            return $result
            EXIT 1;
        }
        
        Write-verbose "SQLPackage.exe Started. Continue Checking results..."
        if(!$hidden){
            
            $output

        }
        
    
        if(!(Test-Path -Path $result.LogFile)){
            $result.Succeeded = $false
            $result.Message = "Could not find file at '$($result.LogFile)' unable to check for correct execution."
    
            Write-Error "$($result.message)"
            return $result
            EXIT 1;
        }
        
        
        [bool] $ProcessReturnedSuccessfulExitCode = $p.ExitCode -eq 0
        [bool] $ProcessOutputDoesNotContainFailureMessage = (((Select-String -Path $($result.LogFile) -Pattern "Could not deploy package" -SimpleMatch) -eq $null) -or ((Select-String -Path $($result.LogFile) -Pattern "Initializing deployment (Failed)" -SimpleMatch) -eq $null))
        [bool] $ProcessOutputDoesContainSuccesseMessage = (Select-String -Path $($result.LogFile) -Pattern "Successfully published database." -SimpleMatch -Quiet) -eq $true
        
        $ProcessSucceeded = $ProcessOutputDoesNotContainFailureMessage -and $ProcessReturnedSuccessfulExitCode -and $ProcessOutputDoesContainSuccesseMessage
        
        if ($ProcessSucceeded -eq $true){

            $result.Succeeded = $true
            $result.Message = "command executed Successfully"
    
            if (!$keeplogfiles)
                {
                    if (Test-Path $($result.LogFile) -PathType Leaf) { Remove-Item -Path $($result.LogFile) -Force }
                    if (Test-Path $($result.ErrorLogFile) -PathType Leaf) { Remove-Item -Path $($result.ErrorLogFile) -Force }

                    $result.LogFile = $null
                    $result.ErrorLogFile = $null
                }
    
    
        }else{

            $result.Succeeded = $false
            $result.Message = "Processing ""$($result.FiletoProcess)"" Failed! Please check ""$($result.LogFile)"" "
            $result
            Write-Error "$($result.message)"
            EXIT 1;

        }
    
        Write-Verbose "SQLPackage passed. See results below..."
        $result
        
    }
    
    