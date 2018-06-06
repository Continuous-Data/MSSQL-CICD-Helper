$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf
$testRoot = Resolve-Path "$projectRoot\Tests"

#Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force
InModuleScope MSSQL-CICD-Helper {

    Describe "CurrentVersion" -Tags Build {
        $returnedversion = 'V1.0.0'

        Mock CurrentVersion {$returnedversion}

        It "Saves the configuration with expected values"{
            # Act
            $version = currentversion
            
            # Assert
            $version | should be 'v1.0.0'
            Assert-MockCalled currentversion -Exactly 1 -Scope It
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

            Assert-MockCalled Export-Clixml -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 3 -Scope It
        }

        It "Saves without throwing"{
            # Act
            {
                Save-MSSQLCICDHelperConfiguration -SQLPackageExePath 'C:\pestertest\SQLPackage.exe' -MSBuildExePath 'C:\pestertest\MSBuild.exe' -erroraction stop
            } | Should not throw

            Assert-MockCalled Export-Clixml -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 3 -Scope It

        }
        # prepare fail
        Mock Test-Path {$false}

        It "Throws when Test-Path fails"{
            # Act
            {
                Save-MSSQLCICDHelperConfiguration -SQLPackageExePath 'C:\pestertest\SQLPackage.exe' -MSBuildExePath 'C:\pestertest\MSBuild.exe' -erroraction stop
            } | Should throw

            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            
        }
    }
    
    Describe "ImportConfig" -Tags Build {
        # Prepare

        Mock currentversion {'V1.0.0'}

        $FilePath = "$TestDrive\PesterTest.xml"
        $ImportCLIXML = Get-Command Import-Clixml
        $buildpath = 'C:\pestertest\MSBuild.exe'
        $sqlpath = 'C:\pestertest\SQLPackage.exe'
        $currentversion = currentversion

        $export = @{
            MSBuildExe = $buildpath
            SQLPackageExe = $sqlpath
            Version = currentversion
        }

        $export | Export-Clixml -path $FilePath

        Mock Test-Path {$true}

        Mock Import-Clixml -Verifiable {
            & $ImportCLIXML $FilePath
        }

        It "imports the config with the correct values"{
            # Assert
            $results = ImportConfig
            $results.SQLPackageExe | Should BeExactly $sqlpath
            $results.MSBuildExe | Should BeExactly $buildpath
            $results.version | Should BeExactly $currentversion

            Assert-MockCalled currentversion -Exactly 1 -Scope It
            Assert-MockCalled Import-Clixml -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
        }

        It "imports the config w/o throwing an error"{

            {
                ImportConfig -erroraction stop
            } | Should not throw

            Assert-MockCalled currentversion -Exactly 1 -Scope It
            Assert-MockCalled Import-Clixml -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
        }

        # prepare fail
        Mock Test-Path {$false}

        It "Throws an error when path cannot be tested"{

            {
                ImportConfig -erroraction stop
            } | Should  throw

            Assert-MockCalled currentversion -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
        }

    }

    Describe "Get-MSSQLCICDHelperConfiguration" -Tags Build {
        # Prepare
        Mock currentversion {'V1.0.0'}

        $FilePath = "$TestDrive\PesterTest.xml"
        $ImportCLIXML = Get-Command Import-Clixml
        $buildpath = 'C:\pestertest\MSBuild.exe'
        $sqlpath = 'C:\pestertest\SQLPackage.exe'
        $currentversion = currentversion

        $export = @{
            MSBuildExe = $buildpath
            SQLPackageExe = $sqlpath
            Version = currentversion
        }

        $export | Export-Clixml -path $FilePath

        $mockresult = Import-Clixml $FilePath

        Mock Test-Path {$true}

        Mock ImportConfig {$mockresult}

        

        It "Imports the configuration with expected values"{
            # Assert
            $results = Get-MSSQLCICDHelperConfiguration $FilePath
            $results.SQLPackageExe | Should BeExactly $sqlpath
            $results.MSBuildExe | Should BeExactly $buildpath
            $results.version | Should BeExactly $currentversion

            Assert-MockCalled importconfig -Exactly 1 -Scope It
        }

        It "imports the config w/o throwing an error"{

            {
                Get-MSSQLCICDHelperConfiguration -erroraction stop
            } | Should not throw

            Assert-MockCalled importconfig -Exactly 1 -Scope It
        }

        # prepare fail
        Mock importconfig {throw "Could not import config. Make sure it exists or save a new config."}

        It "Throws an error when nested function fails"{

            {
                Get-MSSQLCICDHelperConfiguration -erroraction stop
            } | Should  throw "Could not import config. Make sure it exists or save a new config."
            
            Assert-MockCalled importconfig -Exactly 1 -Scope It
        }

    }

    Describe "Get-MSSQLCICDHelperPaths" -Tags Build {

        #create 1 MSBuild.exe and 2 SQLPackage.exe 1 non existing file.

        New-Item  -Path $TestDrive -Name ExePath1 -ItemType Directory
        New-Item  -Path $TestDrive -Name ExePath2 -ItemType Directory
        New-Item  -Path $TestDrive -Name EmptyFolder -ItemType Directory

        New-Item  -Path $TestDrive\ExePath1\MSBuild.exe -ItemType File
        New-Item  -Path $TestDrive\ExePath1\SQLPackage.exe -ItemType File
        New-Item  -Path $TestDrive\ExePath2\SQLPackage.exe -ItemType File
        New-Item  -Path $TestDrive\ExePath1\Itshouldignorethis.exe -ItemType File

        Context "Mandatory Parameters" {
            It "Parameter Typetofind should be mandatory"{

                (Get-Command "Get-MSSQLCICDHelperPaths").Parameters['Typetofind'].Attributes.Mandatory | Should Be $true
    
            }
    
            It "Parameter Rootpath should be mandatory"{
    
                (Get-Command "Get-MSSQLCICDHelperPaths").Parameters['Rootpath'].Attributes.Mandatory | Should Be $true
    
            }

            It "Should throw an error when no valid typetofind was entered" {
                {
                   Get-MSSQLCICDHelperPaths -typetofind Pester -rootpath $TestDrive -erroraction stop
                } | Should Throw 
    
            }

            It "Should throw an error when no valid rootpath was entered for MSBuild"{
                {
                   Get-MSSQLCICDHelperPaths -typetofind MSBuild -rootpath $TestDrive\NonExistingFolder -erroraction stop
                } | Should Throw 
    
            }
            
            It "Should throw an error when no valid rootpath was entered for SQLPackage"{
                {
                   Get-MSSQLCICDHelperPaths -typetofind SQLPackage -rootpath $TestDrive\NonExistingFolder -erroraction stop
                } | Should Throw 
    
            }
        }

        Context "No Files Found"{
            It "Should throw an error when no files were found for MSBuild"{
                {
                   Get-MSSQLCICDHelperPaths -typetofind MSBuild -rootpath $TestDrive\NonExistingFolder -erroraction stop
                } | Should Throw 
    
            }
            
            It "Should throw an error when no files were found for SQLPackage"{
                {
                   Get-MSSQLCICDHelperPaths -typetofind SQLPackage -rootpath $TestDrive\NonExistingFolder -erroraction stop
                } | Should Throw 
    
            }
        }
        
        Context "File counts"{

            It "Should find one MSBuild.exe when searching MSBuild"{
        
                (Get-MSSQLCICDHelperPaths -typetofind MSBuild -rootpath $TestDrive).count | Should BeExactly 1
    
            }
            
            It "Should find two SQLPackage.exe when searching SQLPackage"{
    
                (Get-MSSQLCICDHelperPaths -typetofind SQLPackage -rootpath $TestDrive).count | Should BeExactly 2
    
            } 
    
            It "Should find three total *.exe when searching Both"{
            
                (Get-MSSQLCICDHelperPaths -typetofind Both -rootpath $TestDrive).count | Should BeExactly 3
    
            }
        }
        
        Context "Correct file paths"{
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
        }

          
        Context "Throws" {
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
         

        
    }

    Describe "Get-MSSQLCICDHelperFiletoBuildDeploy" -Tags Build {
    
        #create 1 of each type, dummyfile, a dir with multiple of the same and an empty dir
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

        New-Item  -Path $TestDrive\Multiple\Solution1.sln -ItemType File
        New-Item  -Path $TestDrive\Multiple\SQLProject1.sqlproj -ItemType File
        New-Item  -Path $TestDrive\Multiple\DBToDeploy1.dacpac -ItemType File
        New-Item  -Path $TestDrive\Multiple\DBToDeploy1.publish.xml -ItemType File
        New-Item  -Path $TestDrive\Multiple\SSISPackages1.dtspac -ItemType File

        $date = (Get-Date).AddDays(-1-$i)

        Set-ItemProperty -Path $TestDrive\Multiple\Solution1.sln -Name LastWriteTime -Value $date
        Set-ItemProperty -Path $TestDrive\Multiple\SQLProject1.sqlproj -Name LastWriteTime -Value $date
        Set-ItemProperty -Path $TestDrive\Multiple\DBToDeploy1.dacpac -Name LastWriteTime -Value $date
        Set-ItemProperty -Path $TestDrive\Multiple\DBToDeploy1.publish.xml -Name LastWriteTime -Value $date
        Set-ItemProperty -Path $TestDrive\Multiple\SSISPackages1.dtspac -Name LastWriteTime -Value $date

        New-Item  -Path $TestDrive\Multiple\Solution2.sln -ItemType File
        New-Item  -Path $TestDrive\Multiple\SQLProject2.sqlproj -ItemType File
        New-Item  -Path $TestDrive\Multiple\DBToDeploy2.dacpac -ItemType File
        New-Item  -Path $TestDrive\Multiple\DBToDeploy2.publish.xml -ItemType File
        New-Item  -Path $TestDrive\Multiple\SSISPackages2.dtspac -ItemType File
        
        #To Ignore Multiple
        New-Item  -Path $TestDrive\Multiple\DBToIgnore.nonpublish.xml -ItemType File
        New-Item  -Path $TestDrive\Multiple\Itshouldignorethis.exe -ItemType File
        
        Context "Mandatory Paramaters"{

            It "Parameter Typetofind should be mandatory"{

                (Get-Command "Get-MSSQLCICDHelperFiletoBuildDeploy").Parameters['Typetofind'].Attributes.Mandatory | Should Be $true

            }

            It "Parameter Rootpath should be mandatory"{

                (Get-Command "Get-MSSQLCICDHelperFiletoBuildDeploy").Parameters['Rootpath'].Attributes.Mandatory | Should Be $true

            }
        
            It "Should throw an error when no valid typetofind was entered"{
                {
                   Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Pester -rootpath $TestDrive -erroraction stop
                } | Should Throw 

            }

            It "Should throw an error when a non-existing folder was entered for type Solution"{
                {
                    Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath $TestDrive\NonExistingFolder -erroraction stop
                 } | Should Throw 
            }

            It "Should throw an error when a non-existing folder was entered for type project"{
                {
                    Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Project -rootpath $TestDrive\NonExistingFolder -erroraction stop
                 } | Should Throw 
            }

            It "Should throw an error when a non-existing folder was entered for type DacPac"{
                {
                    Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DacPac -rootpath $TestDrive\NonExistingFolder -erroraction stop
                 } | Should Throw 
            }

            It "Should throw an error when a non-existing folder was entered for type PublishProfile"{
                {
                    Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind PublishProfile -rootpath $TestDrive\NonExistingFolder -erroraction stop
                 } | Should Throw 
            }

            It "Should throw an error when a non-existing folder was entered for type DTSPac"{
                {
                    Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive\NonExistingFolder -erroraction stop
                 } | Should Throw 
            }
        }

        Context "No File Found" {

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
        }

        Context "Folders with Single file" {}

        Context "File Counts" {
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

           
               (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive\Single).count | Should BeExactly 1

            }
        }
        Context "Correct File Paths" {
            #file matches
            It "Single Filename match for type Solution"{

                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath $TestDrive\Single

                $results.Fullname | Should contain "$TestDrive\Single\Solution.sln"

            }

            It "Single Filename match for type project"{

          
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Project -rootpath $TestDrive\Single

                $results.Fullname | Should contain "$TestDrive\Single\SQLProject.sqlproj"

            }

            It "Single Filename match for type DacPac"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DacPac -rootpath $TestDrive\Single

                $results.Fullname | Should contain "$TestDrive\Single\DBToDeploy.dacpac"

            }

            It "Single Filename match for type PublishProfile"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind PublishProfile -rootpath $TestDrive\Single

                $results.Fullname | Should contain "$TestDrive\Single\DBToDeploy.publish.xml"

            }

            It "Single Filename match for type DTSPac"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive\Single

                $results.Fullname | Should contain "$TestDrive\Single\SSISPackages.dtspac"

            }
        }
        Context "Dummy Files" {

            #file matches
            It "Dummy Exclude Single for type Solution"{

                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath $TestDrive\Single

                $results.Fullname | Should not contain "$TestDrive\Single\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Single\Itshouldignorethis.exe"

            }

            It "Dummy Exclude Single for type project"{

          
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Project -rootpath $TestDrive\Single

                $results.Fullname | Should not contain "$TestDrive\Single\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Single\Itshouldignorethis.exe"

            }

            It "Dummy Exclude Single for type DacPac"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DacPac -rootpath $TestDrive\Single

                $results.Fullname | Should not contain "$TestDrive\Single\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Single\Itshouldignorethis.exe"

            }

            It "Dummy Exclude Single for type PublishProfile"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind PublishProfile -rootpath $TestDrive\Single

                $results.Fullname | Should not contain "$TestDrive\Single\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Single\Itshouldignorethis.exe"

            }

            It "Dummy Exclude Single for type DTSPac"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive\Single

                $results.Fullname | Should not contain "$TestDrive\Single\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Single\Itshouldignorethis.exe"

   

            }

        }

        Context "Folders with Multiple files" {}

        Context "File Counts" {
            #single files Count
            It "Should Find a single file in folder with Multiple files for type Solution"{

               (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath $TestDrive\Multiple).count | Should BeExactly 1

            }

            It "Should Find a single file in folder with Multiple files for type project"{

          
               (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind project -rootpath $TestDrive\Multiple).count | Should BeExactly 1

            }

            It "Should Find a single file in folder with Multiple files for type DacPac"{

           
               (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DacPac -rootpath $TestDrive\Multiple).count | Should BeExactly 1

            }

            It "Should Find a single file in folder with Multiple files for type PublishProfile"{

           
               (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind PublishProfile -rootpath $TestDrive\Multiple).count | Should BeExactly 1

            }

            It "Should Find a single file in folder with Multiple files for type DTSPac"{

           
               (Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive\Multiple).count | Should BeExactly 1

            }
        }
        Context "Correct File Paths" {
            #file matches
            It "Multiple Filename match for type Solution"{

                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath $TestDrive\Multiple

                $results.Fullname | Should contain "$TestDrive\Multiple\Solution2.sln"

            }

            It "Multiple Filename match for type project"{

          
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Project -rootpath $TestDrive\Multiple

                $results.Fullname | Should contain "$TestDrive\Multiple\SQLProject2.sqlproj"

            }

            It "Multiple Filename match for type DacPac"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DacPac -rootpath $TestDrive\Multiple

                $results.Fullname | Should contain "$TestDrive\Multiple\DBToDeploy2.dacpac"

            }

            It "Multiple Filename match for type PublishProfile"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind PublishProfile -rootpath $TestDrive\Multiple

                $results.Fullname | Should contain "$TestDrive\Multiple\DBToDeploy2.publish.xml"

            }

            It "Multiple Filename match for type DTSPac"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive\Multiple

                $results.Fullname | Should contain "$TestDrive\Multiple\SSISPackages2.dtspac"

            }
        }
        Context "Dummy Files" {

            #file matches
            It "Multiple Dummy Exclude Single for type Solution"{

                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Solution -rootpath $TestDrive\Multiple

                $results.Fullname | Should not contain "$TestDrive\Multiple\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Multiple\Itshouldignorethis.exe"

            }

            It "Multiple Dummy Exclude Single for type project"{

          
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind Project -rootpath $TestDrive\Multiple

                $results.Fullname | Should not contain "$TestDrive\Multiple\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Multiple\Itshouldignorethis.exe"

            }

            It "Multiple Dummy Exclude Single for type DacPac"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DacPac -rootpath $TestDrive\Multiple

                $results.Fullname | Should not contain "$TestDrive\Multiple\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Multiple\Itshouldignorethis.exe"

            }

            It "Multiple Dummy Exclude Single for type PublishProfile"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind PublishProfile -rootpath $TestDrive\Multiple

                $results.Fullname | Should not contain "$TestDrive\Multiple\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Multiple\Itshouldignorethis.exe"

            }

            It "Multiple Dummy Exclude Single for type DTSPac"{

           
                $results = Get-MSSQLCICDHelperFiletoBuildDeploy -typetofind DTSPac -rootpath $TestDrive\Multiple

                $results.Fullname | Should not contain "$TestDrive\Multiple\DBToIgnore.nonpublish.xml"
                $results.Fullname | Should not contain "$TestDrive\Multiple\Itshouldignorethis.exe"

   

            }

        }
    
    }
    Describe "Invoke-Cmd" -Tags Build {

        #New-Item  -Path $TestDrive\poutput.log -ItemType File
        #New-Item  -Path $TestDrive\errorpoutput.log -ItemType File

        $executable = 'powershell.exe'
        $passingarguments = 'Write-Output ''Test sentence for assertion'''
        $passingAssertion = 'Test sentence for assertion'
        $failingarguments = 'throw'
        $FailingAssertion = ''
        $logfile = "$TestDrive\poutput.log"
        $errorlogfile = "$TestDrive\errorpoutput.log"

        It "Mandatory Parameters"{
            (Get-Command "Invoke-Cmd").Parameters['Executable'].Attributes.Mandatory | Should Be $true
            (Get-Command "Invoke-Cmd").Parameters['Arguments'].Attributes.Mandatory | Should Be $true
            (Get-Command "Invoke-Cmd").Parameters['Logfile'].Attributes.Mandatory | Should Be $true
            (Get-Command "Invoke-Cmd").Parameters['errorlogfile'].Attributes.Mandatory | Should Be $true
        }

        It "Should not throw when all parameters are entered on a successfull command"{
            { Invoke-Cmd -executable $executable -arguments $passingarguments -logfile $logfile -errorlogfile $errorlogfile } | Should not Throw
        }

        It "Should throw on an invalid logfile path parent"{
            { Invoke-Cmd -executable $executable -arguments $passingarguments -logfile $testdrive\NonExistingFolder\file.log -errorlogfile $errorlogfile -erroraction stop } | Should Throw
        }

        It "Should throw on an invalid errorlogfile path parent"{
            { Invoke-Cmd -executable $executable -arguments $passingarguments -logfile $logfile -errorlogfile $testdrive\NonExistingFolder\file.log -erroraction stop } | Should Throw
        }

        It "Should throw when a non existing executable is used"{
            { Invoke-Cmd -executable 'failingassert.error' -arguments $passingarguments -logfile $logfile -errorlogfile $errorlogfile -erroraction stop } | Should Throw
        }

        It "Should produce the correct results when calling write-output command"{
            $results = Invoke-Cmd -executable $executable -arguments $passingarguments -logfile $logfile -errorlogfile $errorlogfile
            #getting results
            $results.ExitCode | Should -BeExactly 0
            $results.ErrorOutput | Should -BeExactly -1
            $results.Output.Trim() | Should -BeExactly $passingAssertion
            #test created files
            Test-Path -Path $logfile | Should be $true
            Test-Path -Path $errorlogfile | Should be $true

            $producedlogfile = Get-Content $logfile 
            $producederrorlogfile = Get-Content $errorlogfile 

            $producedlogfile[0].Trim() | Should -BeExactly $passingAssertion
            $producederrorlogfile.Trim() | Should -BeExactly -1
        }

        It "Should produce the correct results when calling throw command"{
            $results = Invoke-Cmd -executable $executable -arguments $failingarguments -logfile $logfile -errorlogfile $errorlogfile
            
            $results.ExitCode | Should -BeExactly 1
            $results.ErrorOutput | Should -BeExactly 83
            $results.Output | Should -BeExactly $FailingAssertion

            Test-Path -Path $logfile | Should be $true
            Test-Path -Path $errorlogfile | Should be $true

            $producedlogfile = Get-Content $logfile 
            $producederrorlogfile = Get-Content $errorlogfile 

            $producedlogfile | Should -BeExactly $FailingAssertion
            $producederrorlogfile.Trim() | Should -BeExactly 83
        }
    }

    Describe "Invoke-MSSQLCICDHelperMSBuild" -Tags Build {
        Context "Errors & Dependencies" {
            #Context "test nested context"{}
            ############################
            
            ############################
            mock Get-Module {$false}

            It "Should throw when Invoke-MSBuild is not Available"{
                {Invoke-MSSQLCICDHelperMSBuild -UseInvokeMSBuildModule -erroraction stop} | Should throw
                
                Assert-MockCalled Get-Module -Exactly 1 -Scope It
            }

            New-Item  -Path $TestDrive -Name Solution -ItemType Directory
            New-Item  -Path $TestDrive -Name Empty -ItemType Directory

            New-Item  -Path $TestDrive\MSBuild.exe -ItemType File
            New-Item  -Path $TestDrive\SQLPackage.exe -ItemType File

            New-Item  -Path $TestDrive\Solution\Solution.sln -ItemType File

            $filetobuild = "$TestDrive\Solution\Solution.sln"

            Mock currentversion {'V1.0.0'}

            $configpath = "$TestDrive\PesterTest.xml"
            #$ImportCLIXML = Get-Command Import-Clixml
            $buildpath = "$Testdrive\MSBuild.exe"
            $sqlpath = "$testdrive\SQLPackage.exe"
            $currentversion = currentversion

            $export = @{
                MSBuildExe = $buildpath
                SQLPackageExe = $sqlpath
                Version = $currentversion
            }

            $export | Export-Clixml -path $configpath

            $mockresult = Import-Clixml $configpath

            Mock ImportConfig {$mockresult}

            it "Should throw an error on an empty path" {
                {Invoke-MSSQLCICDHelperMSBuild -filename $testRoot\NonExisting.sln -erroraction stop} | Should throw
                
                Assert-MockCalled importconfig -Exactly 0 -Scope It
            }
            
            mock Get-MSSQLCICDHelperFiletoBuildDeploy {throw}
            #mock Get-ChildItem {}
            mock Invoke-Expression {throw}

            # it "Should throw when an exception occurs with manual filename " {

            #     {Invoke-MSSQLCICDHelperMSBuild -filename $filetobuild -erroraction stop} | Should throw
            # }

            it "Should throw when an exception occurs with Autodiscovery filename" {

                {Invoke-MSSQLCICDHelperMSBuild -erroraction stop} | Should throw

                Assert-MockCalled importconfig -Exactly 1 -Scope It
                Assert-MockCalled Get-MSSQLCICDHelperFiletoBuildDeploy -Exactly 1 -Scope It
            }
        }
    }

    Describe "Invoke-MSSQLCICDHelperSQLPackage" -Tags Build {

    }

}


