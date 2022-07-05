# Import required module
import-module msonline

# Initial variable states

[boolean]$global:connected = $false
[boolean]$global:success = $false

# MFA Functions

Function Enable-AzureMFA {
	param(
        [parameter(Mandatory=$true)]
		[string]$UPN
	)

	$st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement -Property @{
		State = "Enabled";
		RelyingParty = "*";
	}
	try {
		Set-MsolUser -UserPrincipalName $UPN -StrongAuthenticationRequirements $st -Erroraction Stop
		[boolean]$global:success = $true
		return $global:success
	} catch {
		[boolean]$global:success = $false
		return $global:success
	}
	Remove-variable -name st,success -force -Erroraction silentlycontinue
}

Function Disable-AzureMFA {
	param(
        [parameter(Mandatory=$true)]
		[string]$UPN
	)

	try {
		Set-MsolUser -UserPrincipalName $UPN -StrongAuthenticationRequirement @() -ErrorAction Stop
		[boolean]$global:success = $true
	} catch {
		[boolean]$global:success = $false
	}
	Remove-variable -name exists,mfastatus -force -Erroraction silentlycontinue
}

Function ReReg-AzureMFA {
	param(
        [parameter(Mandatory=$true)]
		[string]$UPN
	)

	$p=@()
	try {
		Set-MsolUser -UserPrincipalName $UPN -StrongAuthenticationMethods $p -Erroraction Stop
		[boolean]$global:success = $true
	} catch {
		[boolean]$global:success = $false
	}
	Remove-variable -name p -force -Erroraction silentlycontinue
}

Function Check-AzureMFA {
	param(
        [parameter(Mandatory=$true)]
		[string]$UPN
	)

	try {
		$exists = Get-MSOLUser -UserPrincipalName $UPN -ErrorAction Stop
		$state= $exists.StrongAuthenticationRequirements.State
		if (!$state) {
			$state="Disabled"
		}
		$MFAStatus = New-Object -TypeName PSObject -Property @{
			User = $UPN
			State = $state
		}
		return $MFAStatus
	} catch {
		return "Could not retrieve MFA status for user $($UPN), error was:`n$($_.Exception.Message)"
	}	
}

Function Show-AzureMFA {
	param(
        [parameter(Mandatory=$true)]
		[string]$UPN
	)
	$exists = Get-MSOLUser -UserPrincipalName $UPN -ErrorAction Stop
	if ($exists) {
		try {
			if (!($exists.StrongAuthenticationMethods.MethodType)) {
				$methods = "None registered"
			} else {
				$methods = $exists.StrongAuthenticationMethods.MethodType
				$default = ($exists.StrongAuthenticationMethods | ? {$_.IsDefault -eq "True"}).MethodType
			}
			$details = $exists | Select -ExpandProperty StrongAuthenticationUserDetails
			$hash = [ordered]@{
				User = $UPN
				Default = $default
				Phone = $details.PhoneNumber
				AltPhone = $details.AlternativePhoneNumber
				Methods = $methods

			}
			$MFAMethods = New-Object -TypeName PSObject -Property $hash
			return $MFAMethods
		} catch {
			return "Could not retrieve MFA status for user $($UPN), error was:`n$($_.Exception.Message)"
		}
	} else {
		return "Could not retrieve MFA status for user $($UPN), error was:`n$($_.Exception.Message)"
	}
	Remove-variable -name exists,methods,default,details,hash,mfamethods -force -Erroraction silentlycontinue
}

