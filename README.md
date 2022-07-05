# Azure-MFA-tools
A collection of tools for managing the status of Azure MFA for individual users.

I created these scripts to enable me to quickly check and modify certain aspects of per-user [Azure MFA enrolment](https://docs.microsoft.com/en-us/azure/active-directory/authentication/howto-mfa-userstates), after growing frustrated at the number of blades required to perform the same actions via the Azure Portal. These scripts currently use the [MSOnline module](https://docs.microsoft.com/en-us/powershell/azure/active-directory/overview?view=azureadps-1.0&preserve_view=true), though I will migrate them to the Graph API in due course.

I have also created a script implementing most of these functions within a Windows Forms GUI.

For ease of use I prefer to pre-load these functions in my PowerShell profile and assign them aliases (e.g. "mfaon" for Enable-AzureMFA), but this is not required.

## Usage

### Enable-AzureMFA -UPN $UPN
This will retrieve the user account and set the State for StrongAuthenticationRequirements to "Enabled".

### Disable-AzureMFA -UPN $UPN
This will retrieve the user account and set the state for StrongAuthenticationRequirements to "Disabled".

### Check-AzureMFA -UPN $UPN
This will retrieve the user account and report the current value of StrongAuthenticationRequirements.

### Show-AzureMFA -UPN $UPN
This will retrieve the user account and return a summary of the account MFA status, including:
 * Default MFA method
 * Primary phone number
 * Alternative phone number
 * All available MFA methods

### Rereg-AzureMFA -UPN $UPN
This will reset the StrongAuthenticationMethods for the account to null. This will allow the user to re-enrol for MFA.

### MFATool
This implements most of the above functions within a Windows Forms GUI for ease of use by support staff.