# FileName:  ps_ExtractGroups.ps1
#----------------------------------------------------------------------------
# Script Name: [Recursively expand AD Groups to document nested FullAccess principals]
# Created: [08/03/2017]
# Author: Rob Wolsky
# Company: NovaTech Group
# Email: rob.wolsky@ntekcloud.com
# Requirements: CSV file containing groups to expand by CN 
# Requirements: List relevant identities in c:\Temp\fullaccessgroups.csv (header GroupName)
# Requirements: 
# Keywords:
#-----------------------------------------------------------------------------
# Purpose: Investigation of Send-As permissions for Office 365 migration project
#-----------------------------------------------------------------------------
# REVISION HISTORY
#-----------------------------------------------------------------------------
# Date: [08/03/2017]
# Time: [1409]
# Issue: Update for IFF. 
# Solution:
#
#-----------------------------------------------------------------------------
# Script Body - Main script section
#-----------------------------------------------------------------------------

$groupnames = @()
#Populate Group Name Array
#[Array] $groupnames = Import-Csv C:\temp\FullAccessGroups.csv
[Array] $groupnames = Import-Csv C:\temp\SendAsGroups.csv

#Initialize array variable used to store records for output

$arrResults = @()

ForEach ($group in [Array] $groupnames)
{

#Process group name for AD member data, recursively drill down into nested groups to capture users
$found = Get-ADGroup -Identity $group.GroupName
trap { 'Group: '+$group.GroupName+' not found - NOT A GROUP'; continue }
Get-ADGroupMember $found -Recursive | Select Name | % {

    $objEX = New-Object -TypeName PSObject

    $objEX | Add-Member -MemberType NoteProperty -Name Mailbox -Value $group.GroupName

    $objEX | Add-Member -MemberType NoteProperty -Name User -Value $_.Name

    $arrResults += $objEX 

    } 
}

$arrResults | Out-GridView
#$arrResults | Export-Csv -Path 'C:\Temp\SENDAS_RESULT.csv' -NoTypeInformation 

#-----------------------------------------------------------------------------
# END OF SCRIPT: [Find Mailboxes with Send-As permissions]
#-----------------------------------------------------------------------------
#>