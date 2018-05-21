$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf
$testRoot = Resolve-Path "$projectRoot\Tests"

#Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force
InModuleScope MSSQL-CICD-Helper {

    Describe "CurrentVersion" -Tags Build {
        

        It "Saves the configuration with expected values"{
            # Act
            $version = currentversion
            
            # Assert
            $version | should be 'v1.0.0'
        }
    }

    Describe 'Save-MSSQLCICDHelperConfiguration' -Tags Build {

        # Prepare
        $FilePath = "$TestDrive\PesterTest.xml"

        $ExportCLIXML = Get-Command Export-Clixml
        $currentversion = currentversion

        Mock Export-Clixml {
            & $ExportCLIXML -InputObject $InputObject -Path $FilePath
        }

        Mock Test-Path {$true}

        It "Saves the configuration with expected values"{
            # Act
            Save-MSSQLCICDHelperConfiguration -SQLPackageExePath 'C:\pestertest\SQLPackage.exe' -MSBuildExePath 'C:\pestertest\MSBuild.exe' -erroraction stop
            
            # Assert
            $results = Import-Clixml "$TestDrive\PesterTest.xml"
            $results.SQLPackageExe | Should be 'C:\pestertest\SQLPackage.exe'
            $results.MSBuildExe | Should be 'C:\pestertest\MSBuild.exe'
            $results.version | Should be "$currentversion"
        }

        It "Saves without throwing"{
            # Act
            {
                Save-MSSQLCICDHelperConfiguration -SQLPackageExePath 'C:\pestertest\SQLPackage.exe' -MSBuildExePath 'C:\pestertest\MSBuild.exe' -erroraction stop
            } | Should not throw
            
            
        }
        # prepare fail
        Mock Test-Path {$false}

        It "Throws when Test-Path fails"{
            # Act
            {
                Save-MSSQLCICDHelperConfiguration -SQLPackageExePath 'C:\pestertest\SQLPackage.exe' -MSBuildExePath 'C:\pestertest\MSBuild.exe' -erroraction stop
            } | Should throw
            
            
        }
    }
    
    Describe "ImportConfig" -Tags Build {
        # Prepare
        $FilePath = "$TestDrive\PesterTest.xml"

        $ExportCLIXML = Get-Command Export-Clixml
        $ImportCLIXML = Get-Command Import-Clixml
        $currentversion = currentversion

        Mock Export-Clixml {
            & $ExportCLIXML -InputObject $InputObject -Path $FilePath
        }

        Mock Test-Path {$true}

        Mock Import-Clixml -Verifiable {
            & $ImportCLIXML $FilePath
        }

        It "Saves the configuration with expected values"{
            # Act
            Save-MSSQLCICDHelperConfiguration -SQLPackageExePath 'C:\pestertest\SQLPackage.exe' -MSBuildExePath 'C:\pestertest\MSBuild.exe' -erroraction stop
            
            # Assert
            $results = ImportConfig
            $results.SQLPackageExe | Should be 'C:\pestertest\SQLPackage.exe'
            $results.MSBuildExe | Should be 'C:\pestertest\MSBuild.exe'
            $results.version | Should be "$currentversion"
        }

        It "imports the config w/o throwing an error"{

            {
                ImportConfig -erroraction stop
            } | Should not throw
        }

        # prepare fail
        Mock Test-Path {$false}

        It "Throws an error when path cannot be tested"{

            {
                ImportConfig -erroraction stop
            } | Should  throw
        }

    }

    Describe "Get-MSSQLCICDHelperConfiguration" -Tags Build {
        # Prepare
        $FilePath = "$TestDrive\PesterTest.xml"

        $ExportCLIXML = Get-Command Export-Clixml
        $currentversion = currentversion

        Mock Export-Clixml {
            & $ExportCLIXML -InputObject $InputObject -Path $FilePath
        }

        Mock Test-Path {$true}

        Mock ImportConfig {$mockresult}

        It "Saves the configuration with expected values"{
            # Act
            Save-MSSQLCICDHelperConfiguration -SQLPackageExePath 'C:\pestertest\SQLPackage.exe' -MSBuildExePath 'C:\pestertest\MSBuild.exe' -erroraction stop
            
            $mockresult = Import-Clixml "$TestDrive\PesterTest.xml"
            # Assert
            $results = Get-MSSQLCICDHelperConfiguration $FilePath
            $results.SQLPackageExe | Should be 'C:\pestertest\SQLPackage.exe'
            $results.MSBuildExe | Should be 'C:\pestertest\MSBuild.exe'
            $results.version | Should be "$currentversion"
        }

        It "imports the config w/o throwing an error"{

            {
                Get-MSSQLCICDHelperConfiguration -erroraction stop
            } | Should not throw
        }

        # prepare fail
        Mock importconfig {throw "Could not import config. Make sure it exists or save a new config."}

        It "Throws an error when nested function fails"{

            {
                Get-MSSQLCICDHelperConfiguration -erroraction stop
            } | Should  throw "Could not import config. Make sure it exists or save a new config."
        }

    }

    Describe "Get-MSSQLCICDHelperPaths" -Tags Build {}

    Describe "Get-MSSQLCICDHelperFiletoBuildDeploy" -Tags Build {}

    Describe "Invoke-MSSQLCICDHelperMSBuild" -Tags Build {}

    Describe "Invoke-MSSQLCICDHelperSQLPackage" -Tags Build {}

}


