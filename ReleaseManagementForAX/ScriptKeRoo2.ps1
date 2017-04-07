cd C:\Repository\ReleaseManagementForAX
#./RDAXModelStoreManager.ps1 -Action "setModelStore" -NoInstallMode
#./RDAXReports.ps1 -Action "DeployReports" -Id "AX2012TFSMSSQLSERVER" -ReportName * -RestartReportServer
./RDSPReportStatusManager.ps1 -SiteUrl  "https://portal.realdolmen.com/communities/AX" -DocumentListName "builds" -DocumentListUrl "Builds/PTC/" -DocumentTitle "build_tst.txt" -Status "OK" -TimeOut 5

$LASTEXITCODE