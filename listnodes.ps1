#List nodes

#Make sure we have the latest Cohesity Module
Update-Module -Name “Cohesity.PowerShell”

#setup credentials
$username = "admin"
$password = "admin"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr

#Connect to Cluster 1
Connect-CohesityCluster -Server 172.16.3.101 -Credential ($cred)
$nodelist = 

Disconnect-CohesityCluster
