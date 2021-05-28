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
  $tempstring = $sourcedatavol -split ","
  foreach ($item in $tempstring)
  {
  $newstring += $item  + ":`"`,`""
  }
  $sourcedatavol = "`"" + $newstring.substring(0,$newstring.length-2)
  $destdatavol = "`"" + $newstring.substring(0,$newstring.length-2)

  New-SRPartnership -SourceComputerName $sourceserver -SourceRGName $sourcerg -SourceVolumeName $sourcedatavol -SourceLogVolumeName $sourcelogvol -DestinationComputerName $destserver -DestinationRGName $destrg -DestinationVolumeName $destdatavol -DestinationLogVolumeName $destlogvol

}

if ($task -eq "Test")
{
  if (!(get-srpartnership))
  {  
  Test-SRTopology -SourceComputerName $sourceserver -SourceVolumeName $sourcedatavol":" -SourceLogVolumeName $sourcelogvol":" -DestinationComputerName $destserver -DestinationVolumeName $destdatavol":" -DestinationLogVolumeName $destlogvol":" -DurationInMinutes 5 -ResultPath c:\temp -verbose
  }
}

if ($task -eq "RemoveService")
{
  Remove-SRPartnership -SourceComputerName $sourceserver -SourceRGName $sourcerg -DestinationComputerName $destserver -DestinationRGName $destrg -force
}

if ($task -eq "RemoveGroups")
{
  get-srgroup | Remove-SRGroup -name {$_.name} -force
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
