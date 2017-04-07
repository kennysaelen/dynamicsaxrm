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

param
(
    [string]$Action = $(throw "Action must be provided."),

    [Parameter(	Mandatory	= $true)]
    [string]$AxClientConfigName = $(throw "The client configuration file name must be provided."),

    [Parameter(	Mandatory	= $true)]
    [int]$TimeOut = $(throw "The timeout must be specified when calling the compilation manager"),

	[Parameter(	Mandatory	= $false)]
	[string]$ClientExecutablePath
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

	if ($Action -eq "axbuild")
	{
		Start-Build -configFile $AxClientConfigName -TimeOut $TimeOut
	}
	elseif ($Action -eq "compile")
	{
		Start-Compile -configFile $AxClientConfigName -TimeOut $TimeOut
	}
	elseif($Action -eq "CILBuild")
	{
		Start-CILBuild -configFile $AxClientConfigName -TimeOut $TimeOut -ClientExecutablePath $ClientExecutablePath
	}
	elseif($Action -eq"preexit")
	{
		Start-PreExit -configFile $AxClientConfigName -TimeOut $Timeout
	}
	elseif($Action -eq"kernelcompile")
	{
		Start-KernelCompile -configFile $AxClientConfigName -TimeOut $Timeout
	}
	else
	{
		Throw "Unknown action specified to compile AX";
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
    
	"`nError : RM Dynamics AX action $Action failed. `nException message: $ErrorMessage"

	$ExitCode = 1
}

exit $exitCode