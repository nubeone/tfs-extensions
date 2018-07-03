# Merges the file at $path2 into the file at $path1, overwriting where necessary. Saves at $path1.
# Use: $path2 = new config from build, $path1 = old config in prod. 
# custom configuration in prod (from editor or such) is retained, while configurations done in code are updated

Trace-VstsEnteringInvocation $MyInvocation
try {
    $global:ErrorActionPreference = 'Stop'
    #$global: __vstsNoOverrideVerbose = $true
    Import-Module "$PSScriptRoot\utility.ps1"

    # Get inputs from TFS/VSTS
    $path1 = Get-VstsInput -Name "path1" -Require -ErrorAction "Stop"
    $path2 = Get-VstsInput -Name "path2" -Require -ErrorAction "Stop"

    $server = Get-VstsInput -Name "server" -Require -ErrorAction "Stop"
    $userName = Get-VstsInput -Name "userName" -Require -ErrorAction "Stop"
    $input_Password = Get-VstsInput -Name "password" -Require -ErrorAction "Stop"

    # build remote Session with the supplied credentials
    $password = ConvertTo-SecureString $input_Password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($userName, $password)
    $remote = New-PSSession -ComputerName $server -Credential $cred

    "Reading XML Files"
    [ xml ]$file1 = Invoke-Command -Session $remote -ScriptBlock { Get-Content -Path $USING:path1 } 
    [ xml ]$file2 = Get-Content -Path $path2

    if ($file1 -eq $null) {
        "Failed to read the existing XML file."
        if (Test-Path $path1) {
            "file exists at path $path1."
        } else {
            "file not found at path $path1."
        }
    }
    if ($file2 -eq $null) {
        "Failed to read the new XML file."
        if (Test-Path $path2) {
            "file exists at path $path2."
        } else {
            "file not found at path $path2."
        }
    }
    # find files' root node
    $xmlRoot1 = $file1.DocumentElement
    $xmlRoot2 = $file2.DocumentElement

    # import rootnode 2 and all its children into xml1 (else said children cannot be added there)
    $xmlRoot2 = $file1.ImportNode($xmlRoot2, $true)
    # merge root2 into root1
    $newRoot = mergeNodes $xmlRoot1 $xmlRoot2
    $file1.ReplaceChild($newRoot, $xmlRoot1)
    # save merged XML to path1 on remote server
    $scriptBlock = {
        param (
            [xml]$file,
            [string]$path
        )
        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        $sw = New-Object System.IO.StreamWriter($path, $false, $utf8Bom)
        $file.Save($sw)
        $sw.Close()
    }
    Invoke-Command -Session $remote -ScriptBlock $scriptBlock -ArgumentList ($file1, $path1)

    #close session
    Remove-PSSession $remote

} catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}