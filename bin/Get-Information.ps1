<#
    :: Get-Information.ps1 ::
    Checks computers connection in a LAN.

    This script is used to detect students disconected from organizational network
    during an exam.
    The aim of the script is to avoid the use of mobile phone access points during exams.

    @version 0.5
    @author: Ander F.L. for Cuatrovientos ITC
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# :: Show-InitialWindow ::
# Shows a WinForm asking for the required parameters to launch de script
# - $cbGroup: must be the name of a CSV file cotaining the user name and IP
# - $dtpStartTime: start time of the exam in houers and minutes format HH:MM
# - $dtpEndTime: end time of the exam in hours and minutes format HH:MM
function Show-InitialWindow(){
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Cuatrovientos ITC'
    $form.Size = New-Object System.Drawing.Size(300,300)
    $form.StartPosition = 'CenterScreen'

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,150)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'Lanzar'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(175,150)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancelar'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    # Group name must be the same of the CSV located in the same folder
    $labelGroup = New-Object System.Windows.Forms.Label
    $labelGroup.Location = New-Object System.Drawing.Point(10,20)
    $labelGroup.Size = New-Object System.Drawing.Size(280,20)
    $labelGroup.Text = 'Grupo de la clase de AD:'
    $form.Controls.Add($labelGroup)

    $cbGroup = New-Object System.Windows.Forms.ComboBox
    $cbGroup.Location = New-Object System.Drawing.Point(10,40)
    $cbGroup.Size = New-Object System.Drawing.Size(260,20)
    # Fill combobox with file names under \etc directory
    $groups = Get-ChildItem ..\etc | Select-Object Name 
    $firstFileName, $firstFileFormat = ($groups[0]).Name.Split('\.')

    foreach($g in $groups) 
    {
        $gFileName, $gFileFormat = $g.Name.Split('\.')
        if($gFileFormat -eq "csv"){
            $cbGroup.Items.add($gFileName) *> $null
        }
    }

    $cbGroup.text = $firstFileName
    $form.Controls.Add($cbGroup)
    # End time
    $labelEndTime = New-Object System.Windows.Forms.Label
    $labelEndTime.Location = New-Object System.Drawing.Point(10,100)
    $labelEndTime.Size = New-Object System.Drawing.Size(280,20)
    $labelEndTime.Text = 'Hora fin: (HH:mm)'
    $form.Controls.Add($labelEndTime)

    $dtpEndTime = New-Object System.Windows.Forms.DateTimePicker
    $dtpEndTime.Format = [windows.forms.datetimepickerFormat]::custom
    $dtpEndTime.CustomFormat = “HH:mm”
    $dtpEndTime.Location = New-Object System.Drawing.Point(10,120)
    $dtpEndTime.Size = New-Object System.Drawing.Size(260,20)
    $dtpEndTime.MinDate = (Get-Date).AddMinutes(60).ToString("HH:mm")
    $form.Controls.Add($dtpEndTime)
    ##
    $form.Topmost = $true
    $form.Add_Shown({$cbGroup.Select()})
    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $group = $cbGroup.Text
        $end = (Get-Date $dtpEndTime.Text)
        # Launch script to check if IPs from CSV file till the end of the exam 
        ./Check-Connection $group $end 
    }
}

## Main execution point
Show-InitialWindow  
