#Blade Runner - Andrew Ortiz
#A Powershell wrapper for Plink.exe for easy scripting across multiple servers.

$version = ".4"

Function TempFile {
#increase compatibility with older versions of Powershell
$tmp = 'tmp-{0}' -f (get-random)
$tmp = Join-Path $Env:TMP -ChildPath $tmp
return ($tmp)
}


Function BladeRunner {
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$BAT                             = New-Object system.Windows.Forms.Form
$BAT.ClientSize                  = '610,605'
$BAT.text                        = "Blade Runner"
$BAT.TopMost                     = $false

#Provide version number
$VersionLabel                    = New-Object system.Windows.Forms.Label
$VersionLabel.text               = "Version: $version"
$VersionLabel.AutoSize           = $true
$VersionLabel.location           = New-Object System.Drawing.Point(545,5)

$UsernameLabel                   = New-Object system.Windows.Forms.Label
$UsernameLabel.text              = "Username"
$UsernameLabel.AutoSize          = $true
$UsernameLabel.Location          = New-Object System.Drawing.Point(5,7)

$Username                        = New-Object system.Windows.Forms.TextBox
$Username.width                  = 75
$Username.location               = New-Object System.Drawing.Point(65,5)

$PasswordLabel                   = New-Object system.Windows.Forms.Label
$PasswordLabel.text              = "Password"
$PasswordLabel.AutoSize          = $true
$PasswordLabel.Location          = New-Object System.Drawing.Point(145,7)

$Password                        = New-Object Windows.Forms.MaskedTextBox
$Password.PasswordChar           = '*'
$Password.width                  = 75
$Password.location               = New-Object System.Drawing.Point(205,5)


#Title for the servers box
$ServersLabel                    = New-Object system.Windows.Forms.Label
$ServersLabel.text               = "Servers"
$ServersLabel.AutoSize           = $true
$ServersLabel.location           = New-Object System.Drawing.Point(5,30)

#Location to insert a comma delimited list of servers
$Servers                         = New-Object system.Windows.Forms.TextBox
$Servers.multiline               = $true
$Servers.width                   = 600
$Servers.height                  = 150
$Servers.location                = New-Object System.Drawing.Point(5,55)
$Servers.ScrollBars              = "Vertical"

#Title for the commands box
$CommandsLabel                   = New-Object system.Windows.Forms.Label
$CommandsLabel.text              = "Command(s)"
$CommandsLabel.AutoSize          = $true
$CommandsLabel.location          = New-Object System.Drawing.Point(5,210)

#Location for bash commands
$Commands                        = New-Object system.Windows.Forms.TextBox
$Commands.multiline              = $true
$Commands.AcceptsReturn          = $true
$Commands.width                  = 600
$Commands.height                 = 150
$Commands.location               = New-Object System.Drawing.Point(5,230)
$Commands.ScrollBars             = "Vertical"

#Output field title
$OutputLabel                     = New-Object system.Windows.Forms.Label
$OutputLabel.text                = "Output"
$OutputLabel.AutoSize            = $true
$OutputLabel.location            = New-Object System.Drawing.Point(5,385)

#Place for command output
$Output                          = New-Object system.Windows.Forms.TextBox
$Output.multiline                = $true
$Output.AcceptsReturn            = $true
$Output.width                    = 600
$Output.height                   = 150
$Output.location                 = New-Object System.Drawing.Point(5,405)
$Output.ScrollBars               = "Vertical"

#Button to run the script
$Run                             = New-Object system.Windows.Forms.Button
$Run.text                        = "Run"
$Run.width                       = 60
$Run.height                      = 30
$Run.location                    = New-Object System.Drawing.Point(545,560)

#Checks for the existence of plink.exe and sets the path:
Set-Alias exist Test-Path -Option "Constant, AllScope"
if (exist 'C:\Program Files (x86)\PuTTY\plink.exe' ){$env:Path += ";C:\Program Files (x86)\PuTTY\"}
if (exist 'C:\Program Files\PuTTY\plink.exe' ){$env:Path += ";C:\Program Files\PuTTY\"}
#error out of plink is unavailable 
if (!(Get-Command plink.exe -errorAction SilentlyContinue)){
        [Windows.Forms.MessageBox]::show('Plink.exe not found', 'Error', 'Ok', 'Warning')
        exit
        }
    
#What happens when the Run button is pushed
$Run.Add_Click({

$pass = $Password.Text | ConvertTo-SecureString -AsPlainText -Force

$credentials = New-Object System.Management.Automation.PSCredential ($Username.Text, $pass)

#Disable double clicks of the run button
$Run.Enabled = $False
#$serverloop = $servers.Text
#Turn server string into a list if string contains a comma
if ($servers.Text -match ',') {
$serverloop = $servers.Text.split(",")
}else {
#split the list by lines and remove empties in the array 
$serverloop = $servers.Lines | Where { $_ -and $_.Trim() }
}


#Using a temp file to run as a bash script on the server allows for more complex actions
$tmp = TempFile
write-host $tmp
#Window's default encoding breaks scripts, write as ASCII
$Commands.Text | Out-File -FilePath $tmp -Encoding ASCII

#The core function here which runs the bash script on the servers.  Out-String prevents powershell from moving on before the command is complete
$out = foreach ($server in $serverloop){
Write-Host "`n### $server`n"
$Output.AppendText("$( echo "`n### $server`n"  |Out-String; echo y | plink.exe -ssh -pw $credentials.GetNetworkCredential().password -l $credentials.GetNetworkCredential().username $server -m "$tmp"| Out-String ; echo "`n";)")
}
#Clean up our tmp file
Remove-Item $tmp -Force

#Re-enable the run button after completion
$Run.Enabled = $True
})  

#Load all the fields
$BAT.controls.AddRange(@($VersionLabel,$UsernameLabel,$Username,$PasswordLabel,$Password,$ServersLabel,$CommandsLabel,$Servers,$Commands,$Run,$Output,$OutputLabel))

#Bring up the dialogue box
[void]$BAT.ShowDialog()

 
} #End Function 
 
#Call the Function 

BladeRunner

#Keep powershell open for output review 
pause
 

