<#
    :: Check-Connection.ps1 

    Check connection to a list of computers defined in a CSV file by executing PING command.
    To avoid ICMP packages to be block by firewall is used NMap Ping
       
    @version 0.5
    @author: Ander F.L. for Cuatrovientos ITC
#>

# Get group name. The name of the file where students names and their IPs are stored
$group = '1asir'
# Get exam end time, when the script will automatically end
$examEndDate = (Get-Date).AddMinutes(60)
# Define arrays to store students IPs and students names
$ips = @()
$names = @()
# File where the log of students without connectivity is stored
$filename = "..\logs\connectivitylost.log" 

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
# :: Show-Dialog ::
# Ask observer to give a wake-up call to a student, giving his name and time 
# of the connection lost
## If the student is not in class the teacher can Ignore the message.
## so it will not appear again.
# @params: $name of the student, $time of the connection lost
#
function Show-Dialog([string]$name, $time){
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$time"
    $form.Size = New-Object System.Drawing.Size(300,300)
    $form.StartPosition = 'CenterScreen'
 
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(25,150)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'Aceptar'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $ignoreButton = New-Object System.Windows.Forms.Button
    $ignoreButton.Location = New-Object System.Drawing.Point(100,150)
    $ignoreButton.Size = New-Object System.Drawing.Size(75,23)
    $ignoreButton.Text = 'Ignorar'
    $ignoreButton.DialogResult = [System.Windows.Forms.DialogResult]::Ignore
    $form.CancelButton = $ignoreButton
    $form.Controls.Add($ignoreButton)

    $apButton = New-Object System.Windows.Forms.Button
    $apButton.Location = New-Object System.Drawing.Point(175,150)
    $apButton.Size = New-Object System.Drawing.Size(75,23)
    $apButton.Text = 'Analizar Wifis'
    $apButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $form.CancelButton = $apButton
    $form.Controls.Add($apButton)
            
    $labelStartTime = New-Object System.Windows.Forms.Label
    $labelStartTime.Location = New-Object System.Drawing.Point(10,60)
    $labelStartTime.Size = New-Object System.Drawing.Size(280,300)
    $labelStartTime.Text = "[$time]: $name está desconectado."
    $form.Controls.Add($labelStartTime)
    $form.Topmost = $true
    # Minimize console and mantain form in top
    $form.Add_Shown({
        $form.Activate()
        Hide-Console
    })
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::Ignore)
    {
        Add-Content -Path $env:TMP/absentstudents.txt -Value $name

    } elseif ($result -eq [System.Windows.Forms.DialogResult]::Yes)
    {
            .\Check-AccessPoints.ps1
    }
}
##
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
# :: Check-ConnectivityLost ::
#
# Execute a Nmap ping to verify student's connnection
# @params: ip of the students's computer
#
function Check-ConnectivityLost([string]$ip){
    $pingstatus = ""
    Write-Host "Scanning ip $ip"
    cmd.exe /C "nmap -sn $ip > %tmp%/exam_checker.txt"

    Start-Sleep -second 5
    $resultline =  Get-Content $env:TMP/exam_checker.txt | Where-Object {$_ -like 'Nmap done:*'}
    $ifUp = $resultline | Where-Object {$_ -like '*1 host up*'}
    if([string]::IsNullOrEmpty($ifUp)){
        return $true;
    } else {
        return $false;
    }
}
# Import-IPsFromCSV
# Read CSV file under /etc and gets a relation between students names
# and their IPs
# @params: $group is the name of the CSV file where students informatio is stored
#
function Import-IPsFromCSV([string] $group) {
    $csv = Import-Csv "..\etc\$group.csv"  -Header @("Nombre","IP") 
    # Take out header
    $csv | ForEach-Object {
        if($_.IP -ne 'IP'){
            $script:ips += $_.IP
        } 
        if($_.NOMBRE -ne 'NOMBRE'){
            $script:names += $_.NOMBRE
        } 
    }
}
# Analyze-IP
# Sets a loop until exam ends.
## every 60 seconds all students connection is analyzed.
## If student has no connection is registerend in the log file
## If students han no connection and is not in the missing list
## a Dialog will be shown to the teacher
#
function Analyze-IP(){
    do{
        #Write-Host "Waiting for 60 seconds..."
        #Start-Sleep -Seconds 30
        #Write-Host "30 seconds..."
        #Start-Sleep -Seconds 30

        Import-IPsFromCSV -group $group         

        for($cnt=0; $cnt -lt $script:ips.Length ; $cnt++ ){

           if( Check-ConnectivityLost  -ip $script:ips[$cnt]){
               # Add value to not logged computers file, pc offline
               Write-Output "$(Get-Date -Format 'yyyyMMdd')_$($group):  $($script:names[$cnt]); $($script:ips[$cnt]); $lastCheckTime;  offline" | Out-File  -append  -FilePath $filename
               # Check if student is in the absent students list
               if($script:names[$cnt] -notin (Get-Content -Path $env:TMP/absentstudents.txt)) {
                 # wake-up alert
                 start-process powershell  -arg ".\Check-Connection.ps1 Show-Dialog $($script:names[$cnt]) $(Get-Date -Format "HH:mm")" 
                 # Start-Job -ScriptBlock {Show-Dialog} -ArgumentList  $($script:names[$cnt]),$lastCheckTime
                 ## Debug purpouse
                 # Show-Dialog $($script:names[$cnt]) $lastCheckTime 
               }          
           }
        }
    
        $lastCheckDate = Get-Date
        Write-Host "Last check date: [$lastCheckDate]"

    }while( $lastCheckDate.TofileTime() -lt $examEndDate.TofileTime() )
}



if(($args.Count -eq 0) -or ($args.Count -eq 2)){
    Set-LogFile
    if (Test-Path $env:TMP/absentstudents.txt -PathType leaf){
        # Clear data from absent students list
        Clear-Content -Path $env:TMP/absentstudents.txt
    } else {
        New-Item -Path $env:TMP/absentstudents.txt -ItemType File *> $null
    } 
}

if($args.Count -eq 0){
    ## Debug purpuse
    Analyze-IP
    Write-Host "Exam end"
    exit
} elseif($args[0] -eq "Show-Dialog"){
    # Notify teacher about a not connected user
    Show-Dialog $args[1] $args[2]
}else {
    ## Main execution point
    $group = $args[0]
    $examEndDate = $args[1]
    Analyze-IP
    Write-Host "Exam end"
    exit
} 



