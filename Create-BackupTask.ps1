<#
    Create-BackupTask.ps1
    ---------------------


    USAGE:
    This script is used for calling various helper functions needed to create a new "Windows Server Backup" task.

    -------------------------------------------------------------------------------------------------------------
    
    AUTHOR: j.webster

    DATE: 12-10-2014
    
    VERSION: 1.0
#>


. .\include\Helpers.ps1
. .\include\Create-Script.ps1

$Create_BackupTask = {

    $version = 1.0
    $dayOfWeek = '""'
    $folderOut = "C:\Beheer\Scripts\"
    $fileOut = "Backup.ps1"
    $credentials = getUserInput
    $username = $credentials[0]
    $password = $credentials[1]
    $sender = $credentials[2]
    $recipient = $credentials[3]
    $server = $credentials[4]
    $cycle = $credentials[5]
    $path = $credentials[6]
    
    if ($cycle -eq "w") {
    
        $dayOfWeek = 'get-date -format dddd'
    
    }

    # Create the task for the backup job.
    createScheduledTask -encryptedPassword:$password -user:$username

    # Create the task script file.
    createScript -sender_:$sender -fileOut_:$fileOut -folderOut_:$folderOut -dayOfWeek_:$dayOfWeek -path_:$path -recipient_:$recipient -smtpServer_:$server -version_:$version
}

Invoke-Command -ScriptBlock $Create_BackupTask


