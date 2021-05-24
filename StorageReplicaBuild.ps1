# Build Storage Replica servers via Ansible
# Passes TaskType vriable to the script for the Test, Build and Remove phases, and diskcheck and statecheck.

param
(
[string]$sourceserver,
[string]$sourcedatavol,
[string]$sourcelogvol,
[string]$sourcerg,
[string]$destserver,
[string]$destdatavol,
[string]$destlogvol,
[string]$destrg,
[string]$task
)


function DiskCheck
{
$a = New-PSDrive -Name "Public" -PSProvider "FileSystem" -Root "\\ansclient02\e$"
#net use t: \\$destserver\$serverdatavol"`$"
#write-output "Performed check - Storage Replica not currently installed so can install"
write-host $a
pause
return $a
}

If ($task -eq "Build")
{
  New-SRPartnership -SourceComputerName $sourceserver -SourceRGName $sourcerg -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationRGName $destrg -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":"
}

if ($task -eq "Test")
{
  $b = DiskCheck
  write-host $b
  Test-SRTopology -SourceComputerName $sourceserver -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":" -DurationInMinutes 5 -ResultPath c:\temp -verbose
}

if ($task -eq "Remove")
{
  Remove-SRPartnership -SourceComputerName $sourceserver -SourceRGName $sourcerg -DestinationComputerName $destserver -DestinationRGName $destrg
}

if ($task -eq "statecheck")
{
   $state = get-windowsfeature stor*
   if ($state.name -match "Storage-Replica")
   {
   write-output "Storage Replica Installed"
   Exit 0
   }
else
   {
   write-output "Storage Replica not Installed"
   Exit 2
   }
}
