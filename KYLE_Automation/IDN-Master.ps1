Param(
  [Parameter(Mandatory=$true)]
  [string]$Environment,
  [Parameter(Mandatory=$true)]
  [string]$userName,
  [Parameter(Mandatory=$true)]
  [string]$userPWD,
  [Parameter(Mandatory=$true)]
  [string]$path
)

#Master Call
$Jenkinspath = $path +"uploads/"
$JenkinspathBackups = $path + "uploads/backups/"
$getTime = Get-Date -Format "yyyy_MM_dd-HH-mm"

#Variables
$orgName = $Environment
#V2Token
#$Headersv2 = &($path + 'IDN-V2.ps1') -orgName $orgName
#v3Token
$v3Token = &($path +"IDN-V3.ps1") -orgName $orgName -userPWD $userPWD -userName $userName

$tokenQueryTime = get-date -Format HH:mm:ss
$tokenExpiry = (get-date).AddMinutes(10).ToString("HH:mm:ss")

#import CSV file
#get last imported file
#$lastFile = gci $Jenkinspath  | Sort-Object LastWriteTime -Descending | select -first 1
$lastFile = "uploadedApps.csv"

#exsiting csv
$Exsistingcsv = import-csv ($Jenkinspath + $Environment + "-existingApps.csv") #|sort ApplicationName
$Exsistingcsv  | export-csv  ($JenkinspathBackups + $Environment + $getTime+"existingApps.csv")  -NoTypeInformation

#import new CSV
if ($lastFile){
    $uploadedcsv = import-csv ($Jenkinspath + "uploadedApps.csv") #|sort ApplicationName
    $uploadedcsv | export-csv  ($JenkinspathBackups + $Environment + $getTime+ "uploadedApps.csv")  -NoTypeInformation
}

$removeitem = @()
$removeNewitem = @()
$removeitem = foreach($line in $Exsistingcsv){
    if(!($line.Added  -like "Yes")){
        $line
    }
}
$removeNewitem = foreach($line in $uploadedcsv){
    if(!($line.Added  -like "Yes")){
        $line
    }
}

Write-Host "----------------------Existing Applications--------------------"
Write-Host $removeitem
Write-Host "----------------------New Applications--------------------"
Write-Host $removeNewitem

$combinedCSV = @()
if ($removeNewitem){
    $combinedCSV +=  $removeNewitem
}
if ($removeitem){
    $combinedCSV += $removeitem
}

#$combinedCSV =  $removeNewitem + $removeitem
$combinedCSV | export-csv  ($Jenkinspath + $Environment +"-existingApps.csv") -NoTypeInformation
$csv = Import-Csv ($Jenkinspath + $Environment + "-existingApps.csv")

$rowCount = $csv.Rows.Count
Write-Host $rowCount 

Write-Host "----------------------Combined Applications--------------------"
Write-host $csv
Write-host "===============================================================" 

#App Update
$applicationArray = @()
$applicationArray = $csv
$APArray = @()
$applicationName = ""
$lastApp =  ($applicationArray.ApplicationName | select -Last 1)
Write-Host "-----------------------------------------------------------"

#Get App ID
function GetAppID($appname){
#Write-Host "we are calling APPID - $appname"

    $Applicationexist = &($path + "IDN-GetApplication.ps1") -application $appname -orgName $orgName -v3Token $v3Token
    $ApplicationID = $Applicationexist.id
    return $ApplicationID
}
#Get Exsisting AP linked
function GetExsistingAPLinked(){
     $ApplicationLinkedAP = &($path + "IDN-GetApplicationAP.ps1") -appID $ApplicationID -orgName $orgName -v3Token $v3Token
     $existingAP = $ApplicationLinkedAP
     return $existingAP
}

#UpdateApplication
function UpdateApplication(){
Param(
  [Parameter(Mandatory=$true)]
  $existingAP,
  [Parameter(Mandatory=$true)]
  $ApplicationID,
  [Parameter(Mandatory=$true)]
  $APArray,
  [Parameter(Mandatory=$true)]
  $AppOwner,
  [Parameter(Mandatory=$true)]
  $Source
)
$existingAP = "$existingAP"
    if(!$existingAP){
        $existingAP = "NoExisting"
    }
    $ApplicationBodyUpdateResponse = ""
    $ApplicationBodyUpdateResponse = &($path + "IDN-UpdateApplication.ps1") -ApplicationlinkedAP $APArray  -ApplicationID $ApplicationID -Source $Source -existingAP $existingAP -orgName $orgName -v3Token $v3Token -path $path -AppOwner $AppOwner
    if($ApplicationBodyUpdateResponse -match $ApplicationID){
        Write-Host "Access Profile added to Application"
    }
    $APArray = @()
    return $ApplicationBodyUpdateResponse
}


