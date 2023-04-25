param(
    [string] $applicationPrefix = "intellix-v2"
)

$temp = $env:TEMP

# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Install ARR
# Download URL Rewrite
curl.exe -L 'https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi' -o "$($env:TEMP)/rewrite_amd64_en-US.msi"
# Download ARR3
curl.exe -L 'https://go.microsoft.com/fwlink/?LinkID=615136' -o "$($env:TEMP)/requestRouter_amd64.msi"

Start-Process "$($env:TEMP)/rewrite_amd64_en-US.msi" '/qn' -PassThru | Wait-Process
Start-Process "$($env:TEMP)/requestRouter_amd64.msi" '/qn' -PassThru | Wait-Process

# Create server farm in IIS
& $Env:WinDir\system32\inetsrv\appcmd.exe set config -section:webFarms /+"[name='Intellix']" /commit:apphost
& $Env:WinDir\system32\inetsrv\appcmd.exe set config -section:webFarms /+"[name='Intellix'].[address='localhost']" /commit:apphost
& $Env:WinDir\system32\inetsrv\appcmd.exe set config -section:webFarms -"[name='Intellix'].[address='localhost'].applicationRequestRouting.httpPort:8080" /commit:apphost

# Create URL Rewrite Rule in IIS
& $Env:WinDir\system32\inetsrv\appcmd.exe set config -section:system.webServer/rewrite/globalRules /+"[name='ARR_Intellix_loadbalance', patternSyntax='Wildcard',stopProcessing='True']" /commit:apphost

if ($applicationPrefix -eq "") {
    & $Env:WinDir\system32\inetsrv\appcmd.exe set config -section:system.webServer/rewrite/globalRules /"[name='ARR_Intellix_loadbalance',patternSyntax='Wildcard',stopProcessing='True']".match.url:"*"  /commit:apphost
}
else {
    if ($applicationPrefix.StartsWith("/")) {
        $applicationPrefix = $applicationPrefix.Substring(1)
    }
    & $Env:WinDir\system32\inetsrv\appcmd.exe set config -section:system.webServer/rewrite/globalRules /"[name='ARR_Intellix_loadbalance',patternSyntax='Wildcard',stopProcessing='True']".match.url:"$applicationPrefix*"  /commit:apphost
}
& $Env:WinDir\system32\inetsrv\appcmd.exe set config -section:system.webServer/rewrite/globalRules /"[name='ARR_Intellix_loadbalance',patternSyntax='Wildcard',stopProcessing='True']".action.type:"Rewrite" /"[name='ARR_Intellix_loadbalance',patternSyntax='Wildcard',stopProcessing='True']".action.url:"http://Intellix/{R:0}"  /commit:apphost
