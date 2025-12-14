import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'River Cleaning Boat',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BluetoothControlPage(),
    );
  }
}

class BluetoothControlPage extends StatefulWidget {
  const BluetoothControlPage({super.key});

  @override
  State<BluetoothControlPage> createState() => _BluetoothControlPageState();
}

class _BluetoothControlPageState extends State<BluetoothControlPage> {
  FlutterBluetoothClassic bluetooth = FlutterBluetoothClassic();
  BluetoothDevice? selectedDevice;
  List<BluetoothDevice> devices = [];
  bool isConnected = false;

  double speed = 100; // PWM speed (0-255)
  bool conveyorOn = false;

  @override
  void initState() {
    super.initState();
    getPairedDevices();
    setupListeners();
  }

  void setupListeners() {
    bluetooth.onConnectionChanged.listen((state) {
      setState(() {
        isConnected = state.isConnected;
      });
    });

    bluetooth.onDataReceived.listen((data) {
      String incoming = data.asString();
      debugPrint("Received: $incoming");
    });
  }

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> bondedDevices = await bluetooth.getPairedDevices();
    setState(() {
      devices = bondedDevices;
    });
  }

  Future<void> connect() async {
    if (selectedDevice == null) return;

    try {
      bool success = await bluetooth.connect(selectedDevice!.address);
      if (success) {
        setState(() {
          isConnected = true;
        });
      }
    } catch (e) {
      debugPrint("Connection error: $e");
    }
  }

  void sendCommand(String command) {
    if (isConnected) {
      bluetooth.sendString(command);
    }
  }

  void sendSpeed(int pwmValue) {
    if (isConnected) {
      String cmd = "SPEED$pwmValue"; // Arduino reads as SPEED<value>
      bluetooth.sendString(cmd);
    }
  }

  void toggleConveyor() {
    conveyorOn = !conveyorOn;
    sendCommand(conveyorOn ? "C" : "D"); // C=Conveyor ON, D=OFF
    setState(() {});
  }

  void disconnect() {
    bluetooth.disconnect();
    setState(() {
      isConnected = false;
    });
  }

  Widget buildControlButton(String label, String command, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(100, 50),
      ),
      onPressed: () => sendCommand(command),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("River Cleaning Boat"),
        actions: [
          IconButton(
            icon: Icon(isConnected ? Icons.link_off : Icons.bluetooth),
            onPressed: isConnected ? disconnect : connect,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<BluetoothDevice>(
              hint: const Text("Select Bluetooth Device"),
              value: selectedDevice,
              isExpanded: true,
              items: devices
                  .map(
                    (device) => DropdownMenuItem(
                      value: device,
                      child: Text(device.name ?? device.address),
                    ),
                  )
                  .toList(),
              onChanged: (device) {
                setState(() {
                  selectedDevice = device;
                });
              },
            ),
            const SizedBox(height: 10),
            Text(
              isConnected ? "Status: Connected" : "Status: Disconnected",
              style: TextStyle(
                color: isConnected ? Colors.green : Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Speed slider (Web-safe)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Speed"),
                Expanded(
                  child: Slider(
                    value: speed,
                    min: 0,
                    max: 255,
                    divisions: 25,
                    label: speed.toInt().toString(), // <- Fixed for Web
                    onChanged: (value) {
                      setState(() {
                        speed = value;
                        sendSpeed(speed.toInt());
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Movement Buttons
            buildControlButton("Forward", "F", Colors.green),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildControlButton("Left", "L", Colors.blue),
                buildControlButton("Right", "R", Colors.blue),
              ],
            ),
            buildControlButton("Backward", "B", Colors.green),
            const SizedBox(height: 20),
            buildControlButton("STOP", "S", Colors.red),
            const SizedBox(height: 20),

            // Conveyor Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: conveyorOn ? Colors.orange : Colors.grey,
                    minimumSize: const Size(120, 50),
                  ),
                  onPressed: toggleConveyor,
                  child: Text(conveyorOn ? "Conveyor ON" : "Conveyor OFF"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