#Calls
If($v3Token){

    $NewCSV = ForEach($line in $csv){

        #Variables
        #GGVariables
        $GGName = ($line.GovernanceGroupName) #.Trim()  -replace '[^\p{L}\p{Nd}( )]', '' 
        $GGDesc = $line.GovernaceGroupDescription  -replace '[^\p{L}\p{Nd}( )-]', '' 
        $GGOwn = ($line.GovernanceGroupOwner).Trim()  -replace '[^\p{L}\p{Nd}( )-]', '' 
        $GGMembers = ($line.GovernanceGroupMembers)  #-replace '[^\p{L}\p{Nd}( )-]', '' 
        $ManagerApproval = ($line.ManagerApproval) 

        #APVariables
        $APDesc = ($line.AccessProfileDescription) # -replace '[^\p{L}\p{Nd}( )-]', '' 
        $APname = ($line.AccessProfileName).Trim() # -replace '[^\p{L}\p{Nd}( )-]', '' 
        $APowner = ($line.AccessProfileOwner).Trim()  -replace '[^\p{L}\p{Nd}( )-]', '' 
        $Source = ($line.Source).Trim()

        #AppVariables
        $appName = $line.ApplicationName #).Trim() # -replace '[^\p{L}\p{Nd}( )-]', '' 
        $appDesc = $line.ApplicationDescription  -replace '[^\p{L}\p{Nd}( )-]', '' 
        $AppOwner = ($line.ApplicationOwner).Trim()  -replace '[^\p{L}\p{Nd}( )-]', '' 

        #Entitlement
        $EntitlementName = $line.EntitlementName  #-replace '[^\p{L}\p{Nd}( )-_]', '' 
        $query = "entitlement.description:'Human Resources Access'"

		$currentTime = get-date -Format HH:mm:ss
		if ( $currentTime -ge $tokenExpiry){
         	Write-host "---------------Time for new token---------------"
            $v3Token = &($path +"IDN-V3.ps1") -orgName $orgName -userPWD $userPWD -userName $userName
			$tokenExpiry = (get-date).AddMinutes(10).ToString("HH:mm:ss")
            Write-host "---------------New token Fetched---------------"
			
		}

        if($line.Added -contains 'No'){
        Write-Host -ForegroundColor Blue "*********/" $appName "/***********"

            #Governace Group
            $GovernanceGroupID = ""
            if($line.GovernanceGroupName){
           
               $checkForGG = &($path + "IDN-GetGovernanceGroup.ps1") -GGroup $GGName -v3Token $v3Token  -orgName $orgName
                if($checkForGG){
                    $GovernanceGroupID =  $checkForGG.id
                    Write-Host "Governance Group already exists ($GGName)"
                }else{
                    if($line.GovernanceGroupName -and $line.GovernaceGroupDescription -and $line.GovernanceGroupOwner -and $line.GovernanceGroupMembers){
                        #Create
                        $CreateGGResponse = &($path + "IDN-CreateGovernanceGroup.ps1") -GGName $GGName -GGDesc $GGDesc -GGOwn $GGOwn -orgName $orgName -v3Token $v3Token -path $path

                        if($CreateGGResponse){
                            Write-Host "Governance Group created ($GGName)"
                        }
                        #Add Members to Governace group
                        $GovernanceGroupID = $CreateGGResponse.id    
                        $UpdateGGResponse = &($path + "IDN-updateGovernanceGroup.ps1") -GGMembers $GGMembers -GGID $GovernanceGroupID -orgName $orgName -v3Token $v3Token -path $path
                    }else {
                        Write-Host "A Value is Missing , Governance Group hasnt been created"
                    }
                    
                 }
            }
            
            #Access Profiles

            #Create Access Profile
            
            $approvalScheme = "no"
            if( $ManagerApproval -eq "yes"){
            	$approvalScheme = "manager"
            }
            if($GovernanceGroupID){
            	if ( $ManagerApproval -eq "yes"){
	                $approvalScheme = "manager,workgroup: $GovernanceGroupID"
              	}else {
                	$approvalScheme = "workgroup: $GovernanceGroupID"
                }
            }

            $checkForAP = &($path + "IDN-GetAcessProfile.ps1") -APname $APname -v3Token $v3Token  -orgName $orgName
            If($checkForAP -eq "Null"){
                if($line.AccessProfileDescription -and $line.AccessProfileName -and $line.AccessProfileOwner -and $line.Source -and $line.EntitlementName){
                    $APBodyCeateResponse = &($path + "IDN-CreateAccessProfile.ps1") -APDesc $APDesc -EntitlementName $EntitlementName -APname $APname -APowner $APowner -Source $Source -approvalScheme $approvalScheme -orgName $orgName -v3Token $v3Token -path $path
                    if($APBodyCeateResponse){
                        Write-Host "Access Profile Created ($APname)"
                    }
                }else {
                    Write-Host "A Value is Missing , Access Profile hasnt been created"
                }
                
                $APID = $APBodyCeateResponse.id
            }Else{
                Write-Host "Access Profile already exists ($APname)"
                $APID = $checkForAP.id

            }
        
            #Application

            #CreateApplication
            $Applicationexist = &($path + "IDN-GetApplication.ps1") -application $appName -orgName $orgName -v3Token $v3Token
            if($Applicationexist -eq "No"){
                If ($line.ApplicationName -and $line.ApplicationDescription){
                    $ApplicationBodyCreate = @{name= $appName; description= $appDesc}  | convertto-json -Compress
                    $ApplicationBodyCreateResponse = &($path + "IDN-CreateApplication.ps1") -ApplicationBodyCreate $ApplicationBodyCreate -orgName $orgName -v3Token $v3Token 
                    $ApplicationID = $ApplicationBodyCreateResponse.id
                    if($ApplicationBodyCreateResponse){
                        Write-Host "Application Created ($appName)"
                    }
                }else {
                    Write-Host "A Value is Missing , Application hasnt been created"
                }
                
            }else {
                
                Write-Host "Application already exists ($appName)"
            }

        } else {
            Write-Host -ForegroundColor blue $line.ApplicationName
            Write-Host "Application not added due to the ADDED column in the CSV file"
        } #end else
         Write-Host "-----------------------------------------------------------"
    }#end forloop csv

Write-Host -foregroundcolor Magenta "Application update"
$appsProvisioned = @()
$newArray = $applicationArray
write-host "-=-=-=-=-=-==-=-=-="
write-host $applicationArray.ApplicationName
write-host "-=-=-=-=-=-==-=-=-="

$count = 1
    foreach($item in $applicationArray) {

        #Variables

        #AppVariables
        $AppOwner = ($item.ApplicationOwner).Trim() -replace '[^\p{L}\p{Nd}( )-]', '' 
        $Source = ($item.Source).Trim() 
        $applicationName = $item.ApplicationName #).Trim() -replace '[^\p{L}\p{Nd}( )-]', '' 

        If ($previousAppName -eq $applicationName -and $item.Added -eq "No"){

            $APArray +=  $item.AccessProfileName -replace '[^\p{L}\p{Nd}( )-]', '' 
            If ($lastApp -eq $applicationName -and $count -eq $rowCount){
            Write-Host "-----------------------------------------------------------"
            Write-Host -ForegroundColor Blue $applicationName
            Write-Host "AccessProfiles ($APArray)"
             	$v3Token = &($path +"IDN-V3.ps1") -orgName $orgName -userPWD $userPWD -userName $userName
                $ApplicationID = GetAppID($applicationName)
                #Write-Host $ApplicationID "-app ID"
                if ($ApplicationID){
                    $existingAP = GetExsistingAPLinked($ApplicationID)
                    if (!$existingAP){
                        $existingAP = "NoExisting"
                    }
                #Write-host $existingAP
                    $updateappResp = UpdateApplication -existingAP $existingAP -ApplicationID $ApplicationID -APArray $APArray -appOwner $AppOwner -source $Source
                    $APArray = @()
                    if ($updateappResp){
                        <#foreach($row in $newArray){
                            if(!$row.ApplicationName -notlike $applicationName){
                                $appsProvisioned += $row
                            }
                             
                        }#>
                       $appsProvisioned += $applicationName
                       
                    }    
                }else {

                }
                Write-Host "-----------------------------------------------------------"
            }
        } else {
            If ($APArray){
                Write-Host "-----------------------------------------------------------"
                Write-Host -ForegroundColor Blue $previousAppName
                Write-Host "AccessProfiles ($APArray)"
                 $v3Token = &($path +"IDN-V3.ps1") -orgName $orgName -userPWD $userPWD -userName $userName
                $ApplicationID = GetAppID($previousAppName)
                if ($ApplicationID){
                    #Write-Host $ApplicationID "-app ID"
                    $existingAP = GetExsistingAPLinked($ApplicationID)
                    if (!$existingAP){
                        $existingAP = "NoExisting"
                    }
                    #Write-host $existingAP
                    $updateexistApp = UpdateApplication -existingAP $existingAP -ApplicationID $ApplicationID -APArray $APArray -appOwner $previousAppOwner -source $previousSource
                    $APArray = @()
                    if ($updateexistApp){
                        <#foreach($row in $newArray){
                            if($row.ApplicationName -notlike $previousAppName){
                                 $appsProvisioned += $row
                            }
                             
                        }#>
                        $appsProvisioned += $previousAppName
                        
                    } 
                }else {
                    Write-Host "Application doesnt exist"
                } 

                #Write-Host $ApplicationID "-app ID"
                Write-Host "-----------------------------------------------------------"
            }
            if ($lastApp -eq $applicationName -and $count -eq $rowCount){
              Write-Host "-----------------------------------------------------------"
              Write-Host -ForegroundColor Blue $applicationName
              if (!$APArray){
                 $APArray +=  $item.AccessProfileName -replace '[^\p{L}\p{Nd}( )-]', ''
              }
              Write-Host "AccessProfiles ($APArray)"
              $ApplicationID = GetAppID($applicationName)
              	$v3Token = &($path +"IDN-V3.ps1") -orgName $orgName -userPWD $userPWD -userName $userName
                #Write-Host $ApplicationID "-app ID"
                if ($ApplicationID){
                    $existingAP = GetExsistingAPLinked($ApplicationID)
                    if (!$existingAP){
                        $existingAP = "NoExisting"
                    }
                    
                #Write-host $existingAP
                    $updateappResp = UpdateApplication -existingAP $existingAP -ApplicationID $ApplicationID -APArray $APArray -appOwner $AppOwner -source $Source
                    if ($updateappResp){
                        <#foreach($row in $newArray){
                            if(!$row.ApplicationName -notlike $applicationName){
                                $appsProvisioned += $row
                            }
                             
                        }#>
                       $appsProvisioned += $applicationName
                    }    
                }else {
                    
                }
            }
            $APArray = @()
            If ($item.Added -eq "No"){
                $APArray +=  $item.AccessProfileName -replace '[^\p{L}\p{Nd}( )-]', '' 
            }
            
        }
        $previousSource = $Source
        $previousAppOwner = $AppOwner
        $previousAppName =  $applicationName 
        $count += 1

    }
    
    Write-Host "Apps Provisioned - " $appsProvisioned
    
    $ExistingapplicationArray = @()
    
    #$appsProvisionedName = $appsProvisioned.ApplicationName | select -Unique
    
    Write-host "====" $appsProvisioned "===="
    

    if ($appsProvisioned){
        $ExistingapplicationArray = $applicationArray |Where-Object { $appsProvisioned -notcontains $_.applicationName }
       <# foreach ($item in $applicationArray){
            $combinedAppname = $item.ApplicationName
            foreach ($row in $appsProvisioned){
                $provisionedAppname = $row 
                if($combinedAppname -notmatch $provisionedAppname){
                    $ExistingapplicationArray = $ExistingapplicationArray + $Item
                }
            }
        }#>
        Write-Host "-----------If ---------------"
        Write-Host $ExistingapplicationArray 
        Write-Host "--------------------------"
    }else {
        $ExistingapplicationArray =  $applicationArray
        Write-Host "else statement" $ExistingapplicationArray
    }

$ExistingapplicationArray | export-Csv ($Jenkinspath + $Environment + "-existingApps.csv") -NoTypeInformation

}Else{
    Write-Host "Please try again"
}#end v3Token
