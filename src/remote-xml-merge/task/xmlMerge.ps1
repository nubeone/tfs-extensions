Trace-VstsEnteringInvocation $MyInvocation
try {
    $global:ErrorActionPreference = 'Stop'
    #$global: __vstsNoOverrideVerbose = $true
    Import-Module "$PSScriptRoot\utility.ps1"

    # Get inputs from TFS/VSTS
    $conflictVictor = Get-VstsInput -Name "conflictVictor" -Require -ErrorAction "Stop"
    Write-Host "conflictVictor: $conflictVictor"
    # file 1
    $remote1 = Get-VstsInput -Name "remote1" -Require -ErrorAction "Stop"
    Write-Host "remote1: $remote1"
    $path1 = Get-VstsInput -Name "path1" -Require -ErrorAction "Stop"
    Write-Host "path1: $path1"
    if ($remote1 -eq "true") {
        Write-Host "detected file 1 as remote. reading server, username, PW and opening connection."
        $server1 = Get-VstsInput -Name "server1" -Require -ErrorAction "Stop"
        $userName1 = Get-VstsInput -Name "userName1" -Require -ErrorAction "Stop"
        $input_Password1 = Get-VstsInput -Name "password1" -Require -ErrorAction "Stop"
        Write-Host "Server 1: $server1, userName1: $userName1, input_Password1: redacted. If this is wrong, the error message will tell."
        # build remote Session with the supplied credentials
        $password1 = ConvertTo-SecureString $input_Password1 -AsPlainText -Force
        $cred1 = New-Object System.Management.Automation.PSCredential ($userName1, $password1)
        $session1 = New-PSSession -ComputerName $server1 -Credential $cred1
        Write-Host "done opening session to remote server for file 1"
    }
    # file 2
    $remote2 = Get-VstsInput -Name "remote2" -Require -ErrorAction "Stop"
    Write-Host "remote2: $remote2"
    $path2 = Get-VstsInput -Name "path2" -Require -ErrorAction "Stop"
    Write-Host "path2: $path2"
    if ($remote2 -eq "true") {
        Write-Host "detected file 2 as remote. reading server, username, PW and opening connection."
        $server2 = Get-VstsInput -Name "server2" -Require -ErrorAction "Stop"
        $userName2 = Get-VstsInput -Name "userName2" -Require -ErrorAction "Stop"
        $input_Password2 = Get-VstsInput -Name "password2" -Require -ErrorAction "Stop"
        Write-Host "Server 2: $server2, userName2: $userName2, input_Password2: redacted. If this is wrong, the error message will tell."
        # build remote Session with the supplied credentials
        $password2 = ConvertTo-SecureString $input_Password2 -AsPlainText -Force
        $cred2 = New-Object System.Management.Automation.PSCredential ($userName2, $password2)
        $session2 = New-PSSession -ComputerName $server2 -Credential $cred2
        Write-Host "done opening session to remote server for file 2"
    }
    # target file
    $remoteTarget = Get-VstsInput -Name "remoteTarget" -Require -ErrorAction "Stop"
    Write-Host "remoteTarget: $remoteTarget"
    if ($remoteTarget -eq "true") {
        Write-Host "detected target file as remote. reading server, username, PW and opening connection."
        $pathTarget = Get-VstsInput -Name "pathTarget" -Require -ErrorAction "Stop"
        $serverTarget = Get-VstsInput -Name "serverTarget" -Require -ErrorAction "Stop"
        $userNameTarget = Get-VstsInput -Name "userNameTarget" -Require -ErrorAction "Stop"
        $input_PasswordTarget = Get-VstsInput -Name "passwordTarget" -Require -ErrorAction "Stop"
        Write-Host "Target Server: $serverTarget, target userName: $userNameTarget, target input_Password: redacted. If this is wrong, the error message will tell."
        # build remote Session with the supplied credentials
        $passwordTarget = ConvertTo-SecureString $input_PasswordTarget -AsPlainText -Force
        $credTarget = New-Object System.Management.Automation.PSCredential ($userNameTarget, $passwordTarget)
        $sessionTarget = New-PSSession -ComputerName $serverTarget -Credential $credTarget
        Write-Host "done opening session to remote server for target file"
    } elseif ($remoteTarget -eq "false") {
        $pathTarget = Get-VstsInput -Name "pathTarget" -Require -ErrorAction "Stop"
        Write-Host "detected target as local file, path: $pathTarget"
    }


    Write-Host "Reading XML Files"
    if ($remote1 -eq "true") {
        [ xml ]$file1 = Invoke-Command -Session $session1 -ScriptBlock { Get-Content -Path $USING:path1 }
    } else {
        [ xml ]$file1 = Get-Content -Path $path1
    }
    if ($remote2 -eq "true") {
        [ xml ]$file2 = Invoke-Command -Session $session2 -ScriptBlock { Get-Content -Path $USING:path2 }
    } else {
        [ xml ]$file2 = Get-Content -Path $path2
    }
    if ($file1 -eq $null) {
        "Failed to read XML file 1"
    }
    if ($file2 -eq $null) {
        "Failed to read XML file 1"
    }
    Write-Host "Done reading file 1 and 2"

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
    Write-Host "merging..."
    $newRoot = mergeNodes $xmlRootSub $xmlRootDom
    $submissiveFile.ReplaceChild($newRoot, $xmlRootSub)
    Write-Host "merge complete"

    # scriptblock to save merged XML
    $SaveScriptBlock = {
        param (
            [xml]$file,
            [string]$path
        )
        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        $xmlsettings = New-Object System.Xml.XmlWriterSettings
        $xmlsettings.Encoding = $utf8Bom
        $xmlsettings.OmitXmlDeclaration = $true
        $xmlsettings.Indent = $true
        $xmlsettings.IndentChars = "    "
        $writer = [System.Xml.XmlWriter]::Create($path, $xmlsettings)
        $file.Save($writer)
        $writer.Flush()
        $writer.Close()
    }
    # save local, or remote? if remote, which session should be used?
    $saveRemote = $true
    Write-Host "switching on remoteTarget = $remoteTarget"
    switch ( $remoteTarget ) {
        "true" {
            Write-Host "remote target was true, using "
            $saveSession = $sessionTarget
            $savePath = $pathTarget
        }
        "false" {
            $saveRemote = $false
            $savePath = $pathTarget
        }
        "file1" {
            $savePath = $path1
            if ($remote1 -eq "true") {
                $saveSession = $session1
            } else {
                $saveRemote = $false
            }
        }
        "file2" {
            $savePath = $path2
            if ($remote2 -eq "true") {
                $saveSession = $session2
            } else {
                $saveRemote = $false
            }
        }
    }
    Write-Host "Detected setting for target file: remote = $saveRemote, path = $savePath"
    # save
    if ($saveRemote -eq $true) {
        Write-Host "saving to remote server using Session"
        Invoke-Command -Session $saveSession -ScriptBlock $SaveScriptBlock -ArgumentList ($submissiveFile, $savePath)
    } else {
        Write-Host "saving to local computer without session"
        Invoke-Command -ScriptBlock $SaveScriptBlock -ArgumentList ($submissiveFile, $savePath)
    }

    Write-Host "closing sessions..."
    #close sessions
    Get-PSSession | Remove-PSSession

} catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}