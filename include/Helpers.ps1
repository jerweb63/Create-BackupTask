<#
    Helpers.ps1
    -----------
    

    USAGE:
    Functions that assist in creating a scheduled "Windows Server Backup" task.
    ---------------------------------------------------------------------------
    
    AUTHOR: J. Webster

    DATE: 12-10-2014

    VERSION: 1.0
#>


# Request. receive and store user input.
function getUserInput {
    
    # Grab individual prompt items.
    $inputStream = $null

    # Create an object to store user's input
    $input = New-Object System.Collections.ArrayList

    # Query the user's credentials and related information.
    $output = @( 
        "Enter account name for backup task:`nName"
        "Enter password for backup task:`nPassword",
        "Enter sender's email address:`nEmail sender",
        "Enter recipient's email address:`nEmail recipient",
        "Enter FQDN or IP-Address of smtp server:`nMail server",
        "Enter schedule cycle d for daily, w for weekly:`nSchedule cycle",
        "Enter network path of backup:`nPath");

    $count = $output.count

    for ( $value = 0; $value -lt $count; $value++ ) {
    	
    	Write-Host " "
        Write-Host $output[$value]"[$value]: " -NoNewline

        if ( $value -eq 1 ) {

            $inputStream = Read-Host -AsSecureString
        } 
        
        else {
        
            $inputStream = Read-Host
        }

        # Using void to preclude adding index positions.
        [void]$input.Add($inputStream)
    }

    return ,$input

}

# We stored the password in a SecureString object purely to obfuscate the display.
function decryptSecureString ( [System.Security.SecureString]$encryptedString ) {

    $marshalObject = [System.Runtime.InteropServices.Marshal]
    $pointerToObject = $marshalObject::SecureStringToBSTR(  $encryptedString )
    $decryptedString = $marshalObject::PtrToStringBSTR( $pointerToObject )
    
    # Clear memory location of encrypted string.
    $marshalObject::ZeroFreeBSTR( $pointerToObject )

    return $decryptedString
} 

# Configure task in the task scheduler
function createScheduledTask () {

    param (

	[string]$computerName = "$env:COMPUTERNAME",
    [string]$user = "",
	[string]$runAsUser = $env:USERDOMAIN + "\" + $user,
    [securestring]$encryptedPassword = "",
	[string]$taskName = "Backup",
	[string]$taskRun = '"C:\Windows\System32\windowspowershell\v1.0\powershell.exe C:\Beheer\Scripts\Backup.ps1 -enable"',
	[string]$schedule = "Weekly",
	[string]$modifier = "",
	[string]$days = '"MON,TUE,WED,THU,FRI"',
	[string]$months = '',
	[string]$startTime = "23:50",
	[string]$endTime = "",
	[string]$interval = ""   
    )

    $runPassword = decryptSecureString -encryptedString:$encryptedPassword
	$createScheduledTask = "schtasks.exe /create /s $computerName /ru $runAsUser /rp $runPassword /tn $taskName /tr $taskRun /sc $schedule /d $days /st $startTime /F"

	Invoke-Expression $createScheduledTask
	Clear-Variable Command -ErrorAction SilentlyContinue
	Write-Host "`n"
}