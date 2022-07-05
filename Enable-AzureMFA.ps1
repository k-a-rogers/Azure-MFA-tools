Function Enable-AzureMFA {
	param(
        [parameter(Mandatory=$true)]
		[string]$UPN
	)
	# Check if module loaded
	if (!(Get-Module msonline)) {
		import-module msonline
	}
	# Check if connected
	try {
		Get-MSOLDomain -ErrorAction Stop | Out-Null
	} catch {
		Write-Output "Connecting to Azure AD..."
		Connect-MsolService
	}
	$st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement -Property @{
		State = "Enabled";
		RelyingParty = "*";
	}
	$exists=Get-MsolUser -userprincipalname $UPN -ErrorAction silentlycontinue
	if ($exists) {
		try {
			Set-MsolUser -UserPrincipalName $UPN -StrongAuthenticationRequirements $st -Erroraction Stop
			Write-Output "Attempt to enable MFA complete, checking MFA status now..."
			Check-AzureMFA -UPN $UPN
		} catch {
			Write-Output "MFA could not be enabled for $($UPN), error was:`n$($_.Exception.Message)"
		}
	} else {
		Write-Output "Could not find user $($UPN) in Azure AD."
	}
	Remove-variable -name exists,mfastatus -force -Erroraction silentlycontinue
}