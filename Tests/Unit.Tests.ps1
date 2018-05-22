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

    Describe "Get-MSSQLCICDHelperPaths" -Tags Build {
        It "Should throw an error when no parameters are entered"{
            {
               Get-MSSQLCICDHelperPaths -erroraction stop
            } | Should Throw

        }
        
        It "Should throw an error when no valid typetofind was entered"{
            {
               Get-MSSQLCICDHelperPaths -typetofind Pester -rootpath $TestDrive -erroraction stop
            } | Should Throw 

        }

        #mock 1 MSBuild.exe and 2 SQLPackage.exe 1 non existing file.

        New-Item  -Path $TestDrive -Name ExePath1 -ItemType Directory
        New-Item  -Path $TestDrive -Name ExePath2 -ItemType Directory

        New-Item  -Path $TestDrive\ExePath1\MSBuild.exe -ItemType File
        New-Item  -Path $TestDrive\ExePath1\SQLPackage.exe -ItemType File
        New-Item  -Path $TestDrive\ExePath2\SQLPackage.exe -ItemType File
        New-Item  -Path $TestDrive\ExePath1\Itshouldignorethis.exe -ItemType File
        
        It "Should find one MSBuild.exe when searching MSBuild"{
        
            (Get-MSSQLCICDHelperPaths -typetofind MSBuild -rootpath $TestDrive).count | Should BeExactly 1

        }
        
        It "Should find two SQLPackage.exe when searching SQLPackage"{

            (Get-MSSQLCICDHelperPaths -typetofind SQLPackage -rootpath $TestDrive).count | Should BeExactly 2

        } 

        It "Should find three total *.exe when searching Both"{
        
            (Get-MSSQLCICDHelperPaths -typetofind Both -rootpath $TestDrive).count | Should BeExactly 3

        } 

        It "Should find find the correct path to MSbuild.exe"{
        
            $results = Get-MSSQLCICDHelperPaths -typetofind MSBuild -rootpath $TestDrive

            $results | Should contain "$TestDrive\exepath1\MSBuild.exe"

        } 

        It "Should find find the correct paths to SQLPackage.exe"{
        
            $results = Get-MSSQLCICDHelperPaths -typetofind SQLPackage -rootpath $TestDrive

            $results | Should contain "$TestDrive\exepath1\SQLPackage.exe"
            $results | Should contain "$TestDrive\exepath2\SQLPackage.exe"

        } 

        It "Should find find the correct paths to Both *.exe"{
        
            $results = Get-MSSQLCICDHelperPaths -typetofind Both -rootpath $TestDrive

            $results | Should contain "$TestDrive\exepath1\MSBuild.exe"
            $results | Should contain "$TestDrive\exepath1\SQLPackage.exe"
            $results | Should contain "$TestDrive\exepath2\SQLPackage.exe"

        }
        
        It "Should not contain SQLPackage elements when looking for MSBuild"{
        
            $results = Get-MSSQLCICDHelperPaths -typetofind MSBuild -rootpath $TestDrive

            $results | Should not contain "$TestDrive\exepath1\SQLPackage.exe"
            $results | Should not contain "$TestDrive\exepath2\SQLPackage.exe"

        } 

        It "Should not contain MSBuild elements when looking for SQLPackage"{
        
            $results = Get-MSSQLCICDHelperPaths -typetofind SQLPackage -rootpath $TestDrive

            $results | Should not contain "$TestDrive\exepath1\MSBuild.exe"

        } 

        It "Should never contain the dummy file when running MSBuild"{
        
            $results = Get-MSSQLCICDHelperPaths -typetofind MSBuild -rootpath $TestDrive

            $results | Should Not contain "$TestDrive\ExePath1\Itshouldignorethis.exe"

        }

        It "Should never contain the dummy file when running SQLPackage"{
        
            $results = Get-MSSQLCICDHelperPaths -typetofind SQLPackage -rootpath $TestDrive

            $results | Should Not contain "$TestDrive\ExePath1\Itshouldignorethis.exe"

        }
         
        It "Should never contain the dummy file when running Both"{
        
            $results = Get-MSSQLCICDHelperPaths -typetofind Both -rootpath $TestDrive

            $results | Should Not contain "$TestDrive\ExePath1\Itshouldignorethis.exe"

        }  

        It "Should not Throw when searching MSBuild"{
        
            {Get-MSSQLCICDHelperPaths -typetofind MSBuild -rootpath $TestDrive } | Should Not Throw

        }
        
        It "Should not Throw when searching SQLPackage"{
        
            {Get-MSSQLCICDHelperPaths -typetofind SQLPackage -rootpath $TestDrive } | Should Not Throw

        } 

        It "Should not Throw when searching Both"{
        
            {Get-MSSQLCICDHelperPaths -typetofind Both -rootpath $TestDrive } | Should Not Throw

        } 

        
    }

    Describe "Get-MSSQLCICDHelperFiletoBuildDeploy" -Tags Build {
    
        It "Should throw an error when no parameters are entered"{
            {
               Get-MSSQLCICDHelperFiletoBuildDeploy -erroraction stop
            } | Should Throw

        }
        
        It "Should throw an error when no valid typetofind was entered"{
            {
               Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Pester -rootpath $TestDrive -erroraction stop
            } | Should Throw 

        }

        #mock 1 of each type, dummyfile, a dir with multiple of the same and an empty dir
        # folders
        New-Item  -Path $TestDrive -Name Single -ItemType Directory
        New-Item  -Path $TestDrive -Name Multiple -ItemType Directory
        New-Item  -Path $TestDrive -Name Empty -ItemType Directory

        # Singles
        New-Item  -Path $TestDrive\Single\Solution.sln -ItemType File
        New-Item  -Path $TestDrive\Single\SQLProject.sqlproj -ItemType File
        New-Item  -Path $TestDrive\Single\DBToDeploy.dacpac -ItemType File
        New-Item  -Path $TestDrive\Single\DBToDeploy.publish.xml -ItemType File
        New-Item  -Path $TestDrive\Single\SSISPackages.dtspac -ItemType File
        
        #To Ignore Singles
        New-Item  -Path $TestDrive\Single\DBToIgnore.nonpublish.xml -ItemType File
        New-Item  -Path $TestDrive\Single\Itshouldignorethis.exe -ItemType File

        # Multiple
        New-Item  -Path $TestDrive\Multiple\Solution.sln -ItemType File
        New-Item  -Path $TestDrive\Multiple\SQLProject.sqlproj -ItemType File
        New-Item  -Path $TestDrive\Multiple\DBToDeploy.dacpac -ItemType File
        New-Item  -Path $TestDrive\Multiple\DBToDeploy.publish.xml -ItemType File
        New-Item  -Path $TestDrive\Multiple\SSISPackages.dtspac -ItemType File

        New-Item  -Path $TestDrive\Multiple\Solution1.sln -ItemType File
        New-Item  -Path $TestDrive\Multiple\SQLProject1.sqlproj -ItemType File
        New-Item  -Path $TestDrive\Multiple\DBToDeploy1.dacpac -ItemType File
        New-Item  -Path $TestDrive\Multiple\DBToDeploy1.publish.xml -ItemType File
        New-Item  -Path $TestDrive\Multiple\SSISPackages1.dtspac -ItemType File
        
        #To Ignore Singles
        New-Item  -Path $TestDrive\Multiple\DBToIgnore.nonpublish.xml -ItemType File
        New-Item  -Path $TestDrive\Multiple\Itshouldignorethis.exe -ItemType File
        
        # empty dir
        It "Should throw an error when no file has been found for type Solution"{

           { Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath $TestDrive\Empty -erroraction stop } | Should Throw 

        }

        It "Should throw an error when no file has been found for type project"{

           { Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind project -rootpath $TestDrive\Empty -erroraction stop } | Should Throw 

        }

        It "Should throw an error when no file has been found for type DacPac"{

           { Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DacPac -rootpath $TestDrive\Empty -erroraction stop } | Should Throw 

        }

        It "Should throw an error when no file has been found for type PublishProfile"{

           { Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind PublishProfile -rootpath $TestDrive\Empty -erroraction stop } | Should Throw 

        }

        It "Should throw an error when no file has been found for type DTSPac"{

           { Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive\Empty -erroraction stop } | Should Throw 

        }

        #single files Count
        It "Should Find a single file for type Solution"{

           (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath $TestDrive\Single).count | Should BeExactly 1

        }

        It "Should Find a single file for type project"{

          
           (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind project -rootpath $TestDrive\Single).count | Should BeExactly 1

        }

        It "Should Find a single file for type DacPac"{

           
           (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DacPac -rootpath $TestDrive\Single).count | Should BeExactly 1

        }

        It "Should Find a single file for type PublishProfile"{

           
           (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind PublishProfile -rootpath $TestDrive\Single).count | Should BeExactly 1

        }

        It "Should Find a single file for type DTSPac"{

           
           (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive).count | Should BeExactly 1

        }
        ##############
        It "Filename match for type Solution"{

            $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath $TestDrive\Single

            $results | Should contain "$TestDrive\Single\Solution.sln"

        }

        It "Filename match for type project"{

          
           $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Project -rootpath $TestDrive\Single

            $results | Should contain "$TestDrive\Single\SQLProject.sqlproj"

        }

        It "Filename match for type DacPac"{

           
           $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DacPac -rootpath $TestDrive\Single

            $results | Should contain "$TestDrive\Single\DBToDeploy.dacpac"

        }

        It "Filename match for type PublishProfile"{

           
           $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind PublishProfile -rootpath $TestDrive\Single

            $results | Should contain "$TestDrive\Single\DBToDeploy.publish.xml"

        }

        It "Filename match for type DTSPac"{

           
           $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive\Single

            $results | Should contain "$TestDrive\Single\SSISPackages.dtspac"

        }
    
    }

    Describe "Invoke-MSSQLCICDHelperMSBuild" -Tags Build {}

    Describe "Invoke-MSSQLCICDHelperSQLPackage" -Tags Build {}

}


