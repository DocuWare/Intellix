Set-Location $PSScriptRoot

./setup/Setup-Intellix.ps1 `
    -LicenseFile 'c:\users\Administrator\Downloads\Peters Engineering_Enterprise.lic' `
    -IntellixAdminUser intellix `
    -IntellixAdminPassword fnmfhh34hsd7!kdj9eekdekwi!jdflj1Kdgfglj `
    -IntellixDbUser intellix `
    -IntellixDbPassword dfdfdf45de_34!sd+wexere435d435 `
    -SqlServerInstance "Chw-Win2019-Sql2019" `
    -SqlServerInstanceUser "sa" `
    -SqlServerInstancePassword "Admin001"

./Start-Intellix
