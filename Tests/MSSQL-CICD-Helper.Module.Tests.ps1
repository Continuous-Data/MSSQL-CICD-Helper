$ModuleName = Split-Path (Resolve-Path "$PSScriptRoot\..\" ) -Leaf
$ModuleManifest = Resolve-Path "$PSScriptRoot\..\$ModuleName\$ModuleName.psd1"

#Get-Module $ModuleName | Remove-Module

#Import-Module $ModuleManifest

Describe 'Module Information' {
    
    $ModuleManifest = "$PSScriptRoot\..\MSSQL-CICD-Helper\MSSQL-CICD-Helper.psd1"
    
    Context 'Module Manifest' {
        $Script:Manifest = $null
        It 'Valid Manifest File' {
            {
                $Script:Manifest = Test-ModuleManifest -Path $ModuleManifest -ErrorAction Stop -WarningAction SilentlyContinue
            } | Should Not Throw
        }

        It 'Valid Manifest Root Module' {
            $Script:Manifest.RootModule | Should Be 'MSSQL-CICD-Helper.psm1'
        }

        It 'Valid Manifest Name' {
            $Script:Manifest.Name | Should be MSSQL-CICD-Helper
        }

        It 'Valid Manifest GUID' {
            $Script:Manifest.Guid | SHould be '2287837f-86ec-43ef-97a8-fee9f33a7c33'
        }

        It 'Valid Author' {
            $Script:Manifest.Author | SHould be 'Tobi Steenbakkers'
        }

        It 'Valid Manifest Version' {
            $Script:Manifest.Version -as [Version] | Should Not BeNullOrEmpty
        }

        It 'Valid Manifest Description' {
            $Script:Manifest.Description | Should Not BeNullOrEmpty
        }

        It 'Required Modules' {
            $Script:Manifest.RequiredModules | Should BeNullOrEmpty
        }

        It 'Non blank description' {
            $Script:Manifest.Description | Should not Benullorempty
        }

    }
}

#Remove-Module $ModuleName
