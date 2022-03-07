Param(
  [Parameter(Mandatory=$true)]
  [string]$userDetails,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName
)

#body
$limit = "10"

    if ($v3Token.access_token) {
        try {                         
            # Get User Profiles Based on Query
            $userProfiles = Invoke-RestMethod -SkipCertificateCheck -Method Get -Uri "https://$($orgName).identitynow.com/cc/api/user/list?_dc=$($utime)&listErrorFirst=true&useSds=true&start=0&limit=$($limit)&sorters=%5B%7B%22property%22%3A%22name%22%2C%22direction%22%3A%22ASC%22%7D%5D&filters=%5B%7B%22property%22%3A%22username%22%2C%22value%22%3A%22$($userDetails)%22%7D%5D" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" } 
             foreach($users in $userProfiles.items) {
                    $userInfo =  $users
                    if( $userInfo.alias -eq $userDetails){
                        $userProfile = $userInfo
                    }
                }
            return $userProfile
        }
        catch {
            Write-Error "Bad Query. Check your query. $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    } 

