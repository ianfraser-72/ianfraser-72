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

If ($task -eq "Build")
{

$sourcedatavol1 = $sourcedatavol -join ","
$destdatavol1 = $destdatavol -join ","

$tempstring = "new-srpartnership -SourceComputerName $sourceserver -SourceRGName `"$sourcerg`" -SourceVolumeName $sourcedatavol1 -SourceLogVolumeName $sourcelogvol -DestinationComputerName $destserver -DestinationRGName `"$destrg`" -DestinationVolumeName $destdatavol1 -DestinationLogVolumeName $destlogvol -enableencryption"
write-host $tempstring
invoke-expression $tempstring
}

if ($task -eq "Test")
{
  if (!(get-srpartnership))	
  {  
  $run = Test-SRTopology -SourceComputerName $sourceserver -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":" -DurationInMinutes 5 -ResultPath c:\temp -verbose
  }
  try
  {
  Write-host "Test successful. `r`n`r`n$run"
  }
  catch
  {
   Write-host "Replica failover failed. `r`n`r`n$run"
  }
}

if ($task -eq "RemoveService")
{
  $tempstring = "Remove-SRPartnership -SourceComputerName $sourceserver -SourceRGName `"$sourcerg`" -DestinationComputerName $destserver -DestinationRGName `"$destrg`"  -force"
  write-host $tempstring
  invoke-expression $tempstring
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
  }
  if ($run.ReplicationStatus -match "ConnectingtoSource")
  {
   write-host "Replication Status is $($run.ReplicationStatus) for Replication group $($run.name)"
   Write-host "This will cause data loss"
  }
  
}

if ($task -eq "statecheck")
{
   $state = get-windowsfeature stor*
   if ($state.name -match "Storage-Replica")
   {
   write-output "Storage Replica is Installed"
   Exit 0
   }
else
   {
   write-output "Storage Replica is not Installed"
   Exit 2
   }
}
