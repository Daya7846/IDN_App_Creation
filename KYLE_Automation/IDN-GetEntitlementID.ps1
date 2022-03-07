
Param(
  [Parameter(Mandatory=$true)]
  [string]$queryEntID,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName,
  [Parameter(Mandatory=$true)]
  [string]$source
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#body

$EntitlementName2 = $queryEntID

if ($EntitlementName2.Contains(' ')) {
    $EntitlementName = $EntitlementName2.Substring(0, $EntitlementName2.IndexOf(' '))
}elseif ($EntitlementName2.Contains('-')) {
    $EntitlementName = $EntitlementName2.Substring(0, $EntitlementName2.IndexOf('-'))
}else {
    $EntitlementName =  $EntitlementName2 -replace '\s',''
}

#body
$limit = "1000"
$query = "name:$EntitlementName"

    if ($v3Token.access_token) {
        try {                         
            # Get Users Based on Query
            $results = Invoke-RestMethod -SkipCertificateCheck -Method Get -Uri "https://$($orgName).api.identitynow.com/v2/search/entitlements?limit=$($limit)&query=$($query)" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" }                        
            foreach($ent in $results) {
                    $entInfo =  $ent
                    $entName = $ent.name 
                    if ($entName -eq $EntitlementName2 ){
                        if( $entInfo.source.name -eq $source){
                        $entDetails = $ent
                        }
                     }
                }
              
            return $entDetails
        }
        catch {
            Write-Error "Bad Query or more than 10,000 results? Check your query. $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    }


