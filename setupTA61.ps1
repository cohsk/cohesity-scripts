#Added this bit of script to restart the physical centos vm
#because sometimes it has an undocumented feature where it
#kicks one of the filesystems into a read-only mode
#which causes the protection job to fail

#Install the VMware PowerCLI module
Install-Module -Name "VMware.PowerCLI"

#Connect to VCenter
Connect-VIServer -Server "vcenter-01.talabs.local" -User "Administrator@vsphere.local" -Password "TechAccel1!"

#Restart "centos-physical" because sometimes the file system starts up as read-only
Get-VM "centos-physical" | Restart-VMGuest

#Sleep for 2 minutes while the vm restarts
start-sleep -Seconds 120

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

#Cancel the Physical Protection job
#This line is for the undocumented feature fix
Stop-CohesityProtectionJob -Name "Physical"
#End fix

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
$target = New-Object 'Cohesity.Model.ReplicationTargetSettings' -ArgumentList $rcluster.clusterId, cohesity-02
$reppol = New-Object 'Cohesity.Model.SnapshotReplicationCopyPolicy' -ArgumentList $true, 95, 1, KEvery, $target
$pol.snapshotReplicationCopyPolicies = $reppol
$pol | Set-CohesityProtectionPolicy

## Updated June 2019 with the 1.0.11 release of the Cohesity PowerShell support to launch jobs with Replication

#Run the Physical Protection Job Now
$myJob = Get-CohesityProtectionJob -Names Physical
$myArch = New-Object 'Cohesity.Model.ArchivalExternalTarget' -ArgumentList $null, $null, $null
$snaptarget = New-Object 'Cohesity.Model.RunJobSnapshotTarget' -ArgumentList $myArch, $null, $null, $target, kRemote
Start-CohesityProtectionJob -Id $myJob.Id -RunType KRegular -CopyRunTargets $snaptarget

#Run the Virtual Protection Job Now
$myJob = Get-CohesityProtectionJob -Names Virtual
Start-CohesityProtectionJob -Id $myJob.Id -RunType KRegular -CopyRunTargets $snaptarget

Disconnect-CohesityCluster
