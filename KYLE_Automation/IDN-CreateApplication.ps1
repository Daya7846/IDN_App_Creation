Param(
  [Parameter(Mandatory=$true)]
  [string]$ApplicationBodyCreate,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


if ($v3Token.access_token) {
    try {
        $IDNCreateAP = Invoke-RestMethod  -SkipCertificateCheck -Method Post -Uri "https://$($orgName).api.identitynow.com/cc/api/app/create" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" ; "Content-Type" = "application/json" } -Body $ApplicationBodyCreate     
                return $IDNCreateAP
    }
    catch {
        Write-Error "Creation of Application failed. Check Access Profile configuration (JSON). $($_)"
    }
} 
else {
    Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
    return $v3Token
}
