# Build Storage Replicas

$sourceserver = $args[0]
$sourcedatavol = $args[1]
$sourcelogvol = $args[2]
$sourcerg = $args[3]
$destserver = $args[4]
$destdatavol = $args[5]
$destlogvol = $args[6]
$destrg = $args[7]


New-SRPartnership -SourceComputerName $sourceserver -SourceRGName $sourcerg -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationRGName $destrg -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":"

