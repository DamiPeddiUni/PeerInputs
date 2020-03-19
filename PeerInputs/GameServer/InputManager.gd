extends Node

onready var p1 = get_parent().get_node("P1");
onready var p2 = get_parent().get_node("P2");

var players = [0, 0]; #lo zero rappresenta un posto libero.
var velocity = [Vector2.ZERO, Vector2.ZERO];



func _ready():
	var network = NetworkedMultiplayerENet.new();
	network.create_server(4242, 2); #2 è il numero di giocatori
	get_tree().set_network_peer(network);
	
	network.connect("peer_connected", self, "_peer_connected");
	network.connect("peer_disconnected", self, "_peer_disconnected");
	
	print("IP:", IP.get_local_addresses()[7])
	
func _process(delta):
	#print (players);
	p1.position += velocity[0] * delta * 80;
	p2.position += velocity[1] * delta * 80;

func _peer_connected(id):
	var freePlace = players.find(0);
	players[freePlace] = str(id);
	velocity[freePlace] = Vector2.ZERO;
	print(str(id) + " connected");
	print(str(get_tree().get_network_connected_peers().size()) + " peers connected");
	var welcome_text = str(id);
	get_tree().multiplayer.send_bytes(welcome_text.to_ascii());

func _peer_disconnected(id):
	var place = players.find(str(id));
	players[place] = 0;
	velocity[place] = Vector2.ZERO;
	print(str(id) + " disconnected");
	print(str(get_tree().get_network_connected_peers().size()) + " peers connected");

remote func receive_call(id, data):
	#print("listening from: " + str(players.find(str(id))));
	velocity[players.find(str(id))] = data;
	
		
