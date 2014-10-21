<#
    Create-Script.ps1
    -----------------

    
    USAGE:
    Creates a script for running a scheduled "Windows Server Backup" task.
    
    ARGS:
    ------------------------------------------------------------------------------------

    -dayOfWeek: Sets whether the backup cycle is to folders labeled Monday thru Friday, or daily.
    
    -path: Network storage location where backup will be saved.
    
    -recipient: The email address to which a notification will be sent.
    
    -sender: The email address from which a notification is sent.
    
    -smtpServer: The IP-address or FQDN of mail server.
    
    -fileOut: The file name of the script.
    
    -folderOut: The directory where the script should be placed.
    
    -version: The version number of the script.

    ------------------------------------------------------------------------------------

    AUTHOR: J. Webster
    
    DATE: 12-10-2014
    
    VERSION: 1.0
#>


function createScript () {

    param (
        
        $dayOfWeek_ = $null,
        $path_ = $null,
        $recipient_ = $null,
        $sender_ = $null,
        $smtpServer_ = $null,
        $fileOut_ = $null,
        $folderOut_ = $null,
        $version_ = $null
    )


$scriptOutput = @"
<#
    $fileOut_
    ---------

    
    USAGE:    
    This script is used to write a backup of a computer to a network storage location.
    To start a backup, simply call the script as ".\Backup.ps1 -enable". 

    ARGS:
    -----------------------------------------------------------------------------------------

    -enable:
    
     Appending this argument to the command will execute a backup of the system.
     When script is called without arguments, the last backup status will be shown.
    
    -----------------------------------------------------------------------------------------
      
    REQUIREMENTS:
    
    1. Powershell v2.0. 
    2. Access to writeable share.
    3. Proper user authorization.
             
    AUTHOR: J. Webster
    
    DATE: 20-10-2014 
    
    VERSION: $version_
 #>


[CmdletBinding()]
param( [switch]`$enable )

`$hostName = get-content env:computername
`$dayOfWeek = $dayOfWeek_
`$logPath = "C:\Beheer\Logs\`$hostName.log"
`$storagePath = "$path_" + "\" + `$hostName + "\" +`
  [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase("`$dayOfWeek")
`$recipient = "$recipient_"
`$sender = "$sender_"
`$smtpServer = "$smtpServer_"


function sendNotification(`$customize) {
   
    `$envelope = @{                        
        Subject = "Backup of computer `$env:USERDOMAIN `$hostName"                      
        Body = [string]::join([environment]::newline, (get-content -path `$logPath))                        
        From = "`$sender"                        
        To = "`$recipient"                       
        SmtpServer = "`$smtpServer"
    }
    
    if (`$customize -eq "1") {

        `$customMessage = "No events were found that match the specified selection criteria."
        `$envelope.Body = `$customMessage
    }

    Send-MailMessage @envelope
}


# Determines under which condition a notification is sent.
function getBackupStatus (`$dateEnd, `$dateStart, `$excludeStart, `$excludeEnd, `$conditions) {

    Set-Variable -Name returnValue -Value `$null -Scope 0

    `$count = `$conditions.Length
   
    for (`$value = 0; `$value -lt `$count ; `$value++) {
   
        try {

            `$field = `$conditions[`$value].field
            `$state = `$conditions[`$value].state
            
            switch (`$value) {

                0 { 
                
                    `$statusCode = "OK:" 
                }
                 
                1 { 
                
                    `$statusCode = "CRITICAL:" 
                } 

                2 { 
                
                    `$statusCode = "WARNING:" 
                }
            }

            if (`$dataObject = Get-WinEvent -FilterHashtable @{Logname=’Microsoft-Windows-Backup';`
                StartTime=`$dateStart;EndTime=`$dateEnd} -ErrorAction Stop |`
                Where-Object{`$_.`$field -eq `$state} | Select-Object -first 1 | Format-Wide -Property Message) { 
            
                # We'd like to show the message string, not the object.
                `$messageOutput = Format-List -InputObject `$dataObject | Out-String
                
                # We don't want the \n character that the Out-String method places in the variable.
                Write-Host "`$statusCode " `$messageOutput.Replace("`r`n",'')

                
                if (`$messageOutput) {
                
                    switch (`$statusCode) {
                
                        "OK:" { 
                
                    	    `$returnValue = 0 
                        }
                
                        "CRITICAL:" { 
                
                    	    sendNotification
                            `$returnValue = 1 
                        }
                
                        "WARNING:" {

                            sendNotification
                    	    `$returnValue = 2
                        }
                
                        default { 
                
                    	    "Something bad happend."
                            `$returnValue = 2
                        }
                    }
                }

                return `$returnValue

            }
        
        }

        catch {

            # In case no events were generated send critical status.
            if (`$value -eq 1) {
                
           
                sendNotification -customize:1
                `$returnValue = 3
                return `$returnValue
            }
        }

    }
}


function backupComputer {
    
    `$disk = Get-WmiObject win32_logicaldisk | WHERE {`$_.DriveType -match “3”} | ForEach-Object { `$_.name }

    if (`$disk.Length -ge 2) {

        foreach (`$drivename in `$disk) {

            if (`$drivename -ne "C:") {

                `$target += "," + `$drivename
            }
        }

      `$target = '"' + `$target + '"'
    }
    
    if (`$backup -eq `$true) {

        wbadmin start backup -backupTarget:`$storagePath -include:C:`$target -allCritical -quiet > `$logPath
    }

    `$selection = @( @{"field"="Id";"state"=4};
                @{"field"="LevelDisplayName";"state"="Fout"}
                @{"field"="LevelDisplayName";"state"="Waarschuwing"})

<#
    The parameters '-dateEnd' and '-dateStart' define a timeframe in which the script checks for conditions, e.g. between Monday and Tuesday.
     
    The params '-excludeStart' and '-excludeEnd' define the days on which the check should not be executed, usually Sunday and Monday.
#>
    `$exitCode = getBackupStatus -dateEnd:(Get-Date) -dateStart:(Get-Date).AddDays(-1) -excludeStart:0 -excludeEnd:1 -conditions:`$selection;
}
 
if ( Test-Path -PathType CONTAINER `$storagePath ) {

    backupComputer
} 

else {

    New-Item -ItemType Directory -Force -Path 
    backupComputer
}

exit
"@

    $scriptOutput | Out-File $folderOut_$fileOut_
}