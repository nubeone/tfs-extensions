Trace-VstsEnteringInvocation $MyInvocation
try {
    $global:ErrorActionPreference = 'Stop'
    #$global: __vstsNoOverrideVerbose = $true
    Import-Module "$PSScriptRoot\utility.ps1"

    # Get inputs from TFS/VSTS
    $conflictVictor = Get-VstsInput -Name "conflictVictor" -Require -ErrorAction "Stop"

    # file 1
    $remote1 = Get-VstsInput -Name "remote1" -Require -ErrorAction "Stop"
    $path1 = Get-VstsInput -Name "path1" -Require -ErrorAction "Stop"
    if ($remote1 -eq "true") {
        $server1 = Get-VstsInput -Name "server1" -Require -ErrorAction "Stop"
        $userName1 = Get-VstsInput -Name "userName1" -Require -ErrorAction "Stop"
        $input_Password1 = Get-VstsInput -Name "password1" -Require -ErrorAction "Stop"
        # build remote Session with the supplied credentials
        $password1 = ConvertTo-SecureString $input_Password1 -AsPlainText -Force
        $cred1 = New-Object System.Management.Automation.PSCredential ($userName1, $password1)
        $remote1 = New-PSSession -ComputerName $server1 -Credential $cred1
    }
    # file 2
    $remote2 = Get-VstsInput -Name "remote2" -Require -ErrorAction "Stop"
    $path2 = Get-VstsInput -Name "path2" -Require -ErrorAction "Stop"
    if ($remote2 -eq "true") {
        $server2 = Get-VstsInput -Name "server2" -Require -ErrorAction "Stop"
        $userName2 = Get-VstsInput -Name "userName2" -Require -ErrorAction "Stop"
        $input_Password2 = Get-VstsInput -Name "password2" -Require -ErrorAction "Stop"
        # build remote Session with the supplied credentials
        $password2 = ConvertTo-SecureString $input_Password2 -AsPlainText -Force
        $cred2 = New-Object System.Management.Automation.PSCredential ($userName2, $password2)
        $remote2 = New-PSSession -ComputerName $server2 -Credential $cred2
    }
    # target file
    $remoteTarget = Get-VstsInput -Name "remoteTarget" -Require -ErrorAction "Stop"
    if ($remoteTarget -eq "true") {
        $pathTarget = Get-VstsInput -Name "pathTarget" -Require -ErrorAction "Stop"
        $serverTarget = Get-VstsInput -Name "serverTarget" -Require -ErrorAction "Stop"
        $userNameTarget = Get-VstsInput -Name "userNameTarget" -Require -ErrorAction "Stop"
        $input_PasswordTarget = Get-VstsInput -Name "passwordTarget" -Require -ErrorAction "Stop"
        # build remote Session with the supplied credentials
        $passwordTarget = ConvertTo-SecureString $input_PasswordTarget -AsPlainText -Force
        $credTarget = New-Object System.Management.Automation.PSCredential ($userNameTarget, $passwordTarget)
        $remoteTarget = New-PSSession -ComputerName $serverTarget -Credential $credTarget
    } elseif ($remoteTarget -eq "false") {
        $pathTarget = Get-VstsInput -Name "pathTarget" -Require -ErrorAction "Stop"
    }


    "Reading XML Files"
    if ($remote1 -eq "true") {
        [ xml ]$file1 = Invoke-Command -Session $remote1 -ScriptBlock { Get-Content -Path $USING:path1 }
    } else {
        [ xml ]$file1 = Get-Content -Path $path1
    }
    if ($remote2 -eq "true") {
        [ xml ]$file2 = Invoke-Command -Session $remote2 -ScriptBlock { Get-Content -Path $USING:path2 }
    } else {
        [ xml ]$file2 = Get-Content -Path $path2
    }
    if ($file1 -eq $null) {
        "Failed to read XML file 1"
    }
    if ($file2 -eq $null) {
        "Failed to read XML file 1"
    }

    # check which file wins conflicts
    if ($conflictVictor -eq "file1") {
        $dominantFile = $file1
        $submissiveFile = $file2
    } else {
        $dominantFile = $file2
        $submissiveFile = $file1
    }

    # find files' root node
    $xmlRootSub = $submissiveFile.DocumentElement
    $xmlRootDom = $dominantFile.DocumentElement

    # import dominant rootnode and all its children into submissive xml (else said children cannot be added there)
    $xmlRootDom = $submissiveFile.ImportNode($xmlRootDom, $true)
    # merge roots
    $newRoot = mergeNodes $xmlRoot1 $xmlRootDom
    $submissiveFile.ReplaceChild($newRoot, $xmlRootSub)

    # scriptblock to save merged XML
    $SaveScriptBlock = {
        param (
            [xml]$file,
            [string]$path
        )
        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        $sw = New-Object System.IO.StreamWriter($path, $false, $utf8Bom)
        $file.Save($sw)
        $sw.Close()
    }
    # save local, or remote? if remote, which session should be used?
    $saveRemote = $true
    switch ( $remoteTarget ) {
        "true" {
            $saveSession = $remoteTarget
            $savePath = $pathTarget
        }
        "false" {
            $saveRemote = $false
            $savePath = $pathTarget
        }
        "file1" {
            $savePath = $path1
            if ($remote1 -eq "true") {
                $saveSession = $remote1
            } else {
                $saveRemote = $false
            }
        }
        "file2" {
            $savePath = $path2
            if ($remote2 -eq "true") {
                $saveSession = $remote2
            } else {
                $saveRemote = $false
            }
        }
    }
    # save
    if ($saveRemote -eq $true) {
        Invoke-Command -Session $saveSession -ScriptBlock $SaveScriptBlock -ArgumentList ($submissiveFile, $savePath)
    } else {
        Invoke-Command -ScriptBlock $SaveScriptBlock -ArgumentList ($submissiveFile, $savePath)
    }

    #close sessions
    if ($remote1 -ne $null) { Remove-PSSession $remote1 }
    if ($remote2 -ne $null) { Remove-PSSession $remote2 }
    if ($remoteTarget -ne $null) { Remove-PSSession $remoteTarget }
    Remove-PSSession $remote

} catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}