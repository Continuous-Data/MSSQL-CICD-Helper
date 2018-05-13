#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\ -Include *.ps1 -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\ -Include *.ps1 -Recurse -ErrorAction SilentlyContinue )
$Config = @( Get-ChildItem -Path $PSScriptRoot\Config\ -Include *.ps1 -Recurse -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($import in @($Private + $Public + $Config)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename
