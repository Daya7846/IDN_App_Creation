
Param(
  [Parameter(Mandatory=$true)]
  [string]$Source,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName
)

    if ($v3Token.access_token) {
        try {
            $IDNSources = Invoke-RestMethod -SkipCertificateCheck -Method Get -Uri "https://$($orgName).api.identitynow.com/cc/api/source/list" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" }
            $IDNSources2 = $IDNSources 

                foreach($IDNSources2 in $IDNSources) {
                    $sourceInfo =  $IDNSources2
                    if( $sourceInfo.name -contains $Source){
                        $sourceInfomation = $sourceInfo
                    }
                }

            return $sourceInfomation
        }
        catch {
            Write-Error "Source doesn't exist. Check SourceID. $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    } -SkipCertificateCheck
