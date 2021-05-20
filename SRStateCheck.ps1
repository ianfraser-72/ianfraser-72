state = get-windowsfeature storage*
$state .name
if ($state .name -match "Storage-Replica")
{
write-host "Replica Installed"
Exit 0
}
else
{
Exit 2
}
