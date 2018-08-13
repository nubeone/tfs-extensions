Trace-VstsEnteringInvocation $MyInvocation
try {
    $global:ErrorActionPreference = 'Stop'

    # options
    $recurseCopy = Get-VstsInput -Name "recurseCopy" #copy recursively? (bool)
    $container = Get-VstsInput -Name "container" #retain folder structure? (bool)
    $includeCopy = Get-VstsInput -Name "includeCopy" #include filters for copying (string, contains comma-separated patterns)
    $excludeCopy = Get-VstsInput -Name "excludeCopy" #exclude filters for copying (string, contains comma-separated patterns)
    $forceCopy = Get-VstsInput -Name "forceCopy" #copy read-only files etc. too (bool)
    $clear = Get-VstsInput -Name "clear" #clear folder before copying (bool)
    $recurseDelete = Get-VstsInput -Name "recurseDelete" #delete files in subfolders too (bool)
    $includeDelete = Get-VstsInput -Name "includeDelete" #include filters for deleting (string, contains comma-separated patterns)
    $excludeDelete = Get-VstsInput -Name "excludeDelete" #exclude filters for deleting (string, contains comma-separated patterns)
    $forceDelete = Get-VstsInput -Name "forceDelete" #delete read-only, hidden etc. files too (bool)
    
    # source folder
    $remote1 = Get-VstsInput -Name "remote1" -Require -ErrorAction "Stop"
    Write-Host "remote1: $remote1"
    $sourcePath = Get-VstsInput -Name "sourcePath" -Require -ErrorAction "Stop"
    Write-Host "sourcePath: $sourcePath"
    if ($remote1 -eq "true") {
        Write-Host "detected source folder as remote. reading server, username, PW and opening connection."
        $server1 = Get-VstsInput -Name "server1" -Require -ErrorAction "Stop"
        $userName1 = Get-VstsInput -Name "userName1" -Require -ErrorAction "Stop"
        $input_Password1 = Get-VstsInput -Name "password1" -Require -ErrorAction "Stop"
        Write-Host "Server 1: $server1, userName1: $userName1, input_Password1: redacted. If this is wrong, the error message will tell."
        # build remote Session with the supplied credentials
        $password1 = ConvertTo-SecureString $input_Password1 -AsPlainText -Force
        $cred1 = New-Object System.Management.Automation.PSCredential ($userName1, $password1)
        $session1 = New-PSSession -ComputerName $server1 -Credential $cred1
        Write-Host "done opening session to remote server for source folder"
    }
    # destination folder
    $remote2 = Get-VstsInput -Name "remote2" -Require -ErrorAction "Stop"
    Write-Host "remote2: $remote2"
    $destinationPath = Get-VstsInput -Name "destinationPath" -Require -ErrorAction "Stop"
    Write-Host "destinationPath: $destinationPath"
    if ($remote2 -eq "true") {
        Write-Host "detected destination folder as remote. reading server, username, PW and opening connection."
        $server2 = Get-VstsInput -Name "server2" -Require -ErrorAction "Stop"
        $userName2 = Get-VstsInput -Name "userName2" -Require -ErrorAction "Stop"
        $input_Password2 = Get-VstsInput -Name "password2" -Require -ErrorAction "Stop"
        Write-Host "Server 2: $server2, userName2: $userName2, input_Password2: redacted. If this is wrong, the error message will tell."
        # build remote Session with the supplied credentials
        $password2 = ConvertTo-SecureString $input_Password2 -AsPlainText -Force
        $cred2 = New-Object System.Management.Automation.PSCredential ($userName2, $password2)
        $session2 = New-PSSession -ComputerName $server2 -Credential $cred2
        Write-Host "done opening session to remote server for destination folder"
    }

    #Copy
    if(($remote1 -eq "true") -and ($remote2 -eq "true")) {
        $script = {
            $server = $args[0]
            $cred = $args[1]
            $source = $args[2]
            $destination = $args[3]
            $session = New-PSSession -ComputerName $server -Credential $cred
            Copy-Item -ToSession $session -Path $source -Recurse -Destination $destination -force
        }
        #need to use the local user, so \userName instead of just userName
        Write-Host "Checking userName2 for local"
        if (!$userName2.StartsWith("\")) {
            Write-Host "adding Backslash to make userName local"
            $localUserName = "\" + $userName2
        } else {
            Write-Host "userName was already local, continuing"
            $localUserName = $userName2
        }
        $localUserCred = New-Object System.Management.Automation.PSCredential ($localUserName, $password2)
        Invoke-Command -Session $session1 -ScriptBlock $script -ArgumentList $server2, $localUserCred, $sourcePath, $destinationPath
    } elseif (($remote1 -eq "true") -and ($remote2 -eq "false")) {
        Copy-Item -FromSession $session1 -Path $sourcePath -Recurse -Destination $destinationPath -force
    } elseif (($remote1 -eq "false") -and ($remote2 -eq "true")) {
        Copy-Item -ToSession $session2 -Path $sourcePath -Recurse -Destination $destinationPath -force
    } elseif (($remote1 -eq "false") -and ($remote2 -eq "false")) {
        Copy-Item -Path $sourcePath -Recurse -Destination $destinationPath -force 
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