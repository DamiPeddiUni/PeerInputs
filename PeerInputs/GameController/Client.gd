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

var isDemo = true
var udp := PacketPeerUDP.new()
var connected = false
onready var pingTime = OS.get_ticks_msec() 
var prevCmd = "cmd:"


enum enumState { state_notPressed,state_justPressed,state_pressed,state_released}
 
var buttonA   = enumState.state_notPressed
var buttonB   = enumState.state_notPressed
var bigButtonState = enumState.state_notPressed
var startBigButtonPressedTime


var quadrantVibrationTime : int = 40
var oldQuadrant = -1
var ipAddress = "192.168.1.68"

func _ready():
	Joystick_PANEL.set_visible(false);
	Buttons_PANEL.set_visible(false);
	BigButton_PANEL.set_visible(false);
	Connect_PANEL.set_visible(true);

func _process(delta):
	sendData();
	checkForMessages()
	checkServerAlive()
	
func _on_ConnectBtn_pressed():
	
	udp.connect_to_host(textEdit.text, 4242)
	if !connected:
		# Try to contact server
		udp.put_packet("Connection request".to_utf8())
		yield(get_tree().create_timer(0.5), "timeout")

		if udp.get_available_packet_count() > 0 or isDemo:
			myID = udp.get_packet().get_string_from_utf8()
			ipAddress = textEdit.text
			print("Connected to the server: %s" % myID)
			connected = true
			pingTime = OS.get_ticks_msec() 
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
	get_tree().reload_current_scene();
	print(ipAddress)
	textEdit.set_text(ipAddress)
	

func checkServerAlive():
	if (connected):
		var timeNow = OS.get_ticks_msec()
		if (timeNow - pingTime> 10000):
			print("SERVER DISCONNECTED!")
			disconnectClient()
		
		
func checkForMessages():
	if udp.get_available_packet_count() > 0:
		var msg = udp.get_packet().get_string_from_utf8()
		print("received: %s" % msg)
		if msg == "ping":
			pingTime = OS.get_ticks_msec() 			
		if msg == "vibrate":
			Input.vibrate_handheld(200)

func sendData():
	
	if !connected:
		return;
	
	var data = joystick.get_value()

	handleVibration(data)
	var stringCmd = "cmd:" + var2str(data) + ":"+ var2str(bigButtonState)

	if ( prevCmd != stringCmd ):
		udp.put_packet(stringCmd.to_utf8())
		prevCmd = stringCmd
	oldSentPos = data;
	

func handleVibration(data):
	if (oldSentPos != data):
		var quadrant = computeQuadrant(data)
		if quadrant != oldQuadrant:
			Input.vibrate_handheld(quadrantVibrationTime)
			print("vibrate" + str(quadrant))
		oldQuadrant = quadrant

func computeQuadrant(data):
	var angles =  [ -PI, -0.75*PI, - PI/2,  -PI/4,  0, PI/4, PI/2, 0.75*PI ]
	 
	var angle = atan2(data[1],data[0])

	var q = 0
	for i in angles:
		if angle > i:
			q+=1	
	return q
	
	
func _on_A_Button_pressed():
	buttonA = enumState.state_pressed

func _on_B_Button_pressed():
	buttonB = enumState.state_pressed

func _on_RefreshBtn_pressed():
	udp.put_packet("disconnect:".to_utf8())
	disconnectClient();
	
	
func _on_BigBtn_pressed():
	startBigButtonPressedTime = OS.get_ticks_msec()
	if (bigButtonState == enumState.state_justPressed):
		bigButtonState = enumState.state_pressed
	else:
		bigButtonState = enumState.state_justPressed

func _on_BigBtn_released():
	bigButtonState = enumState.state_released
	var releaseTime = OS.get_ticks_msec()
	var vibrateFor = min(releaseTime - startBigButtonPressedTime, 500)
	print("vibrateFor" + str(vibrateFor))
	Input.vibrate_handheld(vibrateFor)
	 
