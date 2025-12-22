Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------- FORM ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell Appx Package Manager"
$form.Size = New-Object System.Drawing.Size(950,650)
$form.StartPosition = "CenterScreen"

# ---------- RADIO BUTTONS ----------
$rbUninstall = New-Object System.Windows.Forms.RadioButton
$rbUninstall.Text = "Uninstall"
$rbUninstall.Location = New-Object System.Drawing.Point(20,20)
$rbUninstall.Checked = $true

$rbAllUsers = New-Object System.Windows.Forms.RadioButton
$rbAllUsers.Text = "Uninstall for All Users"
$rbAllUsers.Location = New-Object System.Drawing.Point(120,20)

$rbFutureUsers = New-Object System.Windows.Forms.RadioButton
$rbFutureUsers.Text = "Uninstall for Future Users"
$rbFutureUsers.Location = New-Object System.Drawing.Point(320,20)

$form.Controls.AddRange(@($rbUninstall,$rbAllUsers,$rbFutureUsers))

# ---------- FILTER CHECKBOX ----------
$cbRemovableOnly = New-Object System.Windows.Forms.CheckBox
$cbRemovableOnly.Text = "Show only removable apps"
$cbRemovableOnly.Location = New-Object System.Drawing.Point(520,22)
$form.Controls.Add($cbRemovableOnly)

# ---------- BUTTONS ----------
$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Display Installed Apps"
$btnLoad.Size = New-Object System.Drawing.Size(200,30)
$btnLoad.Location = New-Object System.Drawing.Point(20,60)

$btnExecute = New-Object System.Windows.Forms.Button
$btnExecute.Text = "Execute Selected Action"
$btnExecute.Size = New-Object System.Drawing.Size(220,30)
$btnExecute.Location = New-Object System.Drawing.Point(240,60)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export to CSV"
$btnExport.Size = New-Object System.Drawing.Size(150,30)
$btnExport.Location = New-Object System.Drawing.Point(480,60)

$form.Controls.AddRange(@($btnLoad,$btnExecute,$btnExport))

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

    # Suprimă warnings și erori
    $apps = @(Get-AppxPackage -ErrorAction SilentlyContinue 3>$null | Sort-Object Name)

    foreach ($app in $apps) {
        if ($cbRemovableOnly.Checked -and $app.NonRemovable) { continue }

        $item = New-Object System.Windows.Forms.ListViewItem($app.Name)
        $item.SubItems.Add($app.PackageFullName) | Out-Null
        $item.SubItems.Add($(if ($app.NonRemovable) { "No" } else { "Yes" })) | Out-Null

        if ($app.NonRemovable) {
            $item.ForeColor = [System.Drawing.Color]::Gray
            $item.Checked = $false
        }

        $listView.Items.Add($item) | Out-Null
    }
}

$btnLoad.Add_Click({ Load-Apps })
$cbRemovableOnly.Add_CheckedChanged({ Load-Apps })

# ---------- EXECUTE ----------
$btnExecute.Add_Click({
    $selected = $listView.CheckedItems
    if ($selected.Count -eq 0) { return }

    foreach ($item in $selected) {
        if ($item.SubItems[2].Text -eq "No") { continue }

        $name = $item.Text

        try {
            if ($rbUninstall.Checked) {
                Get-AppxPackage -Name $name -ErrorAction SilentlyContinue 3>$null | Remove-AppxPackage -Confirm:$false -ErrorAction SilentlyContinue
            }
            elseif ($rbAllUsers.Checked) {
                Get-AppxPackage -AllUsers -Name $name -ErrorAction SilentlyContinue 3>$null | Remove-AppxPackage -Confirm:$false -ErrorAction SilentlyContinue
            }
            elseif ($rbFutureUsers.Checked) {
                Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue 3>$null |
                    Where-Object DisplayName -eq $name |
                    Remove-AppxProvisionedPackage -Online -Confirm:$false -ErrorAction SilentlyContinue
            }
        } catch {}
    }

    Load-Apps
})

# ---------- EXPORT ----------
$btnExport.Add_Click({
    $path = "$env:USERPROFILE\Desktop\AppxPackages.csv"

    $data = @(Get-AppxPackage -ErrorAction SilentlyContinue 3>$null | Select Name, PackageFullName, NonRemovable)
    $data | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
})

# ---------- SHOW ----------
[void]$form.ShowDialog()
