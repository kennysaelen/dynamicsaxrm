<#
.SYNOPSIS
   Calls the Dynamics AX Database actions
.DESCRIPTION
   This script will load the RDAXManagement module containing the library of functions for Dynamics AX 2012.
   Using the module, stuff like a Database Sync can be done
.PARAMETER <paramName>
   <Description of script parameter>
#>

#region Parameters

param
(
    [string]$Action = $(throw "The action must be provided."),

    [Parameter(	Position	= 0,
                Mandatory	= $true,
			    ParameterSetName = "sync")]
    [string]$AxClientConfigName = $(throw "The client configuration file name must be provided."),

    [Parameter(	Position	= 1,
                Mandatory	= $true,
			    ParameterSetName = "sync")]
    [int]$TimeOut = $(throw "The timeout must be specified when calling the compilation manager")
)

#endregion Parameters

try
{
	$exitCode = 0

	# Determine the working directory of the deploy agent
	$InvocationDir 		= Split-Path $MyInvocation.MyCommand.Path

	# Load the RD Dynamics AX Management PowerShell module
	$AXModuleFileName 	= [string]::Format("{0}\RDAXManagement.psd1", $InvocationDir);
	Import-Module -Name $AXModuleFileName

	if ($Action -eq "sync")
	{
		Start-DBSync -ConfigurationFile $AxClientConfigName -TimeOut $TimeOut
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
    
	"`nError : RM Dynamics AX Database Synchronization failed. `nException message: $ErrorMessage"

	$ExitCode = 1
}

exit $exitCode