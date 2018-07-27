Trace-VstsEnteringInvocation $MyInvocation
try {
    $global:ErrorActionPreference = 'Stop'
    #$global: __vstsNoOverrideVerbose = $true

    # Get inputs from TFS/VSTS
    $source = Get-VstsInput -Name "sourcePath" -Require -ErrorAction "Stop"
    $filename = Get-VstsInput -Name "filename" -Require -ErrorAction "Stop"
    Set-Location $source
    git log --oneline  --date=format:"%Y-%m-%d %H:%M" --pretty=format "- %cd %h %s %d <%ce>" --no-merges > $filename
} catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}