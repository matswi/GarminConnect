task Package {
    if ((Test-Path "$PSScriptRoot\out")) {
        Remove-Item -Path $PSScriptRoot\out -Recurse -Force
    }

    New-Item -ItemType directory -Path $PSScriptRoot\out
    New-Item -ItemType directory -Path $PSScriptRoot\out\GarminConnect

    Copy-Item -Path "$PSScriptRoot\src\GarminConnect.psd1" -Destination "$PSScriptRoot\out\GarminConnect\" -Force
    Copy-Item -Path "$PSScriptRoot\src\GarminConnect.psm1" -Destination "$PSScriptRoot\out\GarminConnect\" -Force -Recurse

}

# The default task is to run the entire CI build
task . Package