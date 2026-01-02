Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------
# PowerShell Appx Package Manager
# Tool for IT administrators to view and remove Appx apps
# ---------------------------------------------------------

# ---------- FORM ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell Appx Package Manager"
$form.Size = New-Object System.Drawing.Size(950,650)
$form.StartPosition = "CenterScreen"

# ---------- RADIO BUTTONS ----------
$rbUninstall = New-Object System.Windows.Forms.RadioButton
$rbUninstall.Text = "Uninstall"
$rbUninstall.AutoSize = $true
$rbUninstall.Location = New-Object System.Drawing.Point(20,20)
$rbUninstall.Checked = $true

$rbAllUsers = New-Object System.Windows.Forms.RadioButton
$rbAllUsers.Text = "Uninstall for All Users"
$rbAllUsers.AutoSize = $true
$rbAllUsers.Location = New-Object System.Drawing.Point(120,20)

$rbFutureUsers = New-Object System.Windows.Forms.RadioButton
$rbFutureUsers.Text = "Uninstall for Future Users"
$rbFutureUsers.AutoSize = $true
$rbFutureUsers.Location = New-Object System.Drawing.Point(300,20)

$form.Controls.AddRange(@($rbUninstall,$rbAllUsers,$rbFutureUsers))

# ---------- FILTER CHECKBOX ----------
$cbRemovableOnly = New-Object System.Windows.Forms.CheckBox
$cbRemovableOnly.Text = "Show only removable apps"
$cbRemovableOnly.AutoSize = $true
$cbRemovableOnly.Location = New-Object System.Drawing.Point(520,20)
$form.Controls.Add($cbRemovableOnly)

# ---------- BUTTONS (MAI ÎNGUSTE) ----------
$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Display Installed Apps"
$btnLoad.Size = New-Object System.Drawing.Size(160,30)
$btnLoad.Location = New-Object System.Drawing.Point(20,60)

$btnExecute = New-Object System.Windows.Forms.Button
$btnExecute.Text = "Execute Selected Action"
$btnExecute.Size = New-Object System.Drawing.Size(160,30)
$btnExecute.Location = New-Object System.Drawing.Point(190,60)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export to CSV"
$btnExport.Size = New-Object System.Drawing.Size(160,30)
$btnExport.Location = New-Object System.Drawing.Point(360,60)

$form.Controls.AddRange(@($btnLoad,$btnExecute,$btnExport))

# ---------- CLICKABLE LINK LABEL ----------
$link = New-Object System.Windows.Forms.LinkLabel
$link.Text = "revolut.me/romeotaranu"
$link.AutoSize = $true
$link.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$link.LinkColor = [System.Drawing.Color]::Blue
$link.Location = New-Object System.Drawing.Point(530, 65)

# Când dai click, deschide browserul
$link.Add_LinkClicked({
    Start-Process "https://revolut.me/romeotaranu"
})

$form.Controls.Add($link)

# ---------- LISTVIEW ----------
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(20,110)
$listView.Size = New-Object System.Drawing.Size(900,480)
$listView.View = "Details"
$listView.CheckBoxes = $true
$listView.FullRowSelect = $true
$listView.GridLines = $true

$listView.Columns.Add("Name",260) | Out-Null
$listView.Columns.Add("PackageFullName",480) | Out-Null
$listView.Columns.Add("Removable",120) | Out-Null

$form.Controls.Add($listView)

# ---------- LOAD APPS ----------
function Load-Apps {
    $listView.Items.Clear()

    try {
        $apps = Get-AppxPackage | Sort-Object Name
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to load Appx packages.")
        return
    }

    foreach ($app in $apps) {
        if ($cbRemovableOnly.Checked -and $app.NonRemovable) { continue }

        $item = New-Object System.Windows.Forms.ListViewItem($app.Name)
        $item.SubItems.Add($app.PackageFullName) | Out-Null
        $item.SubItems.Add($(if ($app.NonRemovable) { "No" } else { "Yes" })) | Out-Null

        if ($app.NonRemovable) {
            $item.ForeColor = [System.Drawing.Color]::Gray
        }

        $listView.Items.Add($item) | Out-Null
    }
}

$btnLoad.Add_Click({ Load-Apps })
$cbRemovableOnly.Add_CheckedChanged({ Load-Apps })

# ---------- EXECUTE ----------
$btnExecute.Add_Click({
    $selected = $listView.CheckedItems
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No apps selected.")
        return
    }

    foreach ($item in $selected) {
        if ($item.SubItems[2].Text -eq "No") { continue }

        $name = $item.Text

        try {
            if ($rbUninstall.Checked) {
                Get-AppxPackage -Name $name | Remove-AppxPackage -Confirm:$false
            }
            elseif ($rbAllUsers.Checked) {
                Get-AppxPackage -AllUsers -Name $name | Remove-AppxPackage -Confirm:$false
            }
            elseif ($rbFutureUsers.Checked) {
                Get-AppxProvisionedPackage -Online |
                    Where-Object DisplayName -eq $name |
                    Remove-AppxProvisionedPackage -Online -Confirm:$false
            }
        }
        catch {
            Write-Host "Error uninstalling $name"
        }
    }

    Load-Apps
})

# ---------- EXPORT ----------
$btnExport.Add_Click({
    $path = "$env:USERPROFILE\Desktop\AppxPackages.csv"

    try {
        Get-AppxPackage |
            Select Name, PackageFullName, NonRemovable |
            Export-Csv -Path $path -NoTypeInformation -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show("Exported to $path")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to export CSV.")
    }
})

# ---------- SHOW ----------
[void]$form.ShowDialog()
