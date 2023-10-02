import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class Loby extends StatefulWidget {
  final String title;
  const Loby({super.key, required this.title});
  @override
  State<Loby> createState() => _LobyPageState();
}

class _LobyPageState extends State<Loby> {
  bool multiplayer = false;
  String joined_players = "";
  int index = 0;
  bool master = false;
  String name = "";
  Future<void> chooseName() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: Text("Choose a name"),
            content: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                    child: Column(
                  children: [
                    TextFormField(
                        decoration: const InputDecoration(labelText: 'Name:'),
                        onChanged: (val) {
                          setState(() {
                            name = val;
                          });
                        })
                  ],
                ))),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("submit")),
            ],
          );
        });
  }

  StreamSubscription<HttpRequest>? streamSubscription = null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body:
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            Center(
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  if (!multiplayer) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyHomePage(
                                  title: "Septica Home page",
                                  type: 1,
                                  multiplayer: multiplayer,
                                )));
                  } else {
                    if (master) {
                       streamSubscription!.cancel();
                      for (var player in players) {
                        http.get(Uri(
                            port: 3002,
                            scheme: "http",
                            host: player.personalIp,
                            path: "/start/${players.length}/1"));
                      }
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyHomePage(
                                  title: "Septica Home page",
                                  type: 1,
                                  multiplayer: multiplayer,
                                )));
                  }
                },
                child: Text("Play septica")),
            ElevatedButton(
                onPressed: () {
                  if (!multiplayer) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyHomePage(
                                  title: "Cruce Home page",
                                  type: 2,
                                  multiplayer: multiplayer,
                                )));
                  } else {
                    if (master) {
                         streamSubscription!.cancel();
                       
                      for (var player in players) {
                        http.get(Uri(
                            port: 3002,
                            scheme: "http",
                            host: player.personalIp,
                            path: "/start/${players.length}/2"));
                      }

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MyHomePage(
                                    title: "Cruce Home page",
                                    type: 2,
                                    multiplayer: multiplayer,
                                  )));
                    }
                  }
                },
                child: Text("Play cruce")),
            Text("Play on multiplayer"),
            Checkbox(
                value: multiplayer,
                onChanged: (value) {
                  setState(() {
                    multiplayer = value as bool;
                  });
                }),
            multiplayer
                ? ElevatedButton(
                    onPressed: () async {
                      var adresses = await NetworkInterface.list();
                      print("Interfaces");
                      master = true;
                      var first = null;

                      for (var interface in adresses) {
                        print("interface name${interface.name}");

                        for (var adress in interface.addresses) {
                          first ??= adress.address;

                          print("${adress.host},${adress.address}");
                        }
                      }

                      players.clear();
                      Player player = Player();
                      player.personalIp = first;
                      player.serverIp = first;

                      await chooseName();
                      player.name = name;

                      setState(() {
                        joined_players =
                            "1. First  player starter of room, ${player.name} \n";
                        print("seteaza starea stringului $joined_players");
                      });
                      players.add(player);
                      RawDatagramSocket udps = await RawDatagramSocket.bind(
                          InternetAddress.anyIPv4, 4000);

                      udps.broadcastEnabled = true;
                      udps.writeEventsEnabled = true;

                      server = await HttpServer.bind(
                          InternetAddress(first), 3000,
                          shared: true);
                      print("started http server ${server!.address.address}");
                      streamServer = server!.asBroadcastStream();

                      streamSubscription=streamServer!.listen((element) {
                        String path = element.uri.path;
                        RegExp exp = RegExp(r'connect/(.*)/(.*)', dotAll: true);
                        RegExpMatch? match = exp.firstMatch(path);
                        print("Path of client in loby is: ${path}");
                        if (match != null) {
                          Player player = Player();

                          player.serverIp = server!.address.address;
                          print("player ip is:${match[1]}");
                          player.personalIp = match[1]!;
                          player.name = match[2]!;

                          setState(() {
                            index = players.length - 1;
                          });
                          players.add(player);
                          setState(() {
                            joined_players +=
                                "Player ${player.name} has joined \n";
                          });
                        }

                        element.response
                            .write("{\"index\":${players.length - 1}}");

                        element.response.close();
                      });

                      print("Start local room");

                      Timer.periodic(const Duration(seconds: 5), (timer) async {
                        var adresses = await NetworkInterface.list();

                        for (var interface in adresses) {
                          for (var address in interface.addresses) {
                            //  print("{\"connect\":\"$first\"}");
                            // print("Adress: ${address.address}");

                            //print(address.type);

                            if (address.type == InternetAddressType.IPv4) {
                              if (address.type == InternetAddressType.IPv4) {
                                var addressS = address.address.replaceRange(
                                    address.address.lastIndexOf("."),
                                    null,
                                    ".255");

                                await udps.send(
                                    "{\"connect\":\"$first\"}".codeUnits,
                                    InternetAddress(addressS),
                                    4001);
                              }
                            }
                          }
                        }
                      });
                      if (first != null) {}
                    },
                    child: Text("Start local room"))
                : const SizedBox.shrink(),
            multiplayer
                ? ElevatedButton(
                    onPressed: () async {
                      RawDatagramSocket udps = await RawDatagramSocket.bind(
                          reuseAddress: true,
                          reusePort: true,
                          InternetAddress.anyIPv4,
                          4001);
                      await chooseName();
                      print("Joining a room wait for server discovery");
                      bool discoveredAServer = false;
                      udps.listen((e) async {
                        Datagram? dg = udps.receive();
                        if (dg != null && discoveredAServer == false) {
                          String message = String.fromCharCodes(dg.data);

                          var msg = jsonDecode(message);

                          if (msg["connect"] != null) {
                            discoveredAServer = true;
                            print("received Server Ip: ${msg["connect"]}");

                            var server_ip = msg["connect"];

                            var adresses = await NetworkInterface.list();
                            print("send http request to $server_ip b");
                            bool received = false;
                            while (!received) {
                              var result = await http.get(Uri(
                                  scheme: "http",
                                  host: server_ip,
                                  port: 3000,
                                  path:
                                      "\\connect\\${adresses.elementAt(0).addresses.elementAt(0).address}\\$name"));
                              if (result.statusCode >= 200 &&
                                  result.statusCode < 300) {
                                String body = result.body;
                                var bdy = jsonDecode(body);
                                setState(() {
                                  if (bdy["index"] != null)
                                    index = bdy["index"];

                                  joined_players =
                                      "Join on serve with index:$index";
                                  print("Index:$index");
                                });
                                //every client will have a server to listen for messages from master
                                serverClients = await HttpServer.bind(
                                    shared: true,
                                    InternetAddress.anyIPv4,
                                    3002);
                                streamClients =
                                    serverClients!.asBroadcastStream();

                                var subscription;

                                subscription =
                                    streamClients!.listen((event) async {
                                  var path = event.uri.path;
                                  if (!gameStarted) {
                                    gameStarted = true;
                                    RegExp exp = RegExp(r'start/(.*)/(.*)');
                                    RegExpMatch? match = exp.firstMatch(path);
                                    if (match != null) {
                                      nr_players = int.parse(match[1]!);
                                      int typeGame = int.parse(match[2]!);
                                      print("Starting with $nr_players layers");
                                     

                                      typeGame == 1
                                          ? Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MyHomePage(
                                                        title:
                                                            "Septica Home page",
                                                        type: 1,
                                                        index: index,
                                                        multiplayer:
                                                            multiplayer,
                                                      )))
                                          : Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MyHomePage(
                                                        title:
                                                            "Cruce Home page",
                                                        type: 2,
                                                        index: index,
                                                        multiplayer:
                                                            multiplayer,
                                                      )));
                                    }

                                    subscription.cancel();
                                  } else {
                                    print(
                                        "not a start message, also the game started can clouse itself");
                                    //

                                    subscription.cancel();
                                  }
                                });

                                received = true;
                              }

                              print("Status request:${result.statusCode}");
                            }
                          }
                        }
                      });
                    },
                    child: Text("Join local room"))
                : const SizedBox.shrink(),
            multiplayer
                ? Text("Players:\n$joined_players")
                : const SizedBox.shrink()
          ],
        )));
  }
}
