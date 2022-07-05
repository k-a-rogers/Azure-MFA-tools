Function Disable-AzureMFA {
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
	$exists=Get-MsolUser -userprincipalname $UPN -ErrorAction silentlycontinue
	if ($exists) {
		try {
			Set-MsolUser -UserPrincipalName $UPN -StrongAuthenticationRequirement @() -ErrorAction Stop
			Write-Output "Attempt to disable MFA complete, checking MFA status now..."
			Check-AzureMFA -UPN $UPN
		} catch {
			Write-Output "MFA could not be disabled for $($UPN), error was:`n$($_.Exception.Message)"
		}
	} else {
		Write-Output "Could not find user $($UPN) in Azure AD."
	}
	Remove-variable -name exists,mfastatus -force -Erroraction silentlycontinue
}