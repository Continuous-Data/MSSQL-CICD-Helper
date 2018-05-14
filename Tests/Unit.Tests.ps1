$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

#Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

Describe "Basic function unit tests" -Tags Build {

    Context "importconfig" {

        it "importconfig should return a value when a config file exists" {

            { Get-MSSQLCICDHelperConfiguration } | Should Not Throw
        }

    }
}