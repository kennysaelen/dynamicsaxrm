<#
#
.SYNOPSIS
   Handles actions that can be performed related to the Enterprise Portal
.DESCRIPTION
   This script will call the RDAXManagement module to execute the AXUpdatePortal command
.PARAMETER $Action
   Action to perform
#>

#region Parameters

param
(
    [string]$Action = $(throw "Action must be provided."),

    [Parameter(	Mandatory	     = $true,
			    ParameterSetName = "UpdateaAll")]
    [string]$WebsiteURL
)

#endregion Parameters

Try
{
	$exitCode = 0

	# Determine the working directory of the deploy agent
	$InvocationDir 		= Split-Path $MyInvocation.MyCommand.Path

	# Load the RD Dynamics AX Management PowerShell module
	$AXModuleFileName 	= [string]::Format("{0}\RDAXManagement.psd1", $InvocationDir);
	Import-Module -Name $AXModuleFileName

	if ($Action -eq "UpdateAll")
	{
		Publish-Portal $Action $WebsiteURL
	}

	if($Error.Count -gt 0)
	{
		$exitCode = 1
	}
}
Catch [system.exception]
{
	$ErrorMessage = $_.Exception.Message + "`n"

	for ($i=0; $i -lt $error.Count; $i++) 
    {
	    $ErrorMessage = $ErrorMessage + "`nFully qualified error $i : " + $error[$i].FullyQualifiedErrorId
    }
    
	"`nError : RM Dynamics AX Enterprise Portal deployment failed. `nException message: $ErrorMessage"

	$ExitCode = 1
}

exit $exitCode