#Import-Module C:\TFS\Online_AX2012_RMPOC\RDAX.CodeCribWrapper\bin\Debug\RDAX.CodeCribWrapper.dll -Verbose
#Start-AxBuild -TimeOutMinutes 30 -ConfigurationFile "C:\Builds\SupportFiles\AX2012R3ClientConfig.axc" -LogPath "C:\Temp\LOG\Log.txt" -verbose
#$result = Get-AxBuildLog -LogName "C:\Program Files\Microsoft Dynamics AX\60\Server\AX60\Log\AxCompileAll.html"
#$Error.Count

Stop-Service -DisplayName 'Microsoft Dynamics AX Object Server 6.3$01-AX60'

cd C:\TFS\Online_AX2012_RMPOC\ReleaseManagementForAX\
.\RDAXFolderCleaner.ps1 -AxClientConfigName "C:\Builds\SupportFiles\AX2012R3ClientConfig.axc" -AxServerConfigName "C:\Builds\SupportFiles\AX2012R3ServerConfig.axc"

./RDAXModelStoreManager.ps1 -Action "installModel" -file "C:\Temp\BLOG.axmodel" -replace "BLOG" -conflict "Push" -noPrompt
./RDAXModelStoreManager.ps1 -Action "setModelStore" -NoInstallMode

Start-Service -DisplayName 'Microsoft Dynamics AX Object Server 6.3$01-AX60'

./RDAXBuilder.ps1 -Action "build" -clientConfigPath "C:\Builds\SupportFiles\AX2012R3ClientConfig.axc" -TimeOut 60
./RDAXBuilder.ps1 -Action "CILBuild" -clientConfigPath "C:\Builds\SupportFiles\AX2012R3ClientConfig.axc" -TimeOut 60
./RDAXDatabase.ps1 -Action "sync" -clientConfigPath "C:\Builds\SupportFiles\AX2012R3ClientConfig.axc" -TimeOut 60
./RDAXReports.ps1 -Action "DeployReports" -Id "AX2012TFSMSSQLSERVER" -ReportName * -RestartReportServer
./RDAXPortal.ps1 -Action "UpdateAll" -WebsiteURL "http://ax2012tfs/sites/DynamicsAx"


#./RDAXBuilder.ps1 -Action "compile" -clientConfigPath "C:\Builds\SupportFiles\AX2012R3ClientConfig.axc" -TimeOut 720 -Verbose
#./RDAXBuilder.ps1 -Action "CILBuild" -clientConfigPath "C:\Builds\SupportFiles\AX2012R3ClientConfig.axc" -TimeOut 60 -Verbose

#./RDAXReports.ps1 -Action "DeployReports" -Id "AX2012TFSMSSQLSERVER" -ReportName * -RestartReportServer -VerboseDeployPortal
#./RDAXPortal.ps1 -Action "UpdateAll" -WebsiteURL "http://ax2012tfs/sites/DynamicsAx"

#./RDAXModelStoreManager.ps1 -Action "ExportModel" -file "C:\Temp\MyModel.axmodel" -model 19
#./RDAXModelStoreManager.ps1 -Action "ImportModel" -file "C:\Temp\MyModel.axmodel" -conflict "overwrite" -replace 19 -noPrompt
#./RDAXModelStoreManager.ps1 -Action "ExportModelStore" -file "C:\Temp\MyModelStore.axmodelstore" -zip
#./RDAXModelStoreManager.ps1 -Action "ImportModelStore" -file "C:\Temp\MyModelStore.axmodelstore" -noPrompt


#$InvocationDir 		= Split-Path $MyInvocation.MyCommand.Path
#$AXModuleFileName 	= [string]::Format("{0}\RDAXManagement.psd1", $InvocationDir);
#Import-Module -Name $AXModuleFileName -Verbose
#Write-Zip -File "C:\Temp\MyModel.axmodel" -Target "C:\Temp\MyModel.zip"
#Open-ZipFile -File "C:\Temp\MyModelStore.zip" -Target "C:\Temp\Output\"

$LASTEXITCODE