Trace-VstsEnteringInvocation $MyInvocation
try {
    $global:ErrorActionPreference = 'Stop'

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

        # options, using splatting
        $copyOptions = @{
            Path = $sourcePath
            Destination = $destinationPath
            Recurse = Get-VstsInput -Name "recurseCopy" -AsBool -Default $true #copy recursively? (bool)
            Container = Get-VstsInput -Name "container" -AsBool -Default $true #retain folder structure? (bool)
            Include = Get-VstsInput -Name "includeCopy" -Default "" | foreach-object { $_.split(",").trim() } #include filters for copying (string, contains comma-separated patterns)
            Exclude = Get-VstsInput -Name "excludeCopy" -Default "" | foreach-object { $_.split(",").trim() } #exclude filters for copying (string, contains comma-separated patterns)
            Force = Get-VstsInput -Name "forceCopy" -AsBool -Default $true #copy read-only files etc. too (bool)
        }
        $clear = Get-VstsInput -Name "clear" -AsBool -Default $false #clear folder before copying (bool)
        $clearOptions = @{
            Path = $destinationPath
            Recurse = Get-VstsInput -Name "recurseDelete" -AsBool -Default $true #delete files in subfolders too (bool)
            Include = Get-VstsInput -Name "includeDelete" -Default "" | foreach-object { $_.split(",").trim() } #include filters for deleting (string, contains comma-separated patterns)
            Exclude = Get-VstsInput -Name "excludeDelete" -Default "" | foreach-object { $_.split(",").trim() } #exclude filters for deleting (string, contains comma-separated patterns)
            Force = Get-VstsInput -Name "forceDelete" -AsBool -Default $false #delete read-only, hidden etc. files too (bool)
        }

    #Clear
    if ($clear -eq $true) {
        $clearScript = {
            $options = $args[0]
            # Remove-Item with recurse has a known issue (according to microsoft documentation), so use Get-Childitem | Remove-Item
            Get-ChildItem @options | Remove-Item @options
        }
        $invokeOptions = @{
            ScriptBlock = $clearScript
            ArgumentList = $clearOptions
        }
        if ($remote2 -eq "true") {
            $invokeOptions.Session = $session2
        } 
        Invoke-Command @invokeOptions
    }

    #Copy
    if(($remote1 -eq "true") -and ($remote2 -eq "true")) { #needs special handling since copy-item can't deal with having both -FromSession and -ToSession
        $script = {
            $server = $args[0]
            $cred = $args[1]
            $options = $args[2]
            $session = New-PSSession -ComputerName $server -Credential $cred
            $options.ToSession = $session
            Copy-Item @options
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
    } else {
        if ($remote1 -eq "true") {
            $copyOptions.FromSession = $session1
        } elseif ($remote2 -eq "true") {
            $copyOptions.ToSession = $session2
        }
        Copy-Item @copyOptions
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