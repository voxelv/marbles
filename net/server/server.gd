extends Node



func _handle_pkt(pkt:Dictionary):
	var type := pkt.get('type', -1) as int
	if type == -1:
		return
	
	match type:
		# Command
		0:
			print("COMMAND RX")

func _send_pkt(pkt:Dictionary)->void:
	if Config.is_local:
		Config.client._handle_packet(pkt)





















