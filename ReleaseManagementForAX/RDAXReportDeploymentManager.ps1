<#
#
.SYNOPSIS
   Handles actions that can be done related to SSRS reports
.DESCRIPTION
   This script will call the RDAXManagement module to deploy the SSRS reports
.PARAMETER $Action
   Action to perform
#>

#region Parameters

param
(
    [string]$Action = $(throw "Action must be provided."),

    [Parameter(	Mandatory	     = $false,
			    ParameterSetName = "DeployReports")]
    [string]$Id,

    [Parameter(	Mandatory	     = $true,
			    ParameterSetName = "DeployReports")]
    [string[]]$ReportName        = {*},

    [Parameter( Mandatory        = $false,
                ParameterSetName = "DeployReports")]
    [DateTime]$ModifiedAfter     = [DateTime]::MinValue,

    [Parameter(	Mandatory	     = $false,
                ParameterSetName = "DeployReports")]
    [switch]$RestartReportServer,

	[Parameter(	Mandatory	     = $false,
                ParameterSetName = "DeployReports")]
	[string]$ServicesAOSName,

	[Parameter(	Mandatory	     = $false,
                ParameterSetName = "DeployReports")]
	[int]$ServicesAOSWSDLPort


)

#endregion Parameters

$exitCode = 0

Try
{
	# Determine the working directory of the deploy agent
	$InvocationDir 		= Split-Path $MyInvocation.MyCommand.Path

	# Load the RD Dynamics AX Management PowerShell module
	$AXModuleFileName 	= [string]::Format("{0}\RDAXManagement.psd1", $InvocationDir);
	Import-Module -Name $AXModuleFileName

	if ($Action -eq "DeployReports")
	{   
		Publish-Reports -Id $Id -ReportName $ReportName -ModifiedAfter $ModifiedAfter -RestartReportServer:$RestartReportServer.IsPresent -ServicesAOSName $ServicesAOSName -ServicesAOSWSDLPort $ServicesAOSWSDLPort
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
    
	"`nError : RM Dynamics AX SSRS Report Deployment failed. `nException message: $ErrorMessage"

	$ExitCode = 1
}

exit $exitCode