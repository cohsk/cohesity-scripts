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
$c1ndd = Get-CohesityStorageDomain -Names sd-ndd-ncc | ConvertFrom-JSON | Select Id
$c1idd = Get-CohesityStorageDomain -Names sd-idd-icc | ConvertFrom-JSON | Select Id
Disconnect-CohesityCluster

#Connect to Cluster 2
Connect-CohesityCluster -Server 172.16.3.102 -Credential ($cred)
$c2ndd = Get-CohesityStorageDomain -Names sd-ndd-ncc | ConvertFrom-JSON | Select Id
$c2idd = Get-CohesityStorageDomain -Names sd-idd-icc | ConvertFrom-JSON | Select Id

#Register Remote Cluster 2
Register-CohesityRemoteCluster -RemoteClusterIps 172.16.3.101 -RemoteClusterCredential ($cred) -EnableReplication -EnableRemoteAccess -StorageDomainPairs @{LocalStorageDomainId=$c2ndd.id;LocalStorageDomainName=“sd-ndd-ncc”;RemoteStorageDomainId=$c1ndd.id;RemoteStorageDomainName=“sd-ndd-ncc”}, @{LocalStorageDomainId=$c2idd.id;LocalStorageDomainName=”sd-idd-icc”;RemoteStorageDomainId=$c1idd.id;RemoteStorageDomainName="sd-idd-icc"}

Disconnect-CohesityCluster

#Connect to Cluster 1
Connect-CohesityCluster -Server 172.16.3.101 -Credential ($cred)


#Register Remote Cluster 2
Register-CohesityRemoteCluster -RemoteClusterIps 172.16.3.102 -RemoteClusterCredential ($cred) -EnableReplication -EnableRemoteAccess -StorageDomainPairs @{LocalStorageDomainId=$c1ndd.id;LocalStorageDomainName=“sd-ndd-ncc”;RemoteStorageDomainId=$c2ndd.id;RemoteStorageDomainName=“sd-ndd-ncc”}, @{LocalStorageDomainId=$c1idd.id;LocalStorageDomainName=”sd-idd-icc”;RemoteStorageDomainId=$c2idd.id;RemoteStorageDomainName="sd-idd-icc"}

#Add Replication to the Bronze Protection Policy
$pol = Get-CohesityProtectionPolicy -Names Bronze
$rcluster = Get-CohesityRemoteCluster | Select ClusterId
$target = New-Object 'Cohesity.Models.ReplicationTarget_' -ArgumentList $rcluster.clusterId, cohesity-02
$reppol = New-Object 'Cohesity.Models.SnapshotReplicationCopyPolicy' -ArgumentList $true, 95, 1, KEvery, $target
$pol.snapshotReplicationCopyPolicies = $reppol
$pol | Set-CohesityProtectionPolicy

Disconnect-CohesityCluster

#To be completed - Run the Physical Protection job

#To be completed - Run the Virtual Protection job

###Extra Credit — Run the BizApps Protection part of the lab

#Get-CohesityStorageDomain

