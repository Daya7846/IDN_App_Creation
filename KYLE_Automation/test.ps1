Param(
[Parameter(mandatory=$true)]
[string]$username,
[Parameter(mandatory=$true)]
[string]$environment,
[Parameter(mandatory=$true)]
[string]$Adminpwd,
[Parameter(mandatory=$true)]
[string]$csvWipe
)

Write-Host "-------------------------------Calling Script-------------------------------"

$path = "/var/jenkins/workspace/IDN-App onboarding/"
$Jenkinspath = $path +"uploads/"
#export-csv ($Jenkinspath + "discovery-sb-existingApps.csv")
#$nullcsv | export-csv ($Jenkinspath + "discovery-existingApps.csv")
#$nullcsv | export-csv ($Jenkinspath + "discovery-stg-existingApps.csv")
$nullcsv  = import-csv ($Jenkinspath + "discovery-uploadedApps.csv") #|sort ApplicationName

if($csvWipe -eq "stg"){
	Write-host "stg csv wipe"
    $nullcsv | export-csv ($Jenkinspath + $environment + "-existingApps.csv") -NoTypeInformation
}
if ($csvWipe -eq "sb"){
	Write-host "sb csv wipe"
    $nullcsv | export-csv ($Jenkinspath + $environment + "-existingApps.csv") -NoTypeInformation
}
if ($csvWipe -eq "prod"){
	Write-host "prod csv wpie"
    $nullcsv | export-csv ($Jenkinspath + $environment + "-existingApps.csv") -NoTypeInformation
}

&($path + "IDN-Master.ps1") -Environment $environment -userName $username -userPWD $Adminpwd -path $path
Write-Host "-------------------------------Completed-------------------------------"
