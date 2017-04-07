cd C:\Users\Administrator\source\OnlineTFS_RMPOC\ReleaseManagementForAX
#./RDAXFolderCleaner.ps1 -AxClientConfigName "C:\Builds\SupportFiles\AX2012R3ClientConfig.axc" -AxServerConfigName "C:\Builds\SupportFiles\AX2012R3ServerConfig.axc"

#./RDAXModelStoreManager.ps1 -Action "ExportModel" -file "C:\temp\MyModel.axmodel" -model 19

./RDAXModelStoreManager.ps1 -Action "InstallModel" -file "C:\temp\MyExportedModel.axmodel" -conflict "overwrite" -replace 19 -noPrompt