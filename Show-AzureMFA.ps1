Function Show-AzureMFA {
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
			if (!($exists.StrongAuthenticationMethods.MethodType)) {
				$methods="None registered"
			} else {
				$methods = $exists.StrongAuthenticationMethods.MethodType
				$default=($exists.StrongAuthenticationMethods | ? {$_.IsDefault -eq "True"}).MethodType
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
			Write-Error "Could not retrieve MFA status for user $($UPN), error was:`n$($_.Exception.Message)"
		}
	} else {
		Write-Output "Could not find user $($UPN) in Azure AD."
	}
	Remove-variable -name exists,methods,default,mfamethods -force -Erroraction silentlycontinue
}