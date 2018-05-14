$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

#Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

Describe "Basic function unit tests" -Tags Build {

    Context "Config" {

        it "importconfig should return a value when a config file exists" {

            { Get-MSSQLCICDHelperConfiguration } | Should Not Throw
        }

    }

    Context "NoConfig" {
        BeforeAll{
            if(Test-path $env:appdata\MSSQLCICDHelper\MSSQLCICDHelperConfiguration.xml){
                Rename-Item -Path "$env:appdata\MSSQLCICDHelper\MSSQLCICDHelperConfiguration.xml" -NewName "PesterBackupMSSQLCICDHelperConfiguration.xml"
            }
        }

        AfterAll{
            if(Test-path $env:appdata\MSSQLCICDHelper\PesterBackupMSSQLCICDHelperConfiguration.xml){
                Rename-Item -Path "$env:appdata\MSSQLCICDHelper\PesterBackupMSSQLCICDHelperConfiguration.xml" -NewName "MSSQLCICDHelperConfiguration.xml"
            }
        }

        It "When no config file is found Get-MSSQLCICDHelperConfiguration should fail"{
            { Get-MSSQLCICDHelperConfiguration -erroraction stop } | Should Throw
        }

        It "When no config file is found Invoke-MSSQLCICDHelperMSBuild should fail"{
            { Invoke-MSSQLCICDHelperMSBuild -erroraction stop } | Should Throw
        }

        It "When no config file is found Invoke-MSSQLCICDHelperSQLPackage should fail"{
            { Invoke-MSSQLCICDHelperSQLPackage -erroraction stop } | Should Throw
        }
    }

    Context "Build" {

        it "importconfig should return a value when a config file exists" {

            { Get-MSSQLCICDHelperConfiguration } | Should Not Throw
        }

    }

    Context "Deploy" {

        it "importconfig should return a value when a config file exists" {

            { Get-MSSQLCICDHelperConfiguration } | Should Not Throw
        }

    }
}