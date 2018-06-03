<#
.Description
Installs and loads all the required modules for the build.
Derived from scripts written by Warren F. (RamblingCookieMonster)
#>

[cmdletbinding()]
param ($Task = 'LocalPester')
"Starting build"
# " Installing latest NuGet Provider"
#Install-PackageProvider -name NuGet -Force
# Grab nuget bits, install modules, set build variables, start build.
"  Install Dependent Modules"
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Install-Module InvokeBuild, BuildHelpers, PSDeploy, PlatyPS -force -Scope CurrentUser
Install-Module PSScriptAnalyzer, Pester-Force -SkipPublisherCheck -Scope CurrentUser

"  Import Dependent Modules"
$modules = New-Object System.Collections.ArrayList
$modules.add('InvokeBuild')
$modules.add('BuildHelpers')
$modules.add('PSScriptAnalyzer')

foreach($module in $modules) {
    if(Get-Module $$module -ErrorAction 'Ignore' -ListAvailable){
        "Module $module is installed. skipping install"
    }else{
        "Installing $module ..."
        Import-Module $module
    }

}

Set-BuildEnvironment

"  InvokeBuild"
Invoke-Build $Task -Result result -Verbose
if ($Result.Error)
{
    exit 1
}
else
{
    exit 0
}