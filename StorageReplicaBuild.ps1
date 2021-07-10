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
[string]$task
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

function StateCheck
{
 $state = get-windowsfeature "Storage-Replica" | ? {$_.InstallState -eq 'Installed'}
 return $state
}

If ($task -eq "Build_Service")
{

$sourcedatavol1 = $sourcedatavol -join ","
$destdatavol1 = $destdatavol -join ","

$run = "new-srpartnership -SourceComputerName $sourceserver -SourceRGName `"$sourcerg`" -SourceVolumeName $sourcedatavol1 -SourceLogVolumeName $sourcelogvol -DestinationComputerName $destserver -DestinationRGName `"$destrg`" -DestinationVolumeName $destdatavol1 -DestinationLogVolumeName $destlogvol -enableencryption"
write-host $run
invoke-expression $run
$run
}

if ($task -eq "Pre_Flight_Check")
{
  
  try 
  {
  get-srpartnership
  $runcmd = $true
  }
  catch 
  { 
  $runcmd = $false
  }
  
  if ($runcmd)
  {
    try
    {
      Test-SRTopology -SourceComputerName $sourceserver -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":" -DurationInMinutes 1 -ResultPath c:\temp -verbose
      Test-SRTopology -GenerateReport -DataPath "C:\temp" 
      Write-host "Test successful. `r`n`r`n$run"
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
  $sourceserver = $sourceserver.split(".")
  $desterver = $destserver.split(".")
  try 
  {
  $run = Remove-SRPartnership -SourceComputerName $($sourceserver[0]) -SourceRGName `"$sourcerg`" -DestinationComputerName $($destserver[0]) -DestinationRGName `"$destrg`"  -force"
  Write-host "Partnership removed`r`n`r`n"
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
  get-srgroup | Remove-SRGroup -name {$_.name} -force
}

if ($task -eq "failback_online")
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

if ($task -eq "check_replication_status")
{
  $runstring = "Get-SRGroup"
  $run = invoke-expression $runstring
  if ($run.ReplicationStatus -match "ContinuouslyReplicating")
  {
   write-host "Replication Status is $($run.ReplicationStatus) for Replication group $($run.name)"
   write-host "Output is $run"
  }
  if ($run.ReplicationStatus -match "ConnectingtoSource")
  {
   write-host "Replication Status is $($run.ReplicationStatus) for Replication group $($run.name)"
   Write-host "In this instance it is critical that if the data stored on the new source server during a failing of the original source server is to be retained, certain steps must be followed.Data loss will occur if the failed server comes back online, and this is then immediately made the source server as this will then force replication and deletion from the recovered source to the destination, effectively wiping the newly stored data. To avoid this scenario, you must repeat the original failover step by running the failover online play and ensuring the newly recovered server is the destination server, not the source when updating the survey. This will ensure new data is replicated to the destination server (the original source server). You can then run the failover online play again to re-establish the original partnership order (basically now reversing the source and destination)"
   write-host "Output is $run"
  }
  
}

if ($task -eq "statecheck")
{
     $state = StateCheck
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

