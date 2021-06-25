param(
    [string] $applicationPrefix = "intellix-v2"
)

$temp = $env:TEMP

# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Install WebPiCmd
Invoke-WebRequest 'https://download.microsoft.com/download/8/4/9/849DBCF2-DFD9-49F5-9A19-9AEE5B29341A/WebPlatformInstaller_x64_en-US.msi' -OutFile $temp/WebPlatformInstaller_x64_en-US.msi
Start-Process $temp/WebPlatformInstaller_x64_en-US.msi '/qn' -PassThru | Wait-Process

# Install ARR
& $Env:Programfiles'\Microsoft\Web Platform Installer\WebpiCmd.exe' /Install /Products:'UrlRewrite2' /AcceptEULA /Log:$temp/WebpiCmd_UrlRewrite.log
& $Env:Programfiles'\Microsoft\Web Platform Installer\WebpiCmd.exe' /Install /Products:'ARRv3_0' /AcceptEULA /Log:$temp/WebpiCmd_ARR.log

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
