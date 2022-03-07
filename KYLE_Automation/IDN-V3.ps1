Param(
  [Parameter(Mandatory=$true)]
  [string]$orgName,
  [Parameter(Mandatory=$true)]
  [string]$userName,
  [Parameter(Mandatory=$true)]
  [string]$userPWD
)

$adminPWDClear = $userPWD
$adminUSR = $userName

function HashString {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$string,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet("MD5", "RIPEMD160", "SHA1", "SHA256", "SHA384", "SHA512")]
        [string]$hashType = "SHA256"
    )

    $StringBuilder = New-Object System.Text.StringBuilder 
    [System.Security.Cryptography.HashAlgorithm]::Create($hashType).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($string)) | ForEach-Object { 
        [Void]$StringBuilder.Append($_.ToString("x2")) 
    } 
    return $StringBuilder.ToString()  
}

# Generate the account hash
$hashUser = HashString $adminUSR.ToLower()
$adminPWD = HashString "$($adminPWDClear)$($hashUser)"

#V3
if ($orgName -eq "discovery-sb"){
    $clientIDv3 = "13bbf169-21b4-4506-a354-4d73e2777e6f"
    $clientSecretv3 = "30f42405339d39a12475f55c7c867ad8ef8ac43e66ad8d902c6660ce8e57bba8"
}
if ($orgName -eq "discovery-stg"){
    $clientIDv3 = "6b172592-64f6-480b-b8d9-a08e928d72ed"
    $clientSecretv3 = "ac059c3d7fafd997e205587f2daa83231b1ec8957e80b3a0a964a25bee28cd6a"
}
if ($orgName -eq "discovery"){
    $clientIDv3 = "2bebb576-b4d0-4c63-aa5f-16e7eedd7775"
    $clientSecretv3 = "6bb8211f44f96091f5a6d6f0813f0ec04c2107f2b33f441ca7bd41d8b72f85a9"
}

# Basic Auth
$Bytesv3 = [System.Text.Encoding]::utf8.GetBytes("$($clientIDv3):$($clientSecretv3)")
$encodedAuthv3 = [Convert]::ToBase64String($Bytesv3)
$Headersv3 = @{Authorization = "Basic $($encodedAuthv3)" }

$oAuthTokenBody = @{
	username   = $adminUSR
	grant_type = "password"
	password   = $adminPWD
            }
# Get v3 oAuth Token
# oAuth URI
$oAuthURI = "https://$($orgName).api.identitynow.com/oauth/token" 
try {                         
    # Get Users Based on Query
    $v3Token = Invoke-RestMethod -SkipCertificateCheck -Method Post -Uri $oAuthURI -Body $oAuthTokenBody -Headers $Headersv3
    return $v3Token
}Catch{
    Write-Host "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
    return $v3Token
}
