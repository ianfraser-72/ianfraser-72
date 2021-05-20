$source = $args[0]
$destination = $args[1]
Test-SRTopology -SourceComputerName $source -SourceVolumeName E: -SourceLogVolumeName G: -DestinationComputerName $destination -DestinationVolumeName E: -DestinationLogVolumeName G: -DurationInMinutes 5 -ResultPath c:\temp –verbose
