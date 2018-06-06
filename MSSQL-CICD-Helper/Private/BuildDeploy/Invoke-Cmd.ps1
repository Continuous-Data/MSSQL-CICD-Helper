function Invoke-Cmd {
    <#
        .SYNOPSIS
        Executes a Invoke-Expression / CMD.Exe based on the Given Parameters. Allows for re-using part of program code and mocking
    
        .DESCRIPTION
        <will add later based on actual code >
    
        .PARAMETER Executable
        <not used currently>
    
        .PARAMETER Arguments
        Specifies the Arguments for which the Invoked Cmd should use.

        .PARAMETER logfile
        Specifies the Arguments for which the Invoked Cmd should use.

        .PARAMETER errorlogfile
        Specifies the Arguments for which the Invoked Cmd should use.

        .OUTPUTS
        A result set with the outcome of the process along with some metrics.
    
        .EXAMPLE
        Invoke-Cmd -Arguments <add some arguments>

        Will execute the following command:
        
        .LINK
        Project home: https://github.com/tsteenbakkers/MSSQL-CICD-Helper
    
        .NOTES
        Name:   MSSQLCICDHelper
        Author: Tobi Steenbakkers
        Version: 1.0.0
    #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$true,
                   HelpMessage='What to find: *.sln, *.dacpac, *.publish.xml *.dtspac or *.sqlproject File. Options are: Solution, DacPac, DTSPac or Project',
                   Position=0)]
            [ValidateNotNullOrEmpty()]
            $executable,
    
            [Parameter(Mandatory=$true,
                   HelpMessage='Path where search for $typetofind should be started',
                   Position=0)]
            [ValidateNotNullOrEmpty()]
            $arguments,

            [Parameter(Mandatory=$true,
                   HelpMessage='Determines the basepath where logfiles should be stored. if empty the directory where the script is running will be used',
                   Position=0)]
            [Alias("lf")]
            [ValidateNotNullOrEmpty()]
            [String] $logfile,

            [Parameter(Mandatory=$true,
                   HelpMessage='Determines the basepath where logfiles should be stored. if empty the directory where the script is running will be used',
                   Position=0)]
            [Alias("elf")]
            [ValidateNotNullOrEmpty()]
            [String] $errorlogfile
        )
    $poutput = @{}
    $poutput.Output = [string]::Empty
    $poutput.ErrorOutput = [string]::Empty
    $poutput.Message = [string]::Empty
    $poutput.Duration = [TimeSpan]::Zero
    $poutput.Succeeded = $null
    $poutput.ExitCode = $null

    $logbase = Split-Path -path $logfile -Parent
    $errorlogbase = Split-Path -path $logfile -Parent

    if(-not(Test-Path -Path $logbase) -or -not(Test-Path -Path $errorlogbase)){
        
        $poutput.Message = "Could not find parent of $logfile or $errorlogfile unable to proceed to execute Cmd."

        Write-Error "$($poutput.message)"
        return $result
        throw;
    }

    try{

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $executable
        $pinfo.Arguments = $arguments
        
        #$pinfo.Passthru = $true
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false

        if($debug){
            $pinfo
        }
        #executing the command and storing the result inside $p:
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null

        $poutput.output = $p.StandardOutput.ReadToEnd()
        $poutput.erroroutput =  $p.StandardError.read()
        $poutput.Duration = $p.ExitTime - $p.StartTime
        $poutput.output | Out-file -literalpath $logfile -Force
        $poutput.erroroutput | Out-file -literalpath $errorlogfile -Force
        $poutput.ExitCode = $p.ExitCode

        return $poutput

    }catch{
        $errorMessage = $_
        $poutput.Message = "Unexpected error occurred while processing : $errorMessage"
        $poutput.Succeeded = $false
        Write-Error ($poutput.Message)
        return $poutput
        throw;
    }
}