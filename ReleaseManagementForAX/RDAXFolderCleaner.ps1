<#
.SYNOPSIS
	Cleans up the Ax artifacts
.DESCRIPTION
	This script will delete cache files, xppil files, label caches, ... from the Ax folders
.PARAMETER AxClientConfigName
	The client configuration to load client side folder metadata
.PARAMETER AxServerConfigName
	The server configuration to load server side folder metadata
#>

param
(
    [string]$AxClientConfigName = $(throw "The client configuration file name must be provided."),
    [string]$AxServerConfigName = $(throw "The server configuration file name must be provided.")
)

# This makes sure that ReleaseManagement also fails the step instead of continuing execution
$ErrorActionPreference = "Stop"

cls

$ExitCode = 0

Try
{
	# Determine the working directory of the deploy agent
	$InvocationDir 		= Split-Path $MyInvocation.MyCommand.Path

	# Load the Dynamics AX Management PowerShell module
	$AXModuleFileName 	= [string]::Format("{0}\RDAXManagement.psd1", $InvocationDir);
	Import-Module -Name $AXModuleFileName

	# Call the cleanup routine
	Clear-AXArtifactFolders -clientConfigName $AxClientConfigName -serverConfigName $AxServerConfigName

	"`nCleaning of artifacts finished."
}
Catch [system.exception]
{
	$ErrorMessage = $_.Exception.Message + "`n"

	for ($i=0; $i -lt $error.Count; $i++) 
    {
	    $ErrorMessage = $ErrorMessage + "`nFully qualified error $i : " + $error[$i].FullyQualifiedErrorId
    }
    
	"`nError : RM Cleaning of folders failed. `nException message: $ErrorMessage"

	$ExitCode = 1
}

exit $ExitCode