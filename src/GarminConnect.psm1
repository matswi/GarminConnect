$GarminUri = @{
    Base    = "https://connect.garmin.com"
    SSO     = "https://sso.garmin.com/sso"
    Modern  = "https://connect.garmin.com/modern"
    SignIn  = "https://sso.garmin.com/sso/signin"
}
New-Variable -Name GarminUri -Value $GarminUri -Scope Script -Force

$GarminActivityUri = @{
    Sleep = $GarminUri.Modern + "/proxy/wellness-service/wellness/dailySleepData/"
}
New-Variable -Name GarminActivityUri -Value $GarminActivityUri -Scope Script -Force

$Headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"
    "origin" = "https://sso.garmin.com"
    "Content-Type" = "application/x-www-form-urlencoded"
}

New-Variable -Name Headers -Value $Headers -Scope Script -Force

function New-GarminConnectLogin {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ParameterSetName = "Credential")]
        [pscredential]$Credential,
        [Parameter(Mandatory, ParameterSetName = "UserName")]
        [string]$UserName,
        [Parameter(Mandatory, ParameterSetName = "UserName")]
        [SecureString]$Password
    )

    if ($pscmdlet.ParameterSetName -eq "Credential") {
        $UserName = $Credential.UserName
        [string]$Password = $Credential.GetNetworkCredential().Password
    }

    $initialLogin = Invoke-RestMethod -Uri $GarminUri.SignIn -Method Get -SessionVariable loginSession

    if ($null -ne $initialLogin) {
        
        $Body = "username=$Username&password=$Password&embed=true&_eventId=submit&displayNameRequired=false&lt=e1s1"

        $LoginResponse = Invoke-RestMethod -Uri $GarminUri.SignIn -Method Post -Headers $Headers -Body $Body -WebSession $loginSession
        $responseUri = $GarminUri.Modern + "/import-data"
        $response = Invoke-RestMethod -Uri $responseUri -Method Get -WebSession $loginSession -Headers $Headers

        if ($response.html.class -eq "signed-in") {

            $script:loginSession = $loginSession
            return $true
        }
        else {
            return $false
        }
        
    }
}

function Get-GarminSleepData {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$UserDisplayName,
        [Parameter()]
        [string]$Date
    )

    if ($date) {

    }
    else {
        $date = Get-Date -Format yyyy-MM-dd
    }

    $sleepUri = $GarminActivityUri.Sleep + $UserDisplayName + "?date=" + $date
    
    $sleepData = Invoke-RestMethod -Uri $sleepUri -Method Get -WebSession $loginSession -Headers $headers

    return $sleepData

}