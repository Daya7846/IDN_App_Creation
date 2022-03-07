Param(
  [Parameter(Mandatory=$true)]
  [string]$GGName,
  [Parameter(Mandatory=$true)]
  [string]$GGDesc,
  [Parameter(Mandatory=$true)]
  [string]$GGOwn,
  [Parameter(Mandatory=$true)]
  [string]$orgName,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  $path
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


#body 

$userDetails = &($path +"IDN-GetUserID.ps1") -userDetails $GGOwn -v3Token $v3Token -orgName $orgName
$GGOwnID = $userDetails.externalid

$GGBodyCeate = @{name= $GGName; description= $GGDesc; owner = @{id=$GGOwnID}} | ConvertTo-Json -Compress

try {
        $IDNNewGroup = Invoke-RestMethod  -SkipCertificateCheck -Method Post -Uri "https://$($orgName).api.identitynow.com/v2/workgroups" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)"} -ContentType "application/json"  -Body $GGBodyCeate 
        return $IDNNewGroup              
}
catch {
        Write-Error "Failed to create group. Check group details. $($_)" 
}
