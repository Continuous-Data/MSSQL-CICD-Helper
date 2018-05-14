$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Describe "PSScriptAnalyzer rule-sets" -Tag Build {

    $Rules = Get-ScriptAnalyzerRule
    $excludedRules = (
        'PSAvoidUsingConvertToSecureStringWithPlainText', # For private token information
        'PSAvoidUsingUserNameAndPassWordParams' # this refers to gitlab users and passwords
        )
    $scripts = Get-ChildItem $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse | where fullname -notmatch 'classes'

    foreach ( $Script in $scripts )
    {
        Context "Script '$($script.FullName)'" {
            $results = Invoke-ScriptAnalyzer -Path $script.FullName -includeRule $Rules -Severity Error -ExcludeRule $excludedRules -Verbose:$false
            if ($results)
            {
                foreach ($rule in $results)
                {
                    It $rule.RuleName {
                        $message = "{0} Line {1}: {2}" -f $rule.Severity, $rule.Line, $rule.message
                        $message | Should Be ""
                    }

                }
            }
            else
            {
                It "Should not fail any rules" {
                    $results | Should BeNullOrEmpty
                }
            }
        }
    }
}