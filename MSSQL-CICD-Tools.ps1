##################################################################
######### Uncomment and edit sections if applicable			######
######### SSDT Build and Deploy helper for CI/CD            ######
######### Author: Tobi Steenbakkers (@tsteenbakkers)		######
######### Version: 2.0										######
######### Creation Date: 2016-01-21							######
######### Modification Date: 2018-03-10						######
##################################################################

###################################################################
###		Parameters												###
###################################################################

param(
    [string[]]$Tasks, # valid values: build, deploy. Multiple possible
    [string[]]$ProjectType, # valid values: solution, project. Single Value
    [string[]]$SQLType, # valid values: Database, SSIS, SSAS, SSRS. Single value
    [string[]]$UsePublishConfig,
    [string[]]$BuildFilePath = 'C:\Users\tsteenbakkers\gitrepos\cicd-test-priv', 
    [string[]]$BuildFileName,
    #[string[]]$MsBuildpath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe',
    [string[]]$MsBuildpath,
    [string[]]$SSDTpath,
    [string[]]$TargetDatabaseServer,
    [string[]]$TargetDatabaseName
    
)

###################################################################
###		Functions												###
###################################################################


function Determine-msbuild{
    if (!$MsBuildpath){
        $MsBuildpath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\SQL\MSBuild\15.0\Bin\MSBuild.exe'

    }
    #Write-Output "Determining VS Studio installation with MSBuild / SSDT tools"
    
    #Write-Output "testing path $MsBuildPath"

    if (Test-Path -Path $MsBuildpath) {
        
        #Write-Output "Msbuild path verified"
        $return = $MsBuildpath
        return $return
    }
    else{

        Write-Error "$MsBuildPath not found. Please check"
        EXIT 1 
    }
    
}
function get-BuildFile{

    [hashtable] $return = @{}

    switch ($ProjectType) {
        "solution"{
            $buildfilextension = 'sln'
        }
        "project"{
            $buildfilextension = 'sqlproject'
        }
        default {
            Write-Error "Invalid option given for input param -Projecttype. valid options are: Solution, Project"
            EXIT 1
        }
    }

    if(!$BuildFilePath){
        Write-Error "BuildFilePath paramater was not supplied."
        EXIT 1
    }
    else{
        if (!$BuildFileName){
            $findfilecommand = "Get-ChildItem -Path $BuildFilePath -filter *.$buildfilextension -Recurse -Force -erroraction SilentlyContinue"
        }
        else{
            $findfilecommand = "Get-ChildItem -Path $BuildFilePath -filter $BuildFileName.$buildfilextension -Recurse -Force -erroraction SilentlyContinue"
        }
        #Write-Output $findfilecommand
        
        #Invoke-Expression $findfilecommand

        $amountofFiles = Invoke-Expression "($findfilecommand).Count"
        $file = Invoke-Expression $findfilecommand | Sort-Object LastwriteTime -Descending | Select-Object Name -First 1 | ForEach-Object {$_.Name}
        $path = Invoke-Expression $findfilecommand | Sort-Object LastwriteTime -Descending | Select-Object Directory -First 1 | ForEach-Object {$_.Directory}
        $FullName = Invoke-Expression $findfilecommand | Sort-Object LastwriteTime -Descending | Select-Object FullName -First 1 | ForEach-Object {$_.FullName}
        
    }

    if ($amountofFiles -lt 1){
        Write-Error "No Files found Eligible for building. Exiting Script"
        EXIT 1
    }
    # else{
    #     $amountofFiles
    #     $file
    #     $FullName
    #     $path
    # }
    Write-Output "Count = $FullName.Count "
    $return.path = $path
    $return.name = $file
    $return.fullname = $FullName
    $return.amount = $amountofFiles
    return $return

}
function prepare-build{
    
    Write-Output "Preparing MSBuild parameters for building"
}

function start-msbuild{
    param(
        [string[]]$MsBuildpath,
        [string[]]$logfilepath,
        [string[]]$MsBuildFile  
    )

        $result = @{}
		$result.BuildSucceeded = $null
		$result.BuildLogFilePath = $buildLogFilePath
		$result.BuildErrorsLogFilePath = $buildErrorsLogFilePath
		$result.ItemToBuildFilePath = $Path
		$result.CommandUsedToBuild = [string]::Empty
		$result.Message = [string]::Empty
		$result.MsBuildProcess = $null
		$result.BuildDuration = [TimeSpan]::Zero

    Write-Output "MSBuildPath: $MSBuildpath"
    $Argumentslist = $("cmd.exe /K "" ""$MsBuildpath"" /fileLoggerParameters:LogFile=$logfilepath""\msbuild.log"" `"$MsBuildFile`"") 
    Write-Output "Starting MSBuild.exe"
    #$Argumentslist
    #& cmd.exe /C $Argumentslist.ToString()
    $result.MsBuildProcess = Start-Process cmd.exe -ArgumentList $Argumentslist -NoNewWindow -PassThru
    $result.MsBuildProcess.ExitCode
    return $result
}

function check-MSBuild{
    param(
        
        [string[]]$logfilepath,
        [string[]]$ExecutionResult
    
    )
    $return = $null
    $findfilecommand = "Get-ChildItem -Path $BuildFilePath -filter msbuild.log -Recurse -Force -erroraction SilentlyContinue"

    $buildLogFilePath = Invoke-Expression $findfilecommand | Sort-Object LastwriteTime -Descending | Select-Object FullName -First 1 | ForEach-Object {$_.FullName}
    $buildLogFilePath
    #$FullName = Invoke-Expression $findfilecommand | Sort-Object LastwriteTime -Descending | Select-Object FullName -First 1 | ForEach-Object {$_.FullName}
    [bool] $buildOutputDoesNotContainFailureMessage = (Select-String -Path $buildLogFilePath -Pattern "Build FAILED." -SimpleMatch) -eq $null
    [bool] $buildReturnedSuccessfulExitCode = $ExecutionResult -eq 0
    $buildSucceeded = $buildOutputDoesNotContainFailureMessage -and $buildReturnedSuccessfulExitCode
}




###################################################################
###		Main Script													###
###################################################################

Write-Output "
##################################################################
######### SSDT Build and Deploy helper for CI/CD            ######
######### Author: Tobi Steenbakkers (@tsteenbakkers)		######
######### Version: 2.0										######
##################################################################

Starting MSSQL CI/CD Tools ...
"

foreach($Task in $Tasks){
    switch($Task)

    {
        "build" {

            Write-Output "Starting Build"

            switch ($ProjectType) {
                "solution"{
                    Determine-msbuild
                    $script:MsBuildpath = Determine-msbuild
                #     get-BuildFile
                #     Write-Output "Test"
                   $script:buildinfo = get-BuildFile
                    $script:buildinfo.FullName
                #    $test = $script:buildinfo.FullName

                #    $test.Count
                    #$script:buildinfo.amount 
                    $lol = start-msbuild -MsBuildpath $script:MsBuildpath -MsBuildFile $script:buildinfo.FullName -logfilepath $BuildFilePath

                    check-MSBuild -logfilepath $BuildFilePath -ExecutionResult $lol.ExitCode
                   #Write-Output $buildinfo.Name
                   #Write-Output $buildinfo.FullName
                    
                }
                "project"{
                    #Determine-msbuild
                    
                }
                default {
                    Write-Error "Invalid option given for input param -Projecttype. valid options are: Solution, Project"
                    EXIT 1
                }
            }
            
        }

        "deploy"{
            Write-Output "Starting Deploy"
        }
        default{
            Write-Output "Invalid Value for -Tasks"
        }
    }
}