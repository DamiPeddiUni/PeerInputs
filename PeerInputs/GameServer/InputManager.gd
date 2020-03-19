extends Node

export (PackedScene)var player;

var players = [0, 0]; #lo zero rappresenta un posto libero. Aggiungere slot qui se vuoi più player
var players_node = [null, null]; #aggiungere slot anche qui
var velocity = [Vector2.ZERO, Vector2.ZERO]; # aggiungere anche qui



func _ready():
	var network = NetworkedMultiplayerENet.new();
	network.create_server(4242, 2); #2 è il numero di giocatori
	get_tree().set_network_peer(network);
	
	network.connect("peer_connected", self, "_peer_connected");
	network.connect("peer_disconnected", self, "_peer_disconnected");
	
	print("IP:", IP.get_local_addresses())
	
func _process(delta):
	pass

func _peer_connected(id):
	#inizializzo il player
	var freePlace = players.find(0);
	players[freePlace] = str(id);
	velocity[freePlace] = Vector2.ZERO; 
	#instanzio il player
	var p = player.instance();
	p.position = Vector2(200, 200);
	p.player_id = str(id);
	players_node[freePlace] = p;
	get_parent().add_child(p);
	#debug
	print(str(id) + " connected");
	print(str(get_tree().get_network_connected_peers().size()) + " peers connected");
	#restituisco al player il suo id per conferma di connessione al server
	var welcome_text = str(id);
	get_tree().multiplayer.send_bytes(welcome_text.to_ascii());

func _peer_disconnected(id):
	#trovo il suo spazio e lo resetto, per permettere nuove connessioni al suo posto
	var place = get_index_from_id(id);
	players[place] = 0;
	velocity[place] = Vector2.ZERO;
	players_node[place].queue_free();
	players_node[place] = null;
	#debug
	print(str(id) + " disconnected");
	print(str(get_tree().get_network_connected_peers().size()) + " peers connected");

func get_index_from_id(id):
	return players.find(str(id)); #restituisce la posizione nell'array in base all'id
	
remote func receive_position(id, data):
	#print("listening from: " + str(players.find(str(id))));
	velocity[get_index_from_id(id)] = data; #salvo la velocity
	for p in players_node:
		if p != null:
			p.velocity = velocity[get_index_from_id(p.player_id)] #la mando solo una volta al player corretto
	

remote func receive_button_input(id, data): #questa funzione ascolta per A e B
	pass

remote func receive_big_button_input(id, data): #questa funzione ascolta per il bottone grosso
	pass
