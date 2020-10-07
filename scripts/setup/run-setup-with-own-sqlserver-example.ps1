./setup-intellix.ps1 `
    -LicenseFile '../../licenses/Peters Engineering_Enterprise.lic' `
    -IntellixAdminUser intellix `
    -IntellixAdminPassword fnmfhh34hsd7!kdj9eekdekwi!jdflj1Kdgfglj `
    -IntellixDbUser intellix `
    -IntellixDbPassword dfdfdf45de_34!sd+wexere435d435 `
    -SqlServerInstance "Chw-Win2019-Sql2019" `
    -SqlServerInstanceUser "sa" `
    -SqlServerInstancePassword "Admin001"

Write-Output "Starting Intellix..."
docker-compose -f run/docker-compose.yml up --remove-orphans
#echo "Intellix is ready to use!"
