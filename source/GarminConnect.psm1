$GarminUri = @{
    Base    = "https://connect.garmin.com"
    SSO     = "https://sso.garmin.com/sso"
    Modern  = "https://connect.garmin.com/modern"
    SignIn  = "https://sso.garmin.com/sso/signin"
}
New-Variable -Name GarminUri -Value $GarminUri -Scope Script -Force

$GarminActivityUri = @{
    
    Activities = $GarminUri.Modern + "/proxy/activitylist-service/activities/search/activities/"
    Devices = $GarminUri.Modern + "/proxy/device-service/deviceregistration/devices/"
    DeviceSettings = $GarminUri.Modern + "/proxy/device-service/deviceservice/device-info/settings/"
}
New-Variable -Name GarminActivityUri -Value $GarminActivityUri -Scope Script -Force

$Headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"
    "origin" = "https://sso.garmin.com"
    "Content-Type" = "application/x-www-form-urlencoded"
}

New-Variable -Name Headers -Value $Headers -Scope Script -Force

function GetUserData {
    
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory)]
        [Object[]]$Response
    )

    [xml]$xml = $response.InnerXml
    
    $null = $xml.html.InnerText -match 'window.VIEWER_SOCIAL_PROFILE = JSON.parse\(\"(.*)\"\)'
    $socialProfile = $Matches[1].Replace('\','') | ConvertFrom-Json

    $UserData = @{
        profileId   = $socialProfile.profileId
        garminGUID  = $socialProfile.garminGUID
        displayName  = $socialProfile.displayName
        fullName    = $socialProfile.fullName
        userName    = $socialProfile.userName
    }
    
    New-Variable -Name UserData -Value $UserData -Scope Script -Force

    return $UserData
}

function InvokeGarminApi {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Fragment,
        [Parameter(Mandatory)]
        [ValidateSet("Get","Post")]
        $Method
    )

    if (-not $loginSession) {
        Throw "No websession, run New-GarminConnectLogin first."
    }

    $Params = @{
        Uri = '{0}/{1}' -f $GarminUri.Modern, $Fragment
        Method = $Method
        Headers = $Headers
        WebSession = $loginSession
    }

    Invoke-RestMethod @Params
}

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

        try {
            $userInfo = GetUserData -Response $response
        }
        catch {
            throw "Failed to get user data. Error: $($_.Exception.Message)"
        }

        if ($response.html.class -eq "signed-in") {

            $script:loginSession = $loginSession
            #return $true
            return $userInfo
        }
        else {
            return $false
        }
        
    }
}

function Get-GarminSleepData {

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Date
    )

    if (-not $date) {
        $date = Get-Date -Format yyyy-MM-dd
    }
    
    $fragment = "proxy/wellness-service/wellness/dailySleepData/" + $UserData.displayName + "/?date=" + $date
    
    InvokeGarminApi -Fragment $fragment -Method Get
    
}

function Get-GarminHeartRate {
    
    [CmdletBinding()]
    param (
        [Parameter()]
        $Date    
    )

    if (-not $Date) {
        $date = Get-Date -Format yyyy-MM-dd
    }

    $fragment = "proxy/wellness-service/wellness/dailyHeartRate/" + $UserData.displayName + "/?date=" + $date
    
    InvokeGarminApi -Fragment $fragment -Method Get
}

function Get-GarminActivities {
    
    [CmdletBinding()]
    param (
        [Parameter()]
        $Date    
    )

    if (-not $Date) {
        $date = Get-Date -Format yyyy-MM-dd
    }

    $fragment = "proxy/activitylist-service/activities/search/activities/" + $UserData.displayName + "/?date=" + $date
    
    InvokeGarminApi -Fragment $fragment -Method Get
}

function Get-GarminDevice {
    
    [CmdletBinding()]
    param (
            
    )

    if (-not $Date) {
        $date = Get-Date -Format yyyy-MM-dd
    }

    $fragment = "proxy/device-service/deviceregistration/devices/"
    
    InvokeGarminApi -Fragment $fragment -Method Get
}

function Get-GarminDeviceSetting {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $DeviceId
    )

    $fragment = "proxy/device-service/deviceservice/device-info/settings/" + $DeviceId
    
    InvokeGarminApi -Fragment $fragment -Method Get
}
