# This is barebone PowerShell script used to deploy the build
# It is an alternative to the ReleaseManagement client
# This is sample script and should be extended with stuff like portal deployment, report deployment, ... and error handling, backups, restores, ...

# Used variables
$BuildNumber 					= "your build number"
$BuildPath 						= "C:\ReleaseManagementShare\Build\" + $BuildNumber
$AxClientConfigName 			= "C:\ReleaseManagementShare\SupportFiles\AX60_CIRB_DEV_VNEXT_CLIENT.axc"
$AxServerConfigName 			= "C:\ReleaseManagementShare\SupportFiles\AX60_CIRB_DEV_VNEXT_SERVER.axc"
$TargetSQLServerInstanceName 	= "Your SQL Server Instance Name"
$AxTargetModelStoreDatabasename = "Your model store db name"
$AOSServiceName					= "AOS60`$01"

$exitCode = 0

try
{
	cd C:\ReleaseManagementShare\PowerShellDeployment
	
    # Stop AOS windows service
	./ManageWindowsServices.ps1 -Action Stop 	-ServiceName $AOSServiceName
	
	# Clean AX artefacts like AUC files, ...
	./RDAXFolderCleaner.ps1 -AxClientConfigName $AxClientConfigName -AxServerConfigName $AxServerConfigName

	# Install all of the models contained in the build we are deploying
	# TODO adjust the model names or add lines to suit your build
	$modelFileName = $BuildPath + "\Model1.axmodel"
	./RDAXModelStoreManager.ps1 -Action "installModel" -server $TargetSQLServerInstanceName -database $AxTargetModelStoreDatabasename -File $modelFileName -replace "xx" -conflict "Push" -noPrompt

	$modelFileName = $BuildPath + "\Model1Labels.axmodel"
	./RDAXModelStoreManager.ps1 -Action "installModel" -server $TargetSQLServerInstanceName -database $AxTargetModelStoreDatabasename -File $modelFileName	-replace "xx" -conflict "Push" -noPrompt

	# Start AOS windows service
	./ManageWindowsServices.ps1 -Action Start 	-ServiceName $AOSServiceName
	
	# Start a full compilation
	./RDAXCompilationManager.ps1 -Action "axbuild" -AxClientConfigName $AxClientConfigName -TimeOut 90

	# Stop and restart AOS windows service
	./ManageWindowsServices.ps1 -Action Stop 	-ServiceName $AOSServiceName
	./ManageWindowsServices.ps1 -Action Start 	-ServiceName $AOSServiceName
	
	# Start a full CIL compilation
	./RDAXCompilationManager.ps1 -Action "CILBuild" -AxClientConfigName $AxClientConfigName -TimeOut 45

	# Stop and restart AOS windows service
	./ManageWindowsServices.ps1 -Action Stop 	-ServiceName $AOSServiceName
	./ManageWindowsServices.ps1 -Action Start 	-ServiceName $AOSServiceName
	
	# Perform a database synchronization
	./RDAXDatabaseManager.ps1 -Action "sync" -AxClientConfigName $AxClientConfigName -TimeOut 90
}
Catch [system.exception]
{
	$ErrorMessage = $_.Exception.Message
	
	"Error : PowerShell deploy of build " + $BuildNumber + " failed! Exception message: $ErrorMessage"	
	
	$ExitCode = 1
}

exit $exitCode