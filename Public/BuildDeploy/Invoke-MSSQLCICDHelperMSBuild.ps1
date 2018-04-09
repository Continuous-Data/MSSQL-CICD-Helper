function Invoke-MSSQLCICDHelperMSBuild {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,
               HelpMessage='What to find: *.sln, *.dacpac, *.dtspac or *.sqlproject File. Options are: Solution, DacPac, DTSPack or Project',
               Position=0)]
        
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $Filepath,
        [Parameter(Mandatory=$true,
               HelpMessage='Provides Build Arguments. Example /target:clean;build',
               Position=0)]
        [Alias("Parameters","Params","P")]
        [ValidateNotNullOrEmpty()]
        $MSBuildArguments
    )


}

