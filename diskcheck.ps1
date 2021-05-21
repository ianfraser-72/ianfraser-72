$destserver = $args[0]
$serverdatavol = $args[1]

net use t: \\$destserver\$serverdatavol"`$"
