Param(
  [Parameter(Mandatory=$true)]
  [string]$GGroup,
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName
  )

    if ($v3Token.access_token) {
        try {
                $IDNGroups = Invoke-RestMethod -SkipCertificateCheck -Method Get -Uri "https://$($orgName).api.identitynow.com/v2/workgroups?org=$($orgName)" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" }
                foreach($groups in $IDNGroups) {
                    $groupInfo =  $groups
                    if($groupInfo.name -eq $GGroup){
                       $doesappexist = $groupInfo
                       
                    }
                }
                return $doesappexist
        }
        catch {
            Write-Error "Group doesn't exist. Check group ID. $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    } 
