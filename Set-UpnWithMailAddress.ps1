<#
Replace UserPrincipalName with Mail attribute

All envrionments perform differently. Please test this code before using it
in production.

THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT WARRANTY 
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR RESULTS FROM THE USE OF 
THIS CODE REMAINS WITH THE USER.

Author: Aaron Guilmette
		aaron.guilmette@microsoft.com
#>

<#
.SYNOPSIS
Replace UserPrincipalName with Mail attribute.

.DESCRIPTION
This script will replace the UPN of the target object with the value
in its mail attribute.  This can be useful if parity between the
User Principal Name and email address is necessary (such as single
sign-on scenarios with Office 365).

.EXAMPLE
.\Set-UpnWithMailAddress.ps1 -TargetUser testuser@contoso.com
Replace UPN with mail attribute for user testuser@contoso.com.

.EXAMPLE
.\Set-UpnWithMailAddress.ps1 -TargetUser *
Replace UPN with mail attribute for all users.

.EXAMPLE
.\Set-UpnWithMailAddress.ps1 -TargetUser * -SearchBase "OU=Test,DC=contoso,DC=com" -LogFile Log.txt
Replace UPN with mail attribute for all users in organizational unit Test 
and log results to log.txt

.EXAMPLE
.\Set-UpnWithMailAddress.ps1 -TargetUser * -OnlyMailboxes
Replace UPN with mail attribute for mailbox users only (exclude mail-
enabled users).

.PARAMETER Logfile
Specify logfile for operations.

.PARAMETER OnlyMailboxes
Ignore MailUser objects, based on msExchRecipientTypeDetails value. If
the environment has MailUsers, it may not be desirable to overwrite the
UserPrincipalName with the external mail attribute, since the external
mail address will most likely be for a domain not bound to the current
organization.

.PARAMETER SearchBase
Set the BaseDN for the search query.  Defaults to the DN of the current
domain.

.PARAMETER SearchScope
Set the search scope for Active Directory Operations.

.PARAMETER TargetUser
This parameter is used to identify the user or group of users on which 
the attributes will be updated. Can be a single UPN or a wildcard to
select all users in current domain.

.LINK
For an updated version of this script, check the Technet
Gallery at http://gallery.technet.microsoft.com/Set-Upn-With-Mail-Address-c4d0ee60
#>

Param(
	[Parameter(Mandatory=$false,HelpMessage="Enter UPN for single user or * for all users")]
		[string]$TargetUser = "*",
	[Parameter(Mandatory=$false,HelpMessage="Only Mailboxes")]
		[switch]$OnlyMailboxes,
	[Parameter(Mandatory=$false,HelpMessage="Active Directory Base DN")]
		[string]$SearchBase = (Get-ADDomain).DistinguishedName,
	[Parameter(Mandatory=$false,HelpMessage="Active Directory Search Scope")]
		[ValidateSet("Base","OneLevel","Subtree")]
		[string]$SearchScope = "Subtree",
	[Parameter(Mandatory=$false,HelpMessage="Log File")]
		[string]$LogFile
	)
If (!(Get-Module ActiveDirectory))
	{
	Import-Module ActiveDirectory
	}

# Start Logfile
If ($LogFile)
	{
	If (Test-Path $LogFile)
        {
        "Logfile already exists."
        }
    Else
        {
        $head = """" + "DistinguishedName" + """" + "," + """" + "UPNBefore" + """" + "," + """" + "MailBefore" + """" + "," + """" + "UPNAfter" + """" + "," + """" + "MailAfter" + """"
	    #$head = "UPNBefore,MailBefore,UPNAfter,MailAfter"
	    $head | Out-File $LogFile
        }
	}

If ($OnlyMailboxes)
	{
	Write-Host -ForegroundColor Green "Processing mailbox objects."
	[array]$Users = Get-ADUser -LDAPFilter "(userPrincipalName=$($TargetUser))" -SearchBase $SearchBase -SearchScope $SearchScope -Properties userPrincipalName,mail,msExchRecipientTypeDetails | ? { $_.msExchRecipientTypeDetails -eq "1" }
	Write-Host -ForegroundColor Green "     $($Users.Count) objects in scope."
	ForEach ($User in $Users) 
		{
		$objBefore = Get-ADObject -Identity $User.DistinguishedName -Properties UserPrincipalName,Mail
		If ($objBefore.Mail)
			{
			Set-ADObject -Identity $User.DistinguishedName -Replace @{userPrincipalName=$($User.mail)}
			$objAfter = Get-ADObject -Identity $User.DistinguishedName -Properties UserPrincipalName,Mail
			If ($LogFile)
				{
				$LogData = """" + $objBefore.DistinguishedName + """" + "," + """" + $objBefore.UserPrincipalName + """" + "," + """" + $objBefore.Mail + """" + "," + """" + $objAfter.UserPrincipalName + """" + "," + """" + $objAfter.Mail + """"
				$LogData | Out-File $LogFile -Append
				}
			}
		Else 
			{ 
			Write-Host -NoNewline "User ";Write-Host -NoNewLine -ForegroundColor Red "$($objBefore.UserPrincipalName) "; Write-Host "does not have a valid mail attribute."
			$data = """" + $objBefore.UserPrincipalName + """" + "," + """" + "Missing or corrupt mail attribute." + """"
			$data | Out-File Errorlog.txt -Append
			}
		$objBefore = $null
		$objAfter = $null
		$LogData = $null
		}
	}
Else
	{
	Write-Host -ForegroundColor Green "Processing all object types."
	[array]$Users = Get-ADUser -LDAPFilter "(userPrincipalName=$($TargetUser))" -SearchBase $SearchBase -SearchScope $SearchScope -Properties userPrincipalName,mail
	Write-Host -ForegroundColor Green "     $($Users.Count) objects in scope."
	ForEach ($User in $Users) 
		{
		$objBefore = Get-ADObject -Identity $User.DistinguishedName -Properties UserPrincipalName,Mail
		If ($objBefore.Mail)
			{
			Set-ADObject -Identity $User.DistinguishedName -Replace @{userPrincipalName=$($User.mail)}
			$objAfter = Get-ADObject -Identity $User.DistinguishedName -Properties UserPrincipalName,Mail
			If ($LogFile)
				{
				$LogData = """" + $objBefore.DistinguishedName + """" + "," + """" + $objBefore.UserPrincipalName + """" + "," + """" + $objBefore.Mail + """" + "," + """" + $objAfter.UserPrincipalName + """" + "," + """" + $objAfter.Mail + """"
				$LogData | Out-File $LogFile -Append
				}
			}
		Else 
			{ 
			Write-Host -NoNewline "User ";Write-Host -NoNewLine -ForegroundColor Red "$($objBefore.UserPrincipalName) "; Write-Host "does not have a valid mail attribute."
			$data = """" + $objBefore.UserPrincipalName + """" + "," + """" + "Missing or corrupt mail attribute." + """"
			$data | Out-File Errorlog.txt -Append
			}
		$objBefore = $null
		$objAfter = $null
		$LogData = $null
		}
	}