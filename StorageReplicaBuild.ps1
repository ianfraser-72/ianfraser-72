# Build Storage Replica servers via Ansible
# Passes TaskType vriable to the script for the Test, Build and Remove phases, and diskcheck and statecheck.

param
(
[switch]$sourceserver,
[switch]$sourcedatavol,
[switch]$sourcelogvol,
[switch]$sourcerg,
[switch]$destserver,
[switch]$destdatavol,
[switch]$destlogvol,
[switch]$destrg,
[switch]$task

)

If ($task -eq "Build")
{
  New-SRPartnership -SourceComputerName $sourceserver -SourceRGName $sourcerg -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationRGName $destrg -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":"
}

if ($task -eq "Test")
{
  Test-SRTopology -SourceComputerName $sourceserver -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":" -DurationInMinutes 5 -ResultPath c:\temp -verbose
}

if ($task -eq "Remove")
{
  Remove-SRPartnership -SourceComputerName $sourceserver -SourceRGName $sourcerg -DestinationComputerName $destserver -DestinationRGName $destrg
}

if ($task -eq "diskcheck")
{
  $destserver = $args[0]
  $serverdatavol = $args[1]
  try 
  {
    net use t: \\$destserver\$serverdatavol"`$"
    write-host "Performed check - Storage Replica not currently installed so can install"
  }
  catch 
  {
    write-host "Replica already installed."
  }
}

if ($task -eq "statecheck")
{
   $state = get-windowsfeature stor*
   if ($state.name -match "Storage-Replica")
   {
   write-host "Storage Replica Installed"
   Exit 0
   }
else
   {
   write-host "Storage Replica not Installed"
   Exit 2
   }
}
