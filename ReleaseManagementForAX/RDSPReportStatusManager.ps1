<#
#
.SYNOPSIS
   Handles actions that can be done with the various types of compilations
.DESCRIPTION
   This script will provide all the actions that can be done by using the CodeCrib.AX.AXBuild dll
.PARAMETER $Action
   Action to perform
#>

#region Parameters

Param(
            [Parameter(	Mandatory = $true)]
			[string]$SiteURL,
			[Parameter(	Mandatory = $true)]
			[string]$DocumentListName,
			[Parameter(	Mandatory = $true)]
			[string]$DocumentListUrl,
			[Parameter(	Mandatory = $true)]
			[string]$DocumentTitle,
			[Parameter(	Mandatory = $true)]
			[string]$Status
		)

#endregion Parameters

$exitCode = 0

try
{
	# Determine the working directory of the deploy agent
	$InvocationDir 		= Split-Path $MyInvocation.MyCommand.Path

	# Load the RD Dynamics AX Management PowerShell module
	$AXModuleFileName 	= [string]::Format("{0}\RDAXManagement.psd1", $InvocationDir);
	Import-Module -Name $AXModuleFileName

	Start-ReportStatus -SiteUrl  $SiteUrl -DocumentListName $DocumentListName -DocumentListUrl $DocumentListUrl -DocumentTitle $DocumentTitle -Status $Status

	if($Error.Count -gt 0)
	{
		$exitCode = 1
	}
}
Catch [system.exception]
{
	$ErrorMessage = $_.Exception.Message
	
	"Error : RM Dynamics AX Build failed. Exception message: $ErrorMessage"	
	
	$ExitCode = 1
}

exit $exitCode