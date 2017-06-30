function Initialize-AxManagementTools
{
    $dynamicsSetupRegKey = Get-Item "HKLM:\SOFTWARE\Microsoft\Dynamics\6.0\Setup"
    $sourceDir = $dynamicsSetupRegKey.GetValue("InstallDir")
    $dynamicsAXUtilPath = join-path $sourceDir "ManagementUtilities"
    ."$dynamicsAXUtilPath\Microsoft.Dynamics.ManagementUtilities.ps1"
}

function Set-AxManagementToolsPath
{
    $dynamicsSetupRegKey = Get-Item "HKLM:\SOFTWARE\Microsoft\Dynamics\6.0\Setup"
    $sourceDir = $dynamicsSetupRegKey.GetValue("InstallDir")
    $dynamicsAXUtilPath = join-path $sourceDir "ManagementUtilities"
    Set-Location $dynamicsAXUtilPath 
}

function Clear-AXArtifactFolders
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position			= 0, 
						Mandatory			= $true)]
			[string]$clientConfigName
            ,
            [Parameter(	Position			= 1, 
						Mandatory			= $true)]
			[string]$serverConfigName		
		)

    # Read the client configration file
    $serverConfiguration = Get-ServerConfiguration -filename $serverConfigName
	$serverAltBinDir = $serverConfiguration.AlternateBinDirectory

	$LocalAppDataFolder = [Environment]::GetFolderPath('LocalApplicationData')
		
	$FolderPath = [string]::Format("{0}Application\Appl\Standard\*",$ServerAltBinDir)
	if(Test-Path $FolderPath)
	{
		Write-Host "Cleaning server label artifacts ($FolderPath)"
		Remove-Item -Path $FolderPath -Include ax*.al? -Recurse
	}
		
	$FolderPath = [string]::Format("{0}XppIL\*",$ServerAltBinDir)
	if(Test-Path $FolderPath)
	{
		Write-Host "Cleaning server XppIL artifacts ($FolderPath)"
		Remove-Item -Path $FolderPath -Include *.* -Recurse
	}
		
	$FolderPath = [string]::Format("{0}VSAssemblies\*",$ServerAltBinDir)
	if(Test-Path $FolderPath)
	{	
		Write-Host "Cleaning server VSAssemblies artifacts ($FolderPath)"
		Remove-Item -Path $FolderPath -Include *.* -Recurse
	}

	$FolderPath = [string]::Format("{0}\*", $LocalAppDataFolder)
	if(Test-Path $FolderPath)
	{
		Write-Host "Cleaning client cache artifacts ($FolderPath)"
		Get-ChildItem -Path $FolderPath -Include *.auc,*.kti -recurse | Remove-Item
	}

	$FolderPath = [string]::Format("{0}\Microsoft\Dynamics Ax\*", $LocalAppDataFolder)
	if(Test-Path $FolderPath)
	{
		Write-Host "Cleaning client VSAssemblies artifacts ($FolderPath)"
		Get-ChildItem -Path $FolderPath -Recurse | Remove-Item -force -Recurse -Filter "VSAssemblies"
	}
}

# Loads the AXUtil library and wraps the export model function
function Export-Model
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position	= 0, 
						Mandatory	= $true)]
			[string]$file
			,
            [Parameter(	Position	= 1, 
						Mandatory	= $true)]
			[string]$model
			,
			[Parameter(	Position	= 2, 
						Mandatory	= $false)]
			[string]$server = $null
            ,
            [Parameter(	Position	= 3, 
						Mandatory	= $false)]
			[string]$database = $null
			,
            [Parameter(	Position	= 4, 
						Mandatory	= $false)]
			[string]$manifestFile = $null
			,
            [Parameter(	Position	= 5, 
						Mandatory	= $false)]
			[string]$key = $null
			,
            [Parameter(	Position	= 6, 
						Mandatory	= $false)]
			[string]$config = $null
		)
	
	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

    Write-Debug ([String]::Format("PSBoundParameters : {0}", $PSBoundParameters))

    # Export the model
    Export-AXModel @PSBoundParameters
}

# Loads the AXUtil library and wraps the export modelStore function
function Export-ModelStore
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position	= 0, 
						Mandatory	= $true)]
			[string]$file
			,
			[Parameter(	Position	= 1, 
						Mandatory	= $false)]
			[string]$server = $null
            ,
            [Parameter(	Position	= 2, 
						Mandatory	= $false)]
			[string]$database = $null
			,
            [Parameter(	Position	= 3, 
						Mandatory	= $false)]
			[string]$config = $null
            ,
            [Parameter(	Position	= 4, 
                        Mandatory	= $false)]
            [switch]$zip
		)
	
	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

    Write-Debug ([String]::Format("PSBoundParameters : {0}", $PSBoundParameters))

    if($PSBoundParameters.ContainsKey("zip"))
    {
        $PSBoundParameters.Remove("zip");
    }

    if(Test-Path $file)
    {
        Remove-Item $file
    }

    # Export the model
    Export-AXModelStore @PSBoundParameters

    if($zip.IsPresent -eq $true)
    {
        $path = Split-Path -Path $file
        Write-ZipFile -file $file -target $path

        if(Test-Path $file)
        {
            Remove-Item $file
        }
    }
}

function Import-ModelStore
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position	= 0, 
						Mandatory	= $false)]
			[string]$file
			,
			[Parameter(	Position	= 1, 
						Mandatory	= $false)]
			[string]$server = $null
            ,
            [Parameter(	Position	= 2, 
						Mandatory	= $false)]
			[string]$database = $null
			,
            [Parameter(	Position	= 3, 
						Mandatory	= $false)]
			[string]$config = $null
            ,
            [Parameter(	Position	= 4, 
						Mandatory	= $false)]
			[string]$apply = $null
            ,
            [Parameter( Position = 5,
                        Mandatory = $false)]
            [string]$BackupSchema = $null
            ,
            [Parameter( Position  = 6,
                        Mandatory = $false)]
            [string]$IdConflict = $null
            ,
            [Parameter( Position  = 7,
                        Mandatory = $false)]
            [string]$SchemaName = $null
            ,
            [Parameter( Position  = 8,
                        Mandatory = $false)]
            [switch]$NoPrompt
		)

		# First load the cmdLets from the AXUtil library
		Initialize-AxManagementTools

        if($file -ne '')
        {
            if((Get-ChildItem $file).Extension -eq ".zip")
            {
                Open-ZipFile -file $file -target (Get-ChildItem $file).Directory
            }
        }

        $PSBPkeys = $PSBoundParameters.GetEnumerator()
		$keysToDelete = @()
		ForEach($PSBPkey in $PSBPkeys)
		{
			if([String]::IsNullOrEmpty($PSBPkey.Value))
			{
				$keysToDelete += $PSBPkey.Key
			}
    	}

		foreach($keyToDelete in $keysToDelete) 
		{
			$PSBoundParameters.Remove($keyToDelete)
		}
   	
        Import-AXModelStore @PSBoundParameters
}

# Optimizes the model store by re-indexing, shrinking the DB, ...
function Optimize-ModelStore
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position	= 0, 
						Mandatory	= $false)]
			[string]$server = $null
            ,
            [Parameter(	Position	= 1, 
						Mandatory	= $false)]
			[string]$database = $null
			,
            [Parameter(	Position	= 2, 
						Mandatory	= $false)]
			[string]$config = $null
		)

	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

    Write-Debug ([String]::Format("PSBoundParameters : {0}", $PSBoundParameters))

    # Optimize the model store
	Optimize-AXModelStore @PSBoundParameters
}

function Set-ModelStore
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position	= 0, 
						Mandatory	= $false)]
			[string]$server = $null
            ,
            [Parameter(	Position	= 1, 
						Mandatory	= $false)]
			[string]$database = $null
			,
            [Parameter(	Position	= 2, 
						Mandatory	= $false)]
			[string]$config = $null,

            [Parameter(	Position	= 3, 
						Mandatory	= $false)]
			[switch]$InstallMode,
            [Parameter(	Position	= 3, 
						Mandatory	= $false)]
			[switch]$NoInstallMode           
		)

	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

    # Optimize the model store
	Set-AXModelStore @PSBoundParameters
}

# Edit the model manifest XML file by either passing an XML file or specifying the properties to change
function Edit-ModelManifest
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position	= 0, 
						Mandatory	= $false)]
			[string]$server = $null
            ,
            [Parameter(	Position	= 1, 
						Mandatory	= $false)]
			[string]$database = $null
			,
            [Parameter(	Position	= 2, 
						Mandatory	= $false)]
			[string]$config = $null
			,
			[Parameter(	Position	= 3, 
						Mandatory	= $false)]
			[string]$model = $null
			,
			[Parameter(	Position	= 4, 
						Mandatory	= $false)]
			[string]$manifestFile = $null
			,
			[Parameter(	Position	= 5, 
						Mandatory	= $false)]
			[string]$manifestProperty = $null
		)

	if(($manifestFile -eq "") -and ($manifestProperty -eq ""))
	{
		throw("Either the manifest file or a manifest property must be specified.")
	}

	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

    # Optimize the model store
	Edit-AXModelManifest  @PSBoundParameters
}