# UI created with native .NET methods
Function Native-GUI {
	Add-Type -assembly System.Windows.Forms
	$form = New-Object System.Windows.Forms.Form

	# Set the properties for the main program window 
	$form.Autosize=$true
	# If desired, hard-coded windows size can be set as well
	# $form.Height = 300
	# $form.Width = 309
	$form.BackColor = "White"
	$buttonwidth = $($form.Size.Width)/3 - 20

	# Create the program name displayed within the window
	$proglabel = New-Object System.Windows.Forms.Label
	$proglabel.text = "MFA Lookup Tool"
	$proglabel.autosize = $true
	$startingpoint = ($form.Width/2)-($proglabel.Width/2)
	$proglabel.location = New-Object System.Drawing.Point($startingpoint,0)
	$form.Controls.Add($proglabel)

	## Row 1 - layout done
	
	# Label 1 - Text label
	$Label1 = New-Object System.Windows.Forms.Label
	$Label1.text = "Status:"
	$Label1.location = New-Object System.Drawing.Point(10,20)
	$Label1.TextAlign = "MiddleLeft"
	$Label1.Size = New-Object System.drawing.Size($buttonwidth,18)
	$form.Controls.Add($Label1)

	# Label 2 - Connection status display
	$Label2 = New-Object System.Windows.Forms.Label
	$Label2.Location = New-Object System.Drawing.Point(($($form.width/3)+13),20)
	$Label2.Size = New-Object System.Drawing.Size(($buttonwidth),18)
	$Label2.Text = "Disconnected"
	$Label2.Forecolor = "Red"
	$form.Controls.Add($Label2)


	# Button 1 - Connect or disconnect MSOnline module
	$button1 = New-Object System.Windows.Forms.Button
	$button1.Location = New-object System.Drawing.Point($((($form.width/3)*2)+10),20)
	$button1.Size = New-Object System.drawing.Size($buttonwidth,18)
	$button1.Text = "Connect"
	$button1.textAlign = "MiddleCenter"
	$button1.BackColor = "LightGray"
	$button1.Add_Click(
		{
            if (!($global:connected)) {
                # If not connected, start a connection and update buttons & labels accordingly
			    try {
				    Connect-MsolService;
				    $button2.Enabled = $true
				    $label6.Text = "Connected succesfully"
				    $Label2.Text = "Connected"
            	    $Label2.Forecolor = "Green"
            	    $button1.Text="Disconnect"
					[boolean]$global:connected = $true
			    } catch {
				    $label6.Text = "Unable to connect, error message was:`n$($_.Exception.Message)"
			    }
            } else {
                # If connected, disconnect and update buttons & labels
                try {
                    [Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
				    $button2.Enabled = $false
				    $label6.Text = "Disconnected succesfully"
				    $Label2.Text = "Disconnected"
            	    $Label2.Forecolor = "Red"
            	    $button1.Text="Connect"
					[boolean]$global:connected = $false
                } catch {
				    $label6.Text = "Error when disconnecting, error message was:`n$($_.Exception.Message)"
                }
            }
		}
	)
	$form.Controls.Add($button1)

	## Row 2 - Search for user

	# Label 3 - Textbox2 label
	$Label3 = New-Object System.Windows.Forms.Label
	$Label3.text = "Username:"
	$Label3.location = New-Object System.Drawing.Point(10,40)
	$Label3.TextAlign = "MiddleLeft"
	$Label3.Size = New-Object System.drawing.Size($buttonwidth,18)
	$form.Controls.Add($Label3)
	
	# Textbox 1 - for username entry
	$textBox1 = New-Object System.Windows.Forms.TextBox
	$textBox1.Location = New-Object System.Drawing.Point(($($form.width/3)+10),40)
	$textBox1.Size = New-Object System.Drawing.Size(($buttonwidth),18)
	$textBox1.Text = ""
	$form.Controls.Add($textBox1)
	
	# Button 2 - for submitting search
	$button2 = New-Object System.Windows.Forms.Button
	$button2.Location = New-object System.Drawing.Point($((($form.width/3)*2)+4),40)
	$button2.Size = New-Object System.drawing.Size($buttonwidth,18)
	$button2.Text = "Go"
	$button2.textAlign = "MiddleCenter"
	$button2.BackColor = "LightGray"
	$button2.Enabled = $false
	$button2.Add_Click(
		{
			try {
				$global:success = $false
				[string]$UPN = $($textBox1.Text)
				Get-MsolUser -UserPrincipalName $UPN -ErrorAction Stop
			    $label6.Text = "Found user $($textBox1.Text)."
				$global:success = $true
			} catch {
			    $label6.Text = "User with name $($textBox1.Text) could not be found!"
			}
			if ($global:success) {
				$check = Check-AzureMFA -UPN $UPN
				if ((($check.GetType()).Name) -match "PSCustomObject") {
					if ($check.State -eq "Disabled") {
						$button3.Enabled = $true
						$label5.Text = "Disabled"
						$label5.Forecolor = "Red"
					} elseif ($check.State -eq "Enforced") {
						$button4.Enabled = $true;
						$button5.Enabled = $true
						$label5.Text = "Enforced"
						$label5.Forecolor = "Green"
					} else {
						$button4.Enabled = $true;
						$button5.Enabled = $true
						$label5.Text = $check.State
						$label5.Forecolor = "Orange"
					}
					$label6.Text = "MFA status for user $($textBox1.Text) retrieved."
				} else {
					$label6.Text = "MFA status for user $($textBox1.Text) could not be retrieved."
				}
			}
			Remove-Variable -name check -Force -ErrorAction SilentlyContinue
		}
	)
	$form.Controls.Add($button2)
	
	## Row 3 - Show MFA status for user
	
	# Label 4 - Text label 
	$Label4 = New-Object System.Windows.Forms.Label
	$Label4.text = "MFA Status:"
	$Label4.location = New-Object System.Drawing.Point(10,60)
	$Label4.TextAlign = "MiddleLeft"
	$Label4.Size = New-Object System.drawing.Size($buttonwidth,18)
	$form.Controls.Add($Label4)

	# Label 5 - Shows MFA Status
	$Label5 = New-Object System.Windows.Forms.Label
	$Label5.text = ""
	$Label5.location = New-Object System.Drawing.Point($((($form.width/3)*2)+4),60)
	$Label5.TextAlign = "MiddleLeft"
	$Label5.Size = New-Object System.drawing.Size($buttonwidth,18)
	$form.Controls.Add($Label5)	
	
	## Row 4 - Buttons for managing MFA status

	# Button 3 - Enable MFA if disabled
	$button3 = New-Object System.Windows.Forms.Button
	$button3.Location = New-object System.Drawing.Point(10,80)
	$button3.Size = New-Object System.drawing.Size($buttonwidth,18)
	$button3.Text = "Enable"
	$button3.textAlign = "MiddleCenter"
	$button3.BackColor = "LightGray"
	$button3.Enabled = $false
	if (!$global:connected) {
		$button3.Enabled = $false
	}	
	$button3.Add_Click(
		{
			try {
				$global:success = $false
				Enable-AzureMFA -UPN $($textBox1.Text)
				if ($global:success) {
					$label6.Text = "Request to enable MFA for $($textBox1.Text) submitted successfully. Re-checking MFA status..."
					$check = Check-AzureMFA  -UPN $($textBox1.Text)
					if ($check.State -eq "Disabled") {
						$button3.Enabled = $true
						$label5.Text = "Disabled"
						$label5.Forecolor = "Red"
					} elseif ($check.State -eq "Enforced") {
						$button4.Enabled = $true;
						$button5.Enabled = $true
						$label5.Text = "Enforced"
						$label5.Forecolor = "Green"
					} else {
						$button4.Enabled = $true;
						$button5.Enabled = $true
						$label5.Text = $check.State
						$label5.Forecolor = "Orange"
					}
					$label6.Text = "Request to enable MFA for $($textBox1.Text) was successful."
				} else {
					$label6.Text = "Request to enable MFA for $($textBox1.Text) was unsuccessful."
				}
			} catch {
				$label6.Text = "An error occurred when enabling MFA for $($textBox1.Text), message was:`n$($_.Exception.Message)"				
			}
		}
	)
	$form.Controls.Add($button3)

	# Button 4 - Disable MFA if enabled
	$button4 = New-Object System.Windows.Forms.Button
	$button4.Location = New-object System.Drawing.Point($(($form.width/3)+10),80)
	$button4.Size = New-Object System.drawing.Size($buttonwidth,18)
	$button4.Text = "Disable"
	$button4.textAlign = "MiddleCenter"
	$button4.BackColor = "LightGray"
	$button4.Enabled = $false
	$button4.Add_Click(
		{
			try {
				$global:success = $false
				Disable-AzureMFA -UPN $($textBox1.Text)
				if ($global:success) {
					$label6.Text = "Request to disable MFA for $($textBox1.Text) submitted successfully. Re-checking MFA status..."
					$check = Check-AzureMFA  -UPN $($textBox1.Text)
					if ($check.State -eq "Disabled") {
						$button3.Enabled = $true
						$label5.Text = "Disabled"
						$label5.Forecolor = "Red"
					} elseif ($check.State -eq "Enforced") {
						$button4.Enabled = $true;
						$button5.Enabled = $true
						$label5.Text = "Enforced"
						$label5.Forecolor = "Green"
					} else {
						$button4.Enabled = $true;
						$button5.Enabled = $true
						$label5.Text = $check.State
						$label5.Forecolor = "Orange"
					}
					$label6.Text = "Request to disable MFA for $($textBox1.Text) was successful."
				} else {
					$label6.Text = "Request to disable MFA for $($textBox1.Text) was unsuccessful."
				}
			} catch {
					$label6.Text = "An error occurred when enabling MFA for $($textBox1.Text), message was:`n$($_.Exception.Message)"				
			}
		}
	)
	$form.Controls.Add($button4)
	
    
	# Button 5 - Show MFA methods
	$button5 = New-Object System.Windows.Forms.Button
	$button5.Location = New-object System.Drawing.Point($((($form.width/3)*2)+4),80)
	$button5.Size = New-Object System.drawing.Size($buttonwidth,18)
	$button5.Text = "List"
	$button5.textAlign = "MiddleCenter"
	$button5.BackColor = "LightGray"
	$button5.Enabled = $false
	$button5.Add_Click(
		{
			try {
				$methods = Show-AzureMFA -UPN $($textBox1.Text)
				$label6.Text = "User:    $($methods.User)`nDefault method:    $($methods.Default)`nPhone number:    $($methods.Phone)"
				if ($method.AltPhone) {
					$label6.Text = "$($label6.Text)`nAlt phone number:    $($methods.AltPhone)`n`nMFA methods:"
				} else {
					$label6.Text = "$($label6.Text)`nAlt phone number:    None`n`nMFA methods:"	
				}
				foreach ($method in $methods.methods) {
					$label6.Text = "$($label6.Text)`n    $($method)"
				}
			} catch {
				$label6.Text = "An error occurred when retrieving MFA methods for $($textBox1.Text), message was:`n$($_.Exception.Message)"
			}
		}
	)
	$form.Controls.Add($button5)
	
	## Row 5 - Output label

	# Label 6 - Output label
	$Label6 = New-Object System.Windows.Forms.Label
	$Label6.text= ""
	$Label6.location = New-Object System.Drawing.Point(10,100)
	$Label6.TextAlign = "MiddleLeft"
	$Label6.autosize = $true
	$form.Controls.Add($Label6)

	## Row 6 - Quit

	# Button 6 - Quit
	$button6 = New-Object System.Windows.Forms.Button
	$button6.Location = New-object System.Drawing.Point($((($form.width/3)*2)+4),230)
	$button6.Size = New-Object System.drawing.Size($buttonwidth,18)
	$button6.Text = "Quit"
	$button6.textAlign = "MiddleCenter"
	$button6.BackColor = "LightGray"
	$button6.Add_Click(
		{
			$form.close()
		}
	)
	$form.Controls.Add($button6)

	# Display the form.
	$form.ShowDialog()
}

Native-GUI