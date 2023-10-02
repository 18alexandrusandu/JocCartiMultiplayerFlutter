import 'package:flutter/material.dart';
import 'main.dart';

class Scores extends StatefulWidget {
  final List<Player> players;
  final int type;

  Scores({super.key, required this.players, required this.type});
  @override
  State<Scores> createState() => _ScoresPageState(players, type);
}

class _ScoresPageState extends State<Scores> {
  bool multiplayer = false;

  List<Player> players;

  var type;

  _ScoresPageState(this.players, this.type) {
    print("players");
  }

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
          title: Text("Scoreboard"),
        ),
        body:
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            Center(
                child: Column(children: [
          ListView(
              shrinkWrap: true,
              children: players.map((e) {
                return type == 2
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text("Player ${e.name}"),
                            Text("Score of last hand:${e.score}"),
                            Text("Score of round:${e.roundScore}"),
                            Text("Acumulated score:${e.acumulatedScore}"),
                            Text(
                                "Group:${(players.indexOf(e) / 2).round() + 1}")
                          ])
                    : Column(children: [
                        Text("Player ${players.indexOf(e)}"),
                        Text("Score septica:${e.score}")
                      ]);
              }).toList())
        ])));
  }
}
