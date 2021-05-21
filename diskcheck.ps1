$serverdatavol = $args[0]
copy-item "c:\temp\checkflag.txt" -destination $serverdatavol":\checkflag.txt"
