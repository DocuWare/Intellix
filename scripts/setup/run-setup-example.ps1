./setup-intellix.ps1 -LicenseFile '../../licenses/Peters Engineering_Enterprise.lic' -IntellixAdminUser intellix -IntellixAdminPassword Admin001 -IntellixDbUser intellix -IntellixDbPassword Admin001

Write-Output "Starting Intellix..."
docker-compose -f run/docker-compose.yml up --remove-orphans
#echo "Intellix is ready to use!"
