Function Check-AzureMFA {
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
			Write-Error "Could not retrieve MFA status for user $($UPN), error was:`n$($_.Exception.Message)"
		}
	}	
}