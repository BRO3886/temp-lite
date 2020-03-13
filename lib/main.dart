import 'package:flutter/material.dart';
import './widgets/thermometer_widget.dart';
import 'package:weather/weather.dart';
import 'package:mqtt_client/mqtt_client.dart';
import './widgets/temp_widget.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'TempLite'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static String broker = 'tailor.cloudmqtt.com';
  static int port = 16605;
  static String username = 'qcclcbbh';
  static String passwd = 'P3qbpKj-JDG5';
  static String clientIdentifier = 'android';

  final MqttClient mqttClient = MqttClient(broker, '');

  double _temp = 20;
  WeatherStation weatherStation =
      new WeatherStation("107d44f6ecc646f3aa795b01317da48d");
  double celsius = 20;
  void connect() async {
    Weather weather = await weatherStation.currentWeather();
    setState(() {
      celsius = weather.temperature.celsius;
    });
    print(celsius.toString());
    // double fahrenheit = weather.temperature.celsius;

    mqttClient.port = port;
    mqttClient.logging(on: true);
    mqttClient.keepAlivePeriod = 120;
    mqttClient.onConnected = _onConnected;
    mqttClient.onDisconnected = _onDisconnected;
    mqttClient.onSubscribed = _onSubscribed;
    MqttConnectionState state;
    String topic = "temperature";
    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .keepAliveFor(120) // Must agree with the keep alive set above or not set
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print("----client connecting----");
    mqttClient.connectionMessage = connMess;
    try {
      await mqttClient.connect(username, passwd);
    } on Exception catch (e) {
      print('----EXC $e----');
      mqttClient.disconnect();
      return;
    }
    if (mqttClient.connectionStatus.state == MqttConnectionState.connected) {
      print("----client connected----");
    } else {
      print("----unable to connect----");
      setState(() {
        state = mqttClient.connectionStatus.state;
      });
      print("----connection state is $state----");
      print("----disconnecting----");
      mqttClient.disconnect();
      return;
    }
    print("----subscribing to topic \"$topic\"----");
    mqttClient.subscribe(topic, MqttQos.atMostOnce);

    mqttClient.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print("----topic is ${c[0].topic} and payload is $pt----");
      setState(() {
        _temp = double.parse(pt);
      });
    });

    print("----sleeping----");
    await MqttUtilities.asyncSleep(120);

    print("----unsubscribing----");
    mqttClient.unsubscribe(topic);

    await MqttUtilities.asyncSleep(2);

    print("----disconnecting----");
    mqttClient.disconnect();
    return;
  }

  void _onDisconnected() {
    print("----_onDisconnected callback, client disconnection----");
    if (mqttClient.connectionStatus.returnCode ==
        MqttConnectReturnCode.solicited) {
      print("----_onDisconnected callback solicitated, correct!----");
    }
    return;
  }

  void _onConnected() {
    print("----connection from _onConnected successful----");
  }

  void _onSubscribed(String topic) {
    print("----subscribed to topic $topic from _onSubscribed----");
  }
  
  Map<PermissionGroup, PermissionStatus> permissions;
  PermissionStatus permission;
  getPermission() async {
    permissions = await PermissionHandler().requestPermissions([PermissionGroup.location]);
    permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.location);
    print(permission.value);
  }

  @override
  void initState() {
    getPermission();
    connect();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          CurrentTemp(celsius),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: connect,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
