Param(
  [Parameter(Mandatory=$true)]
  $ApplicationlinkedAP,
  [Parameter(Mandatory=$true)]
  [string]$Source,
  [Parameter(Mandatory=$true)]
  $existingAP,
  [Parameter(Mandatory=$true)]
  [string]$ApplicationID,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName,
  [Parameter(Mandatory=$true)]
  $path,
  [Parameter(Mandatory=$true)]
  $AppOwner
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


#body
#SourceID
$sourceInfomation = &($path +"IDN-GetSourceID.ps1") -source $Source -v3Token $v3Token -orgName $orgName
$SourceID = $sourceInfomation.id
#appOwnerID
$userDetails = &($path +"IDN-GetUserID.ps1") -userDetails $AppOwner -v3Token $v3Token -orgName $orgName
$AppownerID = $userDetails.id
#
$addAllAP = @()
foreach($accessProfile in $ApplicationlinkedAP){
        $AcessProfileDetails = &($path + "IDN-GetAcessProfile.ps1") -APname $accessProfile -v3Token $v3Token  -orgName $orgName
        if ($AcessProfileDetails.id){
        	$addAllAP += $AcessProfileDetails.id 
        }
             
}
$ExsistingAPArray = $existingAP.split(" ")
 $addExistingAP = @()
if($existingAP -ne "NoExisting"){
    foreach($existAP in $ExsistingAPArray){      
        $addExistingAP += $existAP
    }       
}


#access profile ID
$add=@()
if($existingAP -ne "NoExisting"){
    $existingAP2 = $existingAP  
    $add += $addAllAP
    $add += $addExistingAP
}else{
    $add += $addAllAP
}
$falseCondition = "false"
$trueCondtion = "true"

$ApplicationBodyUpdate = (@{
    accountServiceId = $SourceID 
    accessProfileIds = $add
    launchpadEnabled = $trueCondtion
    provisionRequestEnabled = $trueCondtion
    ownerId = $AppownerID
    accountServiceMatchAllAccounts = $falseCondition
    }) | convertto-json 

    Write-host $ApplicationBodyUpdate
    if ($v3Token.access_token) {
        for( $i = 0 ; $i -lt 5; $i++){
            $activeJobs = &($path +"IDN-GetActiveJobs.ps1")-v3Token $v3Token -orgName $orgName
            $activejobDescription = $activeJobs.description
            $stringAcrtiveJobs = "$activejobDescription"
            #if ($stringAcrtiveJobs -notmatch "Refresh Identities"){
                if ($stringAcrtiveJobs -notmatch "Account Aggregation"){
                    try {     
                            Write-Verbose $ApplicationBodyUpdate 
                            $IDNApps = Invoke-RestMethod -SkipCertificateCheck -Method Post -Uri "https://$($orgName).api.identitynow.com/cc/api/app/update/$($ApplicationID)" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)"; "Content-Type" = "application/json" } -Body $ApplicationBodyUpdate 
                            return $IDNApps
                    
                     }
                     catch {
                                Write-Error "Update to Application failed. Check App ID and update configuration. $($_)" 
                     }
                 }
                
           # }
                
           if ($i -eq 5){
                Write-host "Active job - please try again after the refresh is complete"
                break
           }

           Write-Host "Delay in call due to running Job" 
           Start-Sleep -Seconds 30
        }
        
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    }

