$state = get-windowsfeature stor*
$state.name
if ($state.name -match "Storage-Replica1")
{
write-host "Replica Installed1"
Exit 0
}
else
{
Exit 2
}
