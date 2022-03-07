Param(
  [Parameter(Mandatory=$true)]
  [string]$orgName
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# IdentityNow API Client ID & Secret generated using New-IdentityNowAPIClient

#Sandbox
if ($orgName -eq "discovery-sb"){
    $clientID = '4jMc1Hb2D5ec0Mav'
    $clientSecret = 'uzgQj3x3FL9M3QDj8hmJz0nFcycypJNj'
}
#Staging 
if ($orgName -eq "discovery-stg"){
    $clientID = '3YaqrRLH812jSt0i'
    $clientSecret = 'D62TLxcTgZGPCip4O0gC0UXShQL2i8Gn'
}

if ($orgName -eq "discovery"){
    $clientID = ''
    $clientSecret = ''
}

$Bytes = [System.Text.Encoding]::utf8.GetBytes("$($clientID):$($clientSecret)") 
$encodedAuth = [Convert]::ToBase64String($Bytes)

$Headersv2 = @{Authorization = "Basic $encodedAuth"}
return $Headersv2