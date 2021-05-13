<#
    :: Check-Ap.ps1 :: 

    Check Access points with a power of more than 80%.
    It shows the manufacturer of the device generating the wifi net.
    It avoid showing 4Vientos - Profesores and 4Vientos - Alumnos networks
        
    @version 0.6
    @author: Ander F.L. for Cuatrovientos ITC
#>

## The resulting data with the wifi network name
## the wifi signal's power and the wifi device manufacturer
$networks = @()
# File where the log of access points analyzes
$filename = "..\logs\accesspoints.log" 

##
# INIT VIEW
##
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
##Abrir PowerShell Script y ocultar el símbolo del sistema, pero no la GUI
#https://www.it-swarm-es.com/es/powershell/abrir-powershell-script-y-ocultar-el-simbolo-del-sistema-pero-no-la-gui/829389668/
# .Net methods for hiding/showing the console in the background
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
function Hide-Console
{
    $consolePtr = [Console.Window]::GetConsoleWindow()
    #0 hide
    [Console.Window]::ShowWindow($consolePtr, 0)
}
##
# Shows a Dialog with the resulting information to notify
## user about wifi networks
function Show-APNotificationForm(){
    $form = New-Object System.Windows.Forms.Form

    $form.Text = "Puntos WIFI"
    $form.Size = New-Object System.Drawing.Size(450,350)
    $form.StartPosition = 'CenterScreen'
           
    $text = New-Object System.Windows.Forms.TextBox 
    $text.Multiline = $True;
    $text.Location = New-Object System.Drawing.Size(10,10) 
    $text.Size = New-Object System.Drawing.Size(400,200)
    $text.Scrollbars = "Vertical" 
    $text.Text = $script:networks
    $form.Controls.Add($text)

    $form.Topmost = $true
    # Minimize console and mantain form in top
    $form.Add_Shown({
        $form.Activate()
        Hide-Console
    })
    $result = $form.ShowDialog()
  
}##
# END VIEW
##

##
# :: Set-LogFile ::
# All information related to connection lost is registered
## in the log file, even if the user select to ignore a absent student
function Set-LogFile(){
    # log file created at first execution
    if (!(Test-Path $script:filename))
    {
       New-Item -path ".." -name logs -type "directory" *>$null
       New-Item -path "..\logs" -name connectivitylost.log -type "file" *>$null
       Set-Content -path $script:filename -value "[$(Get-Date)]: Creation of Log file"
    }
} 
##
# Read configuration file.
# specifies minimal wifi power value and known wifi networks
#default values
$minWifiPower = 30
$knownNetworks = @('4V-Alumnos', '4V-Profesores')
$config = '..\etc\check-ap.conf'
function Get-Configuration(){

    if (Test-Path $config -PathType leaf)
    {
        foreach($conf in (Get-Content -Path $script:config) ){        
            $key, $values = $conf.Split(':')
            if($key -eq 'min-power'){
                [int]$script:minWifiPower = $values
            } elseif($key -eq  'known-networks') {
                foreach($knownNetwork in $values){
                  $script:knownNetworks += $knownNetwork.Split(',')
                }
            }

        }
    } 

}

##
# Detects wifi networks and filter them 
# by a minimum signal power and avoiding known wifi names
# returns a string with name of the wifi net, signal power and manufacturer of the wifi device
#
function Analyze-WifiAccessPoints(){
    ## Run command to detect wifi networks around
    # saves the result in a temporary file    
    Start-Job -Name JobFindWifi -ScriptBlock { (netsh wlan show networks mode=Bssid) | Set-Content -Path $env:TEMP\checkAP.txt   }
    Wait-Job -Name JobFindWifi
    # Chunk temporary file's info to get each network's data
    $strCheckAP = (Get-Content  -Path $env:TEMP\checkAP.txt | Select-Object -Skip 3 ) | Out-String 
    $nl = [System.Environment]::NewLine
    $infoNtwrks = ($strCheckAP -split "$nl$nl")
    foreach($info in  $infoNtwrks){
        # Filter data to just get wifi name, signal power and MAC address
        foreach($item in $info.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)){
            $item = $item.Trim()
            if(!$item.StartsWith("BSSID")){
                 $key, $value = $item.Split(':')       

                if($key.StartsWith("SSID")){
                  $ntwrk = $value
                } elseif($key.StartsWith("Signal") -or $key.StartsWith("Se")){
                   # Remove % character from signal power 
                   [int]$signal = $value.substring(0, $value.Length - 1)               
                }
            } else {
                $key, $oui = $item.Split(':') 
                $oui = $oui -join(':')  
            }      

         }         # If conditions are full filled          # search for manufacturer        if(($ntwrk -notin $script:knownNetworks)  -and ($script:minWifiPower -le $signal)){            try
            {
                Start-Sleep -Seconds 5
                $macvendor = Invoke-WebRequest -Uri “https://api.macvendors.com/$oui”
                $macvendor = $macvendor.Content
            }
            catch
            {
                # Detect mac-randomized
                # https://www.mist.com/get-to-know-mac-address-randomization-in-2020/
                $randomvalues = @(2,6,'a','e')
                $str = $oui.ToCharArray()
                $macrandom = $str[2]
                if( $macrandom -in $randomvalues ) {
                    $macvendor =  "Randomized mac"
                } else {
                   $macvendor =  "Device vendor not found"
                }            
            }
            $script:networks += " - $ntwrk con señal $signal creada por $macvendor $nl"            # Add value to not logged computers file, pc offline
            Write-Output "$(Get-Date -Format 'yyyyMMdd HH:mm'):  $ntwrk con señal $signal creada por $macvendor [$oui]" | Out-File  -append  -FilePath $filename
                       }
    
    }
}


## Main starting point
Set-LogFile
Get-Configuration
Analyze-WifiAccessPoints
Show-APNotificationForm


