# Build Storage Replicas

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