function Install-Model
{
    Param(
            [Parameter(	Position	= 0, 
                        Mandatory	= $true)]
            [string]$file
            ,
            [Parameter(	Position	= 1, 
                        Mandatory	= $false)]
            [string]$server = $null
            ,
            [Parameter(	Position	= 2, 
                        Mandatory	= $false)]
            [string]$database = $null
            ,
            [Parameter(	Position	= 3, 
                        Mandatory	= $false)]
            [string]$config = $null
            ,
            [Parameter(	Position	= 4, 
                        Mandatory	= $true)]
            [string]$conflict = $null
            ,
            [Parameter(	Position	= 5, 
                        Mandatory	= $false)]
            [string]$replace = $null
            ,
            [Parameter(	Position	= 6, 
                        Mandatory	= $false)]
            [switch]$createParents
            ,
            [Parameter(	Position	= 7, 
                        Mandatory	= $false)]
            [switch]$details
            ,
            [Parameter(	Position	= 8, 
                        Mandatory	= $false)]
            [switch]$noOptimize
            ,
            [Parameter(	Position	= 9, 
                        Mandatory	= $false)]
            [switch]$noPrompt
            ,
            [Parameter(	Position	= 10, 
                        Mandatory	= $false)]
            [string]$targetLayer = $null
        )

	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

    # Export the model
    Install-AXModel @PSBoundParameters
}

function Uninstall-Model
{
	Param(
            [Parameter(	Position	= 0, 
                        Mandatory	= $false)]
            [string]$server = $null
            ,
            [Parameter(	Position	= 1, 
                        Mandatory	= $false)]
            [string]$database = $null
            ,
            [Parameter(	Position	= 2, 
                        Mandatory	= $false)]
            [string]$config = $null
            ,
			[Parameter(	Position	= 3, 
                        Mandatory	= $true)]
            [string]$model = $null
			,
            [Parameter(	Position	= 4, 
                        Mandatory	= $false)]
            [string]$layer = $null
			,
			[Parameter(	Position	= 5, 
                        Mandatory	= $false)]
            [string]$manifestFile = $null
			,
            [Parameter(	Position	= 6, 
                        Mandatory	= $false)]
            [switch]$details
            ,
            [Parameter(	Position	= 7, 
                        Mandatory	= $false)]
            [switch]$noPrompt
        )

	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

    # Export the model
    UnInstall-AXModel @PSBoundParameters
}

# Grants permission to the model store database for the AOS account
function Grant-ModelStore
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position	= 0, 
						Mandatory	= $false)]
			[string]$server = $null
            ,
            [Parameter(	Position	= 1, 
						Mandatory	= $false)]
			[string]$database = $null
			,
            [Parameter(	Position	= 2, 
						Mandatory	= $false)]
			[string]$config = $null
			,
            [Parameter(	Position	= 3, 
						Mandatory	= $true)]
			[string]$AOSAccount = $null
			,
            [Parameter(	Position	= 4, 
						Mandatory	= $false)]
			[string]$schemaName = $null
		)

	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

	Grant-AXModelStore @PSBoundParameters
}

function Write-ZipFile
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position			= 0, 
						Mandatory			= $true)]
			[string]$file
            ,
            [Parameter(	Position			= 1, 
						Mandatory			= $true)]
			[string]$target	
		)    

    Add-Type -Assembly System.IO.Compression
    Add-Type -Assembly System.IO.Compression.FileSystem

    $openMode = [System.IO.Compression.ZipArchiveMode]::Create
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    $fileName = (Get-ChildItem $file).Name
    $zipFileName = [String]::Format("{0}.{1}", (get-ChildItem $file).BaseName, "zip")
    $zipFilePath = [String]::Format("{0}\{1}", $target, $zipFileName)

    if(Test-Path $zipFilePath)
    {
        Remove-Item $zipFilePath
    }

    $zipFile = [System.IO.Compression.ZipFile]::Open($zipFilePath, $openMode)
    $entry = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipFile, $file, $fileName, $compressionLevel)
    $zipFile.Dispose()
}

function Open-ZipFile
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position			= 0, 
						Mandatory			= $true)]
			[string]$file
            ,
            [Parameter(	Position			= 1, 
						Mandatory			= $true)]
			[string]$target	
		)

    Add-Type -Assembly System.IO.Compression.FileSystem        

    [System.IO.Compression.ZipFile]::ExtractToDirectory($file, $target)
}

function Start-Build
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
            [Parameter(	Mandatory = $true)]
			[string]$configFile,
            [Parameter( Mandatory = $true)]
            [int]$TimeOut
		)
    
	Start-AxBuild -ConfigurationFile $configFile -TimeOutMinutes $TimeOut
}

