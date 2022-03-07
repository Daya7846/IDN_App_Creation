Param(
  [Parameter(Mandatory=$true)]
  [string]$application,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName
)

$doesappexist = "No"

    if ($v3Token.access_token) {
        try {
          
               $IDNApps = Invoke-RestMethod -SkipCertificateCheck -Method Get -Uri "https://$($orgName).api.identitynow.com/cc/api/app/list?filter=org&offset=0&limit=2500" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" }
                foreach($apps in $IDNApps) {
                    $AppInfo =  $apps
                    if( $AppInfo.name -eq $application){
                        $doesappexist = $AppInfo

                       
                    }
                }
                return $doesappexist
                
        }
        catch {
            Write-Error "Application doesn't exist. Check App ID. $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    } 
