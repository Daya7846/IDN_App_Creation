Param(
  [Parameter(Mandatory=$true)]
  [string]$appID,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName
)

$doesappexist = "No"

    if ($v3Token.access_token) {
        try {
          
            $IDNApps = Invoke-RestMethod -SkipCertificateCheck -Method Get -Uri "https://$($orgName).api.identitynow.com/cc/api/app/getAccessProfiles/$AppID" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" }
            $LinkedAP = $IDNApps.items
            $add=@() 
            
            foreach($list in  $LinkedAP) {
                $add += $list.id 
            }
            return $add
        }
        catch {
            Write-Error "Application doesn't exist. Check App ID. $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    } 
