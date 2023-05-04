Import-Module -Name Pester
Import-Module -Name PSScriptAnalyzer

Describe 'Module-level tests' {

    it 'the module imports successfully' {
        { Import-Module "$PSScriptRoot\MAUCacheAdmin\MAUCacheAdmin.psm1" -ErrorAction Stop } | should -not -throw
    }

    it 'the module has an associated manifest' {
        Test-Path "$PSScriptRoot\MAUCacheAdmin\MAUCacheAdmin.psd1" | should -Be $true
    }

    it 'passes all default PSScriptAnalyzer rules' {
        Invoke-ScriptAnalyzer -Path "$PSScriptRoot\MAUCacheAdmin\MAUCacheAdmin.psm1" | should -BeNullOrEmpty
    }
}

Describe "All functions pass PSScriptAnalyzer rules" {
    BeforeDiscovery {
        $scripts = Get-ChildItem -Path "$PSScriptRoot\MAUCacheAdmin\*.ps1" -Recurse -File

        Write-Debug "Debug $($script.Count)"


        $testCases = foreach ($script in $scripts)
        {
            $results = Invoke-ScriptAnalyzer -Path $script.FullName -Verbose:$false

            if ($null -eq $results) {
                @{
                    Path     = $script.FullName
                    Pass     = $true
                    Rule     = "Passed all rules"
                    Severity = $null
                    Line     = $null
                    Message  = $null
                }
                continue
            }

            foreach ($rule in $results)
            {
                @{
                    Path     = $script.FullName
                    Pass     = $false
                    Rule     = $rule.RuleName
                    Severity = $rule.Severity
                    Line     = $rule.Line
                    Message  = $rule.Message
                }
            }
        }
    }

    it "[<Rule>] <Path>" -TestCases $testCases -Skip:(!$testCases) {
        param($Severity,$Path,$Line,$Message)
        $because = "$Severity $Message - $($Path):$Line"
        $Message | Should -BeNullOrEmpty -Because $because
    }
}