<#
.SYNOPSIS
   Handles actions that can be done with the AX Model Store database
.DESCRIPTION
   This script will provide all the actions that can be done by using the AXUtil library (Export / Import models, Export / Import Model Store, ...)
.PARAMETER $Action
   Action to perform against the model store
#>

#region Parameters

param
(
    [string]$Action = $(throw "Action must be provided."),

    [Parameter(	Position	= 0, 
                Mandatory	= $false,
				ParameterSetName = "ExportModel")]
    [Parameter( Position	= 0, 
                Mandatory	= $false,
				ParameterSetName = "ExportModelStore")]
    [Parameter( Position	= 0, 
                Mandatory	= $false,
				ParameterSetName = "ImportModelStore")]
    [Parameter( Position	= 0, 
                Mandatory	= $false,
				ParameterSetName = "InstallModel")]
	[Parameter( Position	= 0, 
                Mandatory	= $false,
				ParameterSetName = "UninstallModel")]
	[Parameter( Position	= 0, 
                Mandatory	= $false,
				ParameterSetName = "OptimizeModelStore")]
	[Parameter( Position	= 0, 
                Mandatory	= $false,
				ParameterSetName = "EditModelManifest")]
	[Parameter( Position	= 0, 
                Mandatory	= $false,
				ParameterSetName = "GrantModelStore")]
	[Parameter( Position	= 0, 
                Mandatory	= $false,
				ParameterSetName = "SetModelStore")]
    [string]$server = $null
    ,
    ###################################################################
    [Parameter(	Position	= 1, 
                Mandatory	= $false,
                ParameterSetName = "ExportModel")]
    [Parameter( Position	= 1, 
                Mandatory	= $false,
				ParameterSetName = "ExportModelStore")]
    [Parameter( Position	= 1, 
                Mandatory	= $false,
				ParameterSetName = "ImportModelStore")]
    [Parameter( Position	= 1, 
                Mandatory	= $false,
				ParameterSetName = "InstallModel")]
	[Parameter( Position	= 1, 
                Mandatory	= $false,
				ParameterSetName = "UninstallModel")]
	[Parameter( Position	= 1, 
                Mandatory	= $false,
				ParameterSetName = "OptimizeModelStore")]
	[Parameter( Position	= 1, 
                Mandatory	= $false,
				ParameterSetName = "EditModelManifest")]
	[Parameter( Position	= 1, 
                Mandatory	= $false,
				ParameterSetName = "GrantModelStore")]
	[Parameter( Position	= 1, 
                Mandatory	= $false,
				ParameterSetName = "SetModelStore")]
    [string]$database = $null
    ,
	###################################################################
    [Parameter(	Position	= 2, 
                Mandatory	= $false,
				ParameterSetName = "ExportModel")]
    [Parameter( Position	= 2, 
                Mandatory	= $false,
				ParameterSetName = "ExportModelStore")]
    [Parameter( Position	= 2, 
                Mandatory	= $false,
				ParameterSetName = "ImportModelStore")]
    [Parameter( Position	= 2, 
                Mandatory	= $false,
				ParameterSetName = "InstallModel")]
	[Parameter( Position	= 2, 
                Mandatory	= $false,
				ParameterSetName = "UninstallModel")]
	[Parameter( Position	= 2, 
                Mandatory	= $false,
				ParameterSetName = "OptimizeModelStore")]
	[Parameter( Position	= 2, 
                Mandatory	= $false,
				ParameterSetName = "EditModelManifest")]
	[Parameter( Position	= 2, 
                Mandatory	= $false,
				ParameterSetName = "GrantModelStore")]
	[Parameter( Position	= 2, 
                Mandatory	= $false,
				ParameterSetName = "SetModelStore")]
    [string]$config = $null
    ,
	###################################################################
    [Parameter(	Position	= 3, 
                Mandatory	= $true,
				ParameterSetName = "ExportModel")]
	[Parameter(	Position	= 3, 
                Mandatory	= $true,
				ParameterSetName = "ExportModelStore")]
    [Parameter( Position	= 3, 
                Mandatory	= $false,
				ParameterSetName = "ImportModelStore")]
	[Parameter(	Position	= 3, 
                Mandatory	= $true,
				ParameterSetName = "InstallModel")]
    [string]$file
    ,
	###################################################################
    [Parameter(	Position	= 4, 
                Mandatory	= $true,
                ParameterSetName = "ExportModel")]
	[Parameter( Position	= 3, 
                Mandatory	= $true,
				ParameterSetName = "UninstallModel")]
	[Parameter( Position	= 3, 
                Mandatory	= $true,
                ParameterSetName = "EditModelManifest")]
    [string]$model
    ,
	###################################################################
    [Parameter(	Position	= 5, 
                Mandatory	= $false,
                ParameterSetName = "ExportModel")]
	[Parameter( Position	= 4, 
                Mandatory	= $false,
                ParameterSetName = "UninstallModel")]
	[Parameter( Position	= 4, 
                Mandatory	= $false,
                ParameterSetName = "EditModelManifest")]
    [string]$manifestFile = $null
    ,
	###################################################################
	[Parameter( Position	= 5, 
                Mandatory	= $false,
                ParameterSetName = "EditModelManifest")]
    [string]$manifestProperty = $null
	,
	###################################################################
    [Parameter(	Position	= 6, 
                Mandatory	= $false,
                ParameterSetName = "ExportModel")]
    [string]$key = $null
    ,
    ###################################################################
    [Parameter(	Position	= 4, 
                Mandatory	= $true,
                ParameterSetName = "InstallModel")]
    [string]$conflict = $null
    ,
	###################################################################
    [Parameter(	Position	= 5, 
                Mandatory	= $false,
                ParameterSetName = "InstallModel")]
    [string]$replace = $null
    ,
	###################################################################
    [Parameter(	Position	= 6, 
                Mandatory	= $false)]
    [Parameter(ParameterSetName = "InstallModel")]
    [switch]$createParents
    ,
	###################################################################
    [Parameter(	Position	= 4, 
                Mandatory	= $false,
				ParameterSetName = "ExportModelStore")]
    [Parameter( Position	= 7, 
                Mandatory	= $false,
				ParameterSetName = "InstallModel")]
	[Parameter( Position	= 5, 
                Mandatory	= $false,
				ParameterSetName = "UninstallModel")]
    [switch]$details
    ,
	###################################################################
    [Parameter(	Position	= 8, 
                Mandatory	= $false,
				ParameterSetName = "InstallModel")]
    [switch]$noOptimize
    ,
	###################################################################
    [Parameter(	Position	= 9, 
                Mandatory	= $false,
				ParameterSetName = "UninstallModel")]
	[Parameter(	Position	= 9, 
                Mandatory	= $false,
				ParameterSetName = "InstallModel")]
    [Parameter( Mandatory   = $false,
                ParameterSetName = "ImportModelStore")]
    [switch]$noPrompt
    ,
	###################################################################
    [Parameter(	Position	= 10, 
                Mandatory	= $false,
                ParameterSetName = "InstallModel")]
    [string]$targetLayer = $null
	,
	###################################################################
	[Parameter(	Position	= 6, 
                Mandatory	= $false,
                ParameterSetName = "UninstallModel")]
    [string]$layer = $null
	,
	###################################################################
	[Parameter(	Position	= 3, 
                Mandatory	= $true,
                ParameterSetName = "GrantModelStore")]
    [string]$AOSAccount= $null
	,
	###################################################################
	[Parameter(	Position	= 4, 
                Mandatory	= $false,
                ParameterSetName = "GrantModelStore")]
    [Parameter( Mandatory   = $false,
                ParameterSetName = "ImportModelStore")]
    [string]$schemaName= $null
	,
	###################################################################
	# This is a workaround for the ParameterSetName because the Optimize Model Store uses only the 3 most basic parameters that all of the other function use.
	# So PowerShell cannot figure out the ParameterSetName without this dummy variable
	[Parameter(	Position	= 3, 
                Mandatory	= $true,
                ParameterSetName = "OptimizeModelStore")]
    [switch]$setOptimizeModelStoreDummy = $null
    ,
	###################################################################
	# This is a workaround for the ParameterSetName because the Edit model manifest has mutual exclusive mandatory parameters (manifestFile and manifestProperty).
	# So PowerShell cannot figure out the ParameterSetName without this dummy variable
	[Parameter(	Position	= 6, 
                Mandatory	= $true,
                ParameterSetName = "EditModelManifest")]
    [switch]$setEditModelManifestDummy = $null
    ,
	###################################################################
    [Parameter(	Mandatory	= $false)]
    [Parameter(ParameterSetName = "ExportModelStore")]
    [switch]$zip
    ,
   	###################################################################
    [Parameter(	Mandatory	= $false,
                ParameterSetName = "ImportModelStore")]
    [string]$apply = $null
    ,
    ###################################################################
    [Parameter( Mandatory   = $false,
                ParameterSetName = "ImportModelStore")]
    [string]$BackupSchema = $null            
    ,
    ###################################################################
    [Parameter( Mandatory   = $false,
                ParameterSetName = "ImportModelStore")]
    [string]$IdConflict = $null,
    ###################################################################
	[Parameter( Position	= 3, 
                Mandatory	= $false,
				ParameterSetName = "SetModelStore")]
    [switch]$InstallMode,
    
	[Parameter( Position	= 3, 
                Mandatory	= $false,
				ParameterSetName = "SetModelStore")]
    [switch]$NoInstallMode
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

	if ($Action -eq "exportModel")
	{
			# First wrap the arguments list for the Export-Model function
			$parms = @{ Server = $server
						Database = $database
						Config = $config
						File = $file
						Model = $model
						ManifestFile = $manifestFile
						Key = $key
						}

			# Call the export function in the RDAXManagement module
			Export-Model @parms
	}
	elseif($Action -eq "exportModelStore")
	{
		# First wrap the arguments list for the Export-ModelStore function
		$parms = @{ Server = $server
					Database = $database
					Config = $config
					File = $file
					}

		# Call the export function in the RDAXManagement module
		Export-ModelStore @parms -zip
	}
	elseif($Action -eq "importModelStore")
	{
		# First wrap the arguments list for the Export-ModelStore function
		$parms = @{ Server = $server
					Database = $database
					Config = $config
					File = $file
					Apply = $apply
					BackupSchema = $BackupSchema
					IdConflict = $IdConflict
					SchemaName = $schemaName
					NoPrompt = $noPrompt
					}

		# Call the export function in the RDAXManagement module
		Import-ModelStore @parms
	}

	elseif ($Action -eq "installModel")
	{
		# First wrap the arguments list for the Install-Model function
		$parms = @{ Server = $server
					Database = $database
					Config = $config
					File = $file
					Replace = $replace
					Conflict = $conflict
					TargetLayer = $targetLayer
					NoPrompt = $noPrompt
					CreateParents = $createParents
					Details = $details
					NoOptimize = $noOptimize
					}

		# Call the import function in the RDAXManagement module
		Install-Model @parms
	}
	elseif ($Action -eq "uninstallModel")
	{
		# First wrap the arguments list for the Uninstall-Model function
		$parms = @{ Server = $server
					Database = $database
					Config = $config
					Model = $model
					Layer = $layer
					ManifestFile = $manifestFile
					Details = $details
					NoPrompt = $noPrompt
					}

		# Call the uninstall function in the RDAXManagement module
		UnInstall-Model @parms
	}
	elseif ($Action -eq "optimizeModelStore")
	{
		$optimizeCommand = [string]::Format("{0}\n{1}", "Optimizing model store", $PSBoundParameters)
		Write-Host $optimizeCommand

		# First wrap the arguments list for the Optimize-ModelStore function
		$parms = @{ Server = $server
					Database = $database
					Config = $config }

		Optimize-ModelStore @parms
	}
	elseif ($Action -eq "editModelManifest")
	{
		if (-not $PSBoundParameters.ContainsKey('ManifestFile') -and -not $PSBoundParameters.ContainsKey('ManifestProperty'))
		{
			throw("Either the manifest file or a manifest property must be specified.")
		}

		# First wrap the arguments list for the Edit-ModelManifest function
		$parms = @{ Server = $server
					Database = $database
					Config = $config
					Model = $model
					ManifestFile = $manifestFile
					ManifestProperty = $manifestProperty }

		Edit-ModelManifest @parms
	}
	elseif ($Action -eq "grantModelStore")
	{
		# First wrap the arguments list for the Edit-ModelManifest function
		$parms = @{ Server = $server
					Database = $database
					Config = $config
					AOSAccount = $AOSAccount
					SchemaName = $schemaName }
	
		Grant-ModelStore @parms
	}
	elseif($Action -eq "setModelStore")
	{
		$setModelStoreCommand = [string]::Format("{0}\n{1}", "Set model store", $PSBoundParameters)
		Write-Host $setModelStoreCommand

		# First wrap the arguments list for the Optimize-ModelStore function
		$parms = @{ Server = $server
					Database = $database
					Config = $config
					InstallMode = $InstallMode
					NoInstallMode = $NoInstallMode }

		Set-ModelStore @parms    
	}
	else
	{
		Write-Error "Unknown action";
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