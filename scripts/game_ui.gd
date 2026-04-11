extends Node3D

@onready var ip_label: Label = $InfoDisplay/IPLabel

func _ready():
	if multiplayer.is_server():
		broadcast_host_ip.rpc(NetworkManager.host_ip)

@rpc("authority", "call_local", "reliable")
func broadcast_host_ip(ip: String):
	ip_label.text = "Game IP: " + ip
