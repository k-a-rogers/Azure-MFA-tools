Function ReReg-AzureMFA {
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
	$p=@()
	$exists=Get-MsolUser -userprincipalname $UPN -ErrorAction silentlycontinue
	if ($exists) {
		Write-Output "Current MFA options for $($UPN):`n$($exists.StrongAuthenticationMethods)`n"
		try {
			Set-MsolUser -UserPrincipalName $UPN -StrongAuthenticationMethods $p -Erroraction Stop
			Write-Output "Attempt to require MFA re-registration complete, checking MFA status now..."
			Show-AzureMFA -UPN $UPN
		} catch {
			Write-Output "MFA could not be enabled for $($UPN), error was:`n$($_.Exception.Message)"
		}
	} else {
		Write-Output "Could not find user $($UPN) in Azure AD."
	}
	Remove-variable -name exists,p -force -Erroraction silentlycontinue
}