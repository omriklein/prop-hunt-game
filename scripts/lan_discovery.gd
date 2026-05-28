extends Node

const DISCOVERY_PORT := 7778
const BROADCAST_INTERVAL := 1.0
const  HOST_EXPIRY_MS := 3000 # remove host if not seen in 3s

var _broadcast_peer: PacketPeerUDP
var _listen_server: UDPServer
var _broadcast_timer := 0.0

var discovered_hosts: Array = [] # {ip, name, last_seen}

func _process(delta: float) -> void:
	_poll_listener()
	if _broadcast_peer:
		_broadcast_timer += delta
		if _broadcast_timer >= BROADCAST_INTERVAL:
			_broadcast_timer = 0.0
			_send_broadcast()
	_remove_stale_hosts()

### host functions

func start_host(host_name: String) -> void:
	_broadcast_peer = PacketPeerUDP.new()
	_broadcast_peer.set_broadcast_enabled(true)
	_broadcast_peer.bind(0)
	_broadcast_timer = BROADCAST_INTERVAL # fire immediately

func stop_host() -> void:
	if _broadcast_peer:
		_broadcast_peer.close()
		_broadcast_peer = null

func _send_broadcast() -> void:
	var payload := JSON.stringify({"name": PlayerData.player_name, "port": 777})
	_broadcast_peer.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	_broadcast_peer.put_packet(payload.to_utf8_buffer())

### client functions

func start_listening() -> void:
	_listen_server = UDPServer.new()
	_listen_server.listen(DISCOVERY_PORT)

func stop_listening() -> void:
	if _listen_server:
		_listen_server.stop()
		_listen_server = null
	discovered_hosts.clear()

func _poll_listener() -> void:
	if not _listen_server:
		return
	_listen_server.poll()
	while _listen_server.is_connection_available():
		var conn: PacketPeerUDP = _listen_server.take_connection()
		while conn.get_available_packet_count() > 0:
			var raw := conn.get_packet()
			var ip := conn.get_packet_ip()
			var text := raw.get_string_from_utf8()
			var parsed = JSON.parse_string(text)
			if parsed is Dictionary and parsed.has("name"):
				_update_host(ip, parsed["name"])

func _update_host(ip: String, name: String) -> void:
	for entry in discovered_hosts:
		if entry["ip"] == ip:
			entry["name"] = name
			entry["last_seen"] = Time.get_ticks_msec()
			return
	discovered_hosts.append({"ip": ip, "name": name, "last_seen": Time.get_ticks_msec()})

func _remove_stale_hosts() -> void:
	var now := Time.get_ticks_msec()
	discovered_hosts = discovered_hosts.filter(func(h): return now - h["last_seen"] < HOST_EXPIRY_MS)
