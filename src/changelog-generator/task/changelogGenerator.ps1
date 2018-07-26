Trace-VstsEnteringInvocation $MyInvocation
try {
    $global:ErrorActionPreference = 'Stop'
    #$global: __vstsNoOverrideVerbose = $true
    Import-Module "$PSScriptRoot\utility.ps1"

    # Get inputs from TFS/VSTS
    $filename = Get-VstsInput -Name "filename" -Require -ErrorAction "Stop"
    git log --oneline  --date=format:"%Y-%m-%d %H:%M" --pretty=format "- %cd %h %s %d <%ce>" --no-merges > $filename
} catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}