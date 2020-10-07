# Export settings as environment variables to make it available in the compose file
Write-Host "Reading Configuration..."
$regex = "^E_?" #Only settings starting with "E_" needs to be exported as environment variables
foreach ($line in Get-Content .\configuration.env) { #read configuration.env
    if ($line -match $regex) {
        $arr = $line.Split("=") #separate settingname from setting value
        $setting = $arr[0]
        $value = $arr[1]
        Set-Item -Path Env:$setting -Value $value
    }
}

Set-Item -Path Env:E_IntellixImageVersion -Value 2
Set-Item -Path Env:E_SolRImageVersion -Value 8
