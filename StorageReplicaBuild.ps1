# Build Storage Replica servers via Ansible
# Passes TaskType vriable to the script for the Test, Build and Remove phases, and diskcheck and statecheck.

param
(
[string]$sourceserver,
[array]$sourcedatavol,
[string]$sourcelogvol,
[string]$sourcerg,
[string]$destserver,
[array]$destdatavol,
[string]$destlogvol,
[string]$destrg,
[string]$task,
[string]$replicationmode
)

function testdisk

{
 try 
  {
    New-PSDrive -Name "A" -PSProvider "FileSystem" -Root "\\$destserver\$destdatavol$"

    if ($Error[0].Exception.Message -like "*does not exist*")
    {
      exit 2 
    }
    else
    {
      return
    }  

  }
  catch [System.IO.FileNotFoundException]
  {
   exit 2 
  }
}

function ReplicaInstallCheck
{
 $state = get-windowsfeature "Storage-Replica" | ? {$_.InstallState -eq 'Installed'}
 return $state
}

If ($task -eq "Build_Service")
{

$sourcedatavol1 = $sourcedatavol -join ","
$destdatavol1 = $destdatavol -join ","

$run = "new-srpartnership -SourceComputerName $sourceserver -SourceRGName `"$sourcerg`" -SourceVolumeName $sourcedatavol1 -SourceLogVolumeName $sourcelogvol -DestinationComputerName $destserver -DestinationRGName `"$destrg`" -DestinationVolumeName $destdatavol1 -DestinationLogVolumeName $destlogvol -enableencryption -replicationmode $replicationmode"
write-host $run
invoke-expression $run
$run
}

if ($task -eq "Check_Connectivity")
{
  
  try 
  {
  get-srpartnership
  $runcmd = $true
  }
  catch [System.Management.Automation.CommandNotFoundException]
  {
  Write-host "Test not run as Storage Replica not installed`r`n`r`n"
  $runcmd = $false
  exit 1
  }
  
  if ($runcmd -eq $true)
  {
    try
    {
      $state = Test-SRTopology -SourceComputerName $sourceserver -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":" -DurationInMinutes 1 -ResultPath c:\temp -verbose
      if (!($error))
      {
      Write-host "Test Successful`r`n`r`n"
      Test-SRTopology -GenerateReport -DataPath "C:\temp" 
      }      
    }
    catch
    {
     Write-host "Test not run as Storage Replica not installed`r`n`r`n"
    }
  }
  else
  {
    Write-host "Test not run as Storage Replica not installed`r`n`r`n"
  }
  
}

if ($task -eq "Remove_Partnership")
{
  $sourceserver1 = $sourceserver.split(".")
  $destserver1 = $destserver.split(".")
  $sourceserver2 = $sourceserver1[0]
  $destserver2 = $destserver1[0]
  try 
  {
  $runstring = "Remove-SRPartnership -SourceComputerName $sourceserver2 -SourceRGName `"$sourcerg`" -DestinationComputerName $destserver2 -DestinationRGName `"$destrg`"  -force"
  $run = invoke-expression $runstring
  Write-host "Partnership removed"
  $run
  }
  catch
  {
   Write-host "No partnership to remove`r`n`r`n"
   $run
  }
}

if ($task -eq "RemoveGroups")
{
  $run = get-srgroup | Remove-SRGroup -name {$_.name} -force
  $run
}

if ($task -eq "failover")
{
  $runstring = "Set-SRPartnership -NewSourceComputerName $sourceserver -SourceRGName `"$sourcerg`" -DestinationComputerName $destserver -DestinationRGName `"$destrg`" -force"
  $run = invoke-expression $runstring
  try
  {
  Write-host "Replica failover successful from $sourceserver to $destserver"
  }
  catch
  {
   Write-host "Replica failover failed from $sourceserver to $destserver"
  }
}

if ($task -eq "Check_Replication_Status")
{
  try
  {
  $partners = Get-SRPartnership
  write-host $partners
  }
  Catch [System.Management.Automation.CommandNotFoundException] 
  {
  write-host "Storage Replica not installed so cant check Replication Status!"
  exit 1
  }
  
  $runstring = "Get-SRGroup"
  $run = invoke-expression $runstring

  if ($run.ReplicationStatus -match "ContinuouslyReplicating")
  {
   write-host "Replication Status is $($run.ReplicationStatus) for Replication group $($run.name)"
   write-host $run
  }
  if ($run.ReplicationStatus -match "ConnectingtoSource")
  {
   write-host "Replication Status is $($run.ReplicationStatus) for Replication group $($run.name)"
   Write-host "In this instance it is critical that if the data stored on the new source server during a failing of the original source server is to be retained, certain steps must be followed.Data loss will occur if the failed server comes back online, and this is then immediately made the source server as this will then force replication and deletion from the recovered source to the destination, effectively wiping the newly stored data. To avoid this scenario, you must repeat the original failover step by running the failover online play and ensuring the newly recovered server is the destination server, not the source when updating the survey. This will ensure new data is replicated to the destination server (the original source server). You can then run the failover online play again to re-establish the original partnership order (basically now reversing the source and destination)"
   write-host $run
  }
  if ($run.ReplicationStatus -match "ReplicationSuspended")
  {
   write-host "Replication Status is $($run.ReplicationStatus) for Replication group $($run.name)"
   Write-host "Replication suspended check connectivity"
   write-host $run
  }  
   if ($run.ReplicationStatus -eq $null)
  {
   write-host "No Replication Group found, partnership not present"
   write-host $run
  }  
}

if ($task -eq "statecheck")
{
     $state = ReplicaInstallCheck
     if ($state)
     {
       write-output "Storage Replica is Installed"
       Exit 0
     }
    else
     {
       write-output "Storage Replica is not Installed"   
       Exit 0
     }
}

