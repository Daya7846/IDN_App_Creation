Param(
  [Parameter(Mandatory=$true)]
  [string]$APDesc,
  [Parameter(Mandatory=$true)]
  [string]$EntitlementName,
  [Parameter(Mandatory=$true)]
  [string]$APname,
  [Parameter(Mandatory=$true)]
  [string]$APowner,
  [Parameter(Mandatory=$true)]
  [string]$Source,
  [Parameter(Mandatory=$true)]
  [string]$approvalScheme,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName,
  [Parameter(Mandatory=$true)]
  $path
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#APowner
$userDetails = &($path +"IDN-GetUserID.ps1") -userDetails $APowner -v3Token $v3Token -orgName $orgName
$APowner = $userDetails.id
#SourceID
$sourceInfomation = &($path +"IDN-GetSourceID.ps1") -source $Source -v3Token $v3Token -orgName $orgName
$SourceID = $sourceInfomation.id
#entitlements
$EntitlementNameSplit = $EntitlementName.Split(",")
$add=@()
if ($EntitlementName -like "*,*"){     
    foreach($ent in $EntitlementNameSplit){
        $entDetails = &($path +"IDN-GetEntitlementID.ps1") -queryEntID $ent -v3Token $v3Token -orgName $orgName -source $Source
        $add += $entDetails.id   
    }
} else {
    $EntitlementQueryResponse=  &($path +"IDN-GetEntitlementID.ps1") -queryEntID $EntitlementName -v3Token $v3Token -orgName $orgName -source $Source
    $add += $EntitlementQueryResponse.id
}
$trueCondtion = "true"
if (!$add){ 
	Write-Host $APname
}
if ($approvalScheme -eq "No"){ 
	$approvalScheme = ""
}
#Body
Write-host $APBodyCreate
$APBodyCreate = (@{
    entitlements = $add
    description = $APDesc
    name = $APname
    ownerId = $APowner
    sourceId = $SourceID
    deniedCommentsRequired = $trueCondtion
    requestCommentsRequired = $trueCondtion
    approvalSchemes = $approvalScheme}) | convertto-json -Compress

If($add) {
  if ($v3Token.access_token) {
      try {
          $IDNCreateAP = Invoke-RestMethod  -SkipCertificateCheck -Method Post -Uri "https://$($orgName).api.identitynow.com/v2/access-profiles" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" ; "Content-Type" = "application/json" } -Body $APBodyCreate
          return $IDNCreateAP
      }
      catch {
          Write-Error "Creation of Application failed. Check Access Profile configuration (JSON). $($_)"
          Write-Host $APBodyCreate
      }
  } 
  else {
      Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
      return $v3Token
  }
}
else {
	Write-Error "Enititlment Not found"
}


