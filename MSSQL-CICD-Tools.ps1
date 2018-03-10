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
    [string[]]$Solutionpath = 'C:\Users\tsteenbakkers\gitrepos\bi-automation-cicd-demo\gitlabcicd.sln',
    [string[]]$MsBuildpath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msBuild.exe',
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
    Write-Output "Determining VS Studio installation with MSBuild / SSDT tools"
    try{
        Test-Path $MsBuildpath
        Write-Output "Msbuild path verified"
    }
    catch {
        Write-Error "$MsBuildPath not found. Please check"
        EXIT 1
    }
    
}

function build-solution{
    
    Write-Output "Building Solution"
}

function start-msbuild{
    #Write-Output " $MSBuildpath"
    $Argumentslist = "$MsBuildpath $Solutionpath" 
    Write-Output "Starting MSBuild.exe"
    return Start-Process cmd.exe -ArgumentList $Argumentslist -NoNewWindow
}

function build-project{
    
        Write-Output "Building Solution"
    }


function deploy-dacpac{
        
            Write-Output "Building Solution"
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

if (!$Tasks){
    Write-Error "No task given. Valid options are: build,deploy. for multiple tasks seperate them with a comma like so: -Tasks 'build','deploy' "
}

foreach($Task in $Tasks){
    switch($Task)

    {
        "build" {

            Write-Output "Starting Build"

            if (!$ProjectType){
                Write-Error "no type supplied. Valid types are Solution, Project"
                EXIT 1
            }
            elseif ($ProjectType -eq 'Solution') {
                Determine-msbuild
                build-solution
                start-msbuild
            }
            elseif ($ProjectType -eq 'Project') {
                build-project
            }
            
        }

        "deploy"{
            Write-Output "Starting Deploy"
        }
    }
}