# Test Storage-Replica connectivity

$sourceserver = $args[0]
$sourcedatavol = $args[1]
$sourcelogvol = $args[2]
$destserver = $args[3]
$destdatavol = $args[4]
$destlogvol = $args[5]

Test-SRTopology -SourceComputerName $sourceserver -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":" -DurationInMinutes 5 -ResultPath c:\temp
