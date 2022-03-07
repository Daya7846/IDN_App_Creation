Param(
  [Parameter(Mandatory=$true)]
  [string]$GGMembers,
  [Parameter(Mandatory=$true)]
  [string]$GGID,
  [Parameter(Mandatory=$true)]
  [string]$orgName,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  $path
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#$Headersv2 += @{"Content-Type" = "application/json" }

#Body
$GGMembersSplit = $GGMembers.Split(",")
$add=@() 

if ($GGMembers -like "*,*"){
     
    foreach($user in $GGMembersSplit){
        $userDetails = &($path +"IDN-GetUserID.ps1") -userDetails $user -v3Token $v3Token -orgName $orgName
        $add += $userDetails.externalid     
    }
    $GGBodyUpdate =
        (@{
        add = $add
        }) | convertto-json
} else {
    $userDetails = &($path +"IDN-GetUserID.ps1") -userDetails $GGMembers -v3Token $v3Token -orgName $orgName
    $add += $userDetails.externalid
    $GGBodyUpdate =
     (@{
        add = $add
        }) | convertto-json
}

#Rest Call
    try {
        $UpdateGovGroup = Invoke-RestMethod -SkipCertificateCheck -Method Post -Uri "https://$($orgName).api.identitynow.com/v2/workgroups/$($GGID)/members" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)"} -ContentType "application/json" -Body $GGBodyUpdate
        return $UpdateGovGroup 
    }
    catch {
        Write-Error "Failed to update Governance Group. Check group details. $($_)" 
    }