function Start-Compile
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
            [Parameter(	Mandatory = $true)]
			[string]$configFile,
            [Parameter( Mandatory = $true)]
            [int]$TimeOut,
			[Parameter( Mandatory = $false)]
			[string]$ClientExecutablePath
		)

    Start-AxCompile -ConfigurationFile $configFile -TimeOutMinutes $TimeOut -ClientExecutablePath $ClientExecutablePath
}

function Start-PreExit
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
            [Parameter(	Mandatory = $true)]
			[string]$configFile,
            [Parameter( Mandatory = $true)]
            [int]$TimeOut,
			[Parameter( Mandatory = $false)]
			[string]$ClientExecutablePath
		)

    Start-AxPreExit -ConfigurationFile $configFile -TimeOutMinutes $TimeOut -ClientExecutablePath $ClientExecutablePath
}

function Start-KernelCompile
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
            [Parameter(	Mandatory = $true)]
			[string]$configFile,
            [Parameter( Mandatory = $true)]
            [int]$TimeOut,
			[Parameter( Mandatory = $false)]
			[string]$ClientExecutablePath
		)

    Start-AxKernelCompile -ConfigurationFile $configFile -TimeOutMinutes $TimeOut -ClientExecutablePath $ClientExecutablePath
}

function Start-CILBuild
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
            [Parameter(	Mandatory = $true)]
			[string]$configFile,
            [Parameter( Mandatory = $true)]
            [int]$TimeOut,
			[Parameter( Mandatory = $false)]
			[string]$ClientExecutablePath
		)
	
	Start-AxCILBuild -ConfigurationFile $configFile -TimeOutMinutes $TimeOut -ClientExecutablePath $ClientExecutablePath
}

function Start-DBSync
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
            [Parameter(	Position  = 0,
                        Mandatory = $true)]
			[string]$ConfigurationFile = $null,

            [Parameter( Position  = 1,
                        Mandatory = $true)]
            [int]$TimeOut         = $null
		)

    Start-AxDBSync -ConfigurationFile $ConfigurationFile -TimeOut $TimeOut
}

function Publish-Reports
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Mandatory	= $false)]
			[string[]]$Id,
			[Parameter(	Mandatory	= $true)]
			[string[]]$ReportName    = {*},
            [Parameter( Mandatory   = $false)]
            [DateTime]$ModifiedAfter = [DateTime]::MinValue,
            [Parameter(	Mandatory	= $false)]
            [switch]$RestartReportServer,
			[Parameter(	Mandatory	= $false)]
			[string]$ServicesAOSName,
			[Parameter(	Mandatory	= $false)]
			[string]$ServicesAOSWSDLPort
		)

	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

    # This (#@$*!) function does not accept positional parameters ...
    Publish-AXReport -Id $Id -ReportName $ReportName -ModifiedAfter $ModifiedAfter -RestartReportServer:$RestartReportServer.IsPresent -ServicesAOSName $ServicesAOSName -ServicesAOSWSDLPort $ServicesAOSWSDLPort 
}

function Publish-Portal
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position	= 0, 
						Mandatory	= $true)]
			[string]$Action,

			[Parameter(	Position	= 1, 
						Mandatory	= $true)]
			[string]$WebsiteURL
        )

    # Set the current path to the management tools path to access AXUpdatePortal.exe
    Set-AxManagementToolsPath

    $formattedAction = [String]::Format("-{0}", $Action)

    $portalScript = { param($action, $url) .\AXUpdatePortal.exe $action -websiteurl $url}

    # Call AXUpdatePortal.exe
    Invoke-Command -ScriptBlock $portalScript -ArgumentList ($formattedAction, $WebsiteURL) -Verbose
}

function Start-ReportStatus
{
	[CmdletBinding(SupportsShouldProcess=$true)]
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
			
	Start-SPReportStatus -SiteUrl $SiteUrl -DocumentListName $DocumentListName -DocumentListUrl $DocumentListUrl -DocumentTitle $DocumentTitle -Status $Status
}

# Initializes 
function Initialize-ModelStore
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
			[Parameter(	Position	= 0, 
						Mandatory	= $false)]
			[string]$server = $null
            ,
            [Parameter(	Position	= 1, 
						Mandatory	= $false)]
			[string]$database = $null
			,
            [Parameter(	Position	= 2, 
						Mandatory	= $false)]
			[string]$schemaName = $null
			,
            [Parameter(	Position	= 3, 
						Mandatory	= $false)]
			[string]$drop = $null
            ,
            [switch]$noPrompt
		)

	# First load the cmdLets from the AXUtil library
	Initialize-AxManagementTools

	Initialize-AXModelStore @PSBoundParameters
}
