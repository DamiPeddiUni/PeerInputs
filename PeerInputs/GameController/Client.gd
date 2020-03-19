extends Node

var velocity = Vector2.ZERO;

var oldSentStuff = Vector2.ZERO;
var myID = "";

onready var joystick = get_node("CanvasLayer/JoyPad/joystick/joystick_button");

func _ready():
	pass
	
func _process(delta):
	send_stuff(joystick.get_value());
	
func _on_ConnectBtn_pressed():
	var network = NetworkedMultiplayerENet.new();
	network.create_client($CanvasLayer/TextEdit.text, 4242);
	get_tree().set_network_peer(network);
	network.connect("connection_failed", self, "_on_connection_failed");
	network.connect("peer_disconnected", self, "_on_disconnected");
	#$CanvasLayer/ConnectBtn.set_disabled(true);
	get_tree().multiplayer.connect("network_peer_packet", self, "_on_packet_received");
	myID = get_tree().get_network_unique_id();
	print(myID);
	
	
func _on_connection_failed(error):
	$CanvasLayer/ConnectBtn.set_disabled(false);
	print(error);

func _on_packet_received(id, packet):
	#myID = packet.get_string_from_ascii();
	pass
	
func disconnectClient():
	get_tree().set_network_peer(null);

func _on_disconnected():
	$CanvasLayer/ConnectBtn.set_disabled(false);

func send_stuff(data):
	if get_tree().get_network_peer() == null || data == oldSentStuff:
		return;
	oldSentStuff = data;
	rpc_unreliable_id(1, "receive_call", myID, data);
	
