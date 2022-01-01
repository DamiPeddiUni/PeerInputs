extends Node

var velocity = Vector2.ZERO;

var oldSentPos = Vector2.ZERO;
var myID = "";

onready var joystick = get_parent().get_node("CanvasLayer/JoyPad/joystick/joystick_button");
onready var textEdit = get_parent().get_node("CanvasLayer/ConnectPanel/TextEdit");
onready var Joystick_PANEL = get_parent().get_node("CanvasLayer/JoyPad");
onready var Buttons_PANEL = get_parent().get_node("CanvasLayer/AB_Buttons");
onready var Connect_PANEL = get_parent().get_node("CanvasLayer/ConnectPanel");
onready var BigButton_PANEL = get_parent().get_node("CanvasLayer/BigBtn");

signal connected


var udp := PacketPeerUDP.new()
var connected = false

var noInput = "0" 
var justPressed = "1"
var pressed = "2"
var justReleased = "3"
var prevCmd = "cmd:"
 
var buttonA  = noInput
var buttonB  = noInput
var bigButton = noInput
var startBigButtonPressedTime
var quadrantVibrationTime : int = 40
var oldQuadrant = -1
var ipAddress

func _ready():
	Joystick_PANEL.set_visible(false);
	Buttons_PANEL.set_visible(false);
	BigButton_PANEL.set_visible(false);
	Connect_PANEL.set_visible(true);

	
func _process(delta):
	send_stuff(joystick.get_value());
	
func _on_ConnectBtn_pressed():
	
	udp.connect_to_host(textEdit.text, 4242)
	if !connected:
		# Try to contact server
		udp.put_packet("Connection request".to_utf8())
		yield(get_tree().create_timer(0.5), "timeout")

		if udp.get_available_packet_count() > 0:
			myID = udp.get_packet().get_string_from_utf8()
			ipAddress = textEdit.text
			print("Connected to the server: %s" % myID)
			connected = true
			emit_signal("connected")
			Joystick_PANEL.set_visible(true);
			Buttons_PANEL.set_visible(false);
			BigButton_PANEL.set_visible(true);
			Connect_PANEL.set_visible(false);	 
			print(myID);
		else:
			print("server not found")
 
func disconnectClient():
	connected = false  
	pass

func send_stuff(data):
	
	if !connected:
		return;
	
	
#	if data[0] > thres:
#		if oldSentPos[0] < thres and oldSentPos[0] > -thres:
#			stringCmd += justPressed	
#		else:
#			stringCmd += pressed
#	elif data[0] < thres and data[0] > -thres  and oldSentPos[0] > thres:
#		stringCmd += justReleased
#	else:
#		stringCmd += noInput
#
#	if data[0] < -thres:
#		if oldSentPos[0] < thres and oldSentPos[0] > -thres:
#			stringCmd += justPressed	
#		else:
#			stringCmd += pressed
#	elif data[0] < thres and data[0] > -thres  and oldSentPos[0] < -thres:
#		stringCmd += justReleased
#	else:
#		stringCmd += noInput
#
#	if data[1] > thres:
#		if oldSentPos[1] < thres and oldSentPos[1] > -thres:
#			stringCmd += justPressed	
#		else:
#			stringCmd += pressed
#	elif data[1] < thres and data[1] > -thres  and oldSentPos[1] > thres:
#		stringCmd += justReleased
#	else:
#		stringCmd += noInput
#
#	if data[1] < -thres:
#		if oldSentPos[1] < thres and oldSentPos[1] > -thres:
#			stringCmd += justPressed	
#		else:
#			stringCmd += pressed
#	elif data[1] < thres and data[1] > -thres  and oldSentPos[1] < -thres:
#		stringCmd += justReleased
#	else:
#		stringCmd += noInput
#
	handleVibration(data)
	
#
	var stringCmd = "cmd:" + var2str(data) + ":"+ bigButton
	
	
#	stringCmd += bigButton
	
	#print(data)
	if ( prevCmd != stringCmd ):
		udp.put_packet(stringCmd.to_utf8())
		prevCmd = stringCmd
		
	#	print(stringCmd)
	oldSentPos = data;

func handleVibration(data):
	if (oldSentPos != data):
		var quadrant = computeQuadrant(data)
		if quadrant != oldQuadrant:
			Input.vibrate_handheld(quadrantVibrationTime)
			print("vibrate" + str(quadrant))
		oldQuadrant = quadrant

func computeQuadrant(data):
	#var angles = [0, PI/4, PI/2 , 3/4*PI , PI,  5/4*PI, 6/4*PI, 7/4*PI, 2*PI ]
	var angles =  [ -PI, -3/4*PI, - PI/2,  -PI/4,  0, PI/4, PI/2, 3/4*PI ]
	
	var angle = atan2(data[1],data[0])
#	print(angle)
#	if (data[1] < 0):
#		angle += PI
	
	var q = 0
	for i in angles:
		if angle > i:
			q+=1	
	return q
	
	
func _on_A_Button_pressed():
	buttonA = pressed

func _on_B_Button_pressed():
	buttonB = pressed

func _on_RefreshBtn_pressed():
	disconnectClient();
	get_tree().reload_current_scene();
	print(ipAddress)
	#textEdit.text = ipAddress
	#yield(get_tree().create_timer(0.5), "timeout")
	
	textEdit.append_at_cursor(ipAddress)
	

func _on_BigBtn_pressed():
	#OS.vibrate_handheld(500)
	startBigButtonPressedTime = OS.get_ticks_msec()
	if (bigButton == justPressed):
		bigButton = pressed
		
	else:
		bigButton = justPressed

func _on_BigBtn_released():
	bigButton = justReleased
	var releaseTime = OS.get_ticks_msec()
	var vibrateFor = min(releaseTime - startBigButtonPressedTime, 500)
	print("vibrateFor" + str(vibrateFor))
	Input.vibrate_handheld(vibrateFor)
	 
