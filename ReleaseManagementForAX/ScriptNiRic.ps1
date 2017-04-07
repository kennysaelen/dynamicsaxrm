cd C:\Repository\ReleaseManagementForAX

./RDSPReportStatusManager.ps1 -SiteUrl  "https://portal.realdolmen.com/communities/AX" -DocumentListName "builds" -DocumentListUrl "Builds/PTC" -DocumentTitle "PTC_Build" -Status "OK"
#./RDSPReportStatusManager.ps1 -SiteUrl  "https://portal.realdolmen.com/communities/AX" -DocumentListName "builds" -DocumentListUrl "Builds/PTC" -DocumentTitle "PTC_Build" -Status "NOT OK"

$LASTEXITCODE