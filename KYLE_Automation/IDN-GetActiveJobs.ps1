Param(
  [Parameter(Mandatory=$true)]
  $v3Token,
  [Parameter(Mandatory=$true)]
  [string]$orgName
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if ($v3Token.access_token) {
        try {
            $Jobs = Invoke-RestMethod -SkipCertificateCheck -Method Get -Uri "https://$($orgName).api.identitynow.com/cc/api/message/getActiveJobs" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" }                                                                                     
            return $Jobs
        }
        catch {
            Write-Error "Problem getting Active Jobs. $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    } 
 

