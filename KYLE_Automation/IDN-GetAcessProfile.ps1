Param(
  [Parameter(Mandatory=$true)]
  [string]$APname,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName
)


$doesappexist = "Null"

  if ($v3Token.access_token) {
        try {
            
                $IDNAccessProfiles = Invoke-RestMethod  -SkipCertificateCheck -Method Get -Uri "https://$($orgName).api.identitynow.com/v2/access-profiles?_offset=0&limit=2500" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" }
                foreach($AP in $IDNAccessProfiles) {
                    $APInfo =  $AP
                    if( $APInfo.name -eq $APname){
                        $doesappexist = $APInfo
                    }
                }
                return $doesappexist
        }
        catch {
            Write-Error "Access Profile doesn't exist. Check Profile ID. $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    }  
