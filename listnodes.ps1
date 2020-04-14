#List nodes
#Use Brian's library
#used with Brian's standard sharing policy
#github.com/bseltz-cohesity/scripts/master/powershell

# Download Commands
$repoURL = 'https://raw.githubusercontent.com/bseltz-cohesity/scripts/master/powershell'
(Invoke-WebRequest -Uri "$repoUrl/cohesity-api/cohesity-api.ps1").content | Out-File cohesity-api.ps1; (Get-Content cohesity-api.ps1) | Set-Content cohesity-api.ps1
# End Download Commands

#dot the command directory
. ./cohesity-api.ps1

#authenticate to the cluster
apiauth -vip 172.16.3.101 -username admin -password admin

$nodes = api get nodes
$nodes | ft
