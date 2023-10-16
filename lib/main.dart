import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'loby.dart';
import 'scores.dart';

HttpServer? server = null;
HttpServer? serverClients = null;
Stream<HttpRequest>? streamServer;
Stream<HttpRequest>? streamClients;

bool gameStarted = false;
int current_player = 0;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          background: Color.fromARGB(255, 187, 117, 27),
        ),
        useMaterial3: true,
      ),
      home: Loby(title: "Jocuri de carti romanesti"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(
      {super.key,
      required this.title,
      required this.type,
      this.players = null,
      this.index = 0,
      this.multiplayer = false});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final int type;
  final int index;
  final List<Player>? players;
  final bool multiplayer;

  @override
  State<MyHomePage> createState() =>
      _MyHomePageState(type, players, multiplayer, index);
}

enum CardType {
  leaf,
  heart,
  bell,
  acorn,
  any;

  String toJson() => name;
}

class Card {
  late int value;
  late CardType color;
  late int index;
  late Widget? front = null;
  late Widget? back = null;
  late bool frontFaced = false;
  Card();
  Card.fromCardStriped(CardStriped card, List<Image> urls) {
    value = card.value;
    index = card.index;
    if (index > 0) {
      front = urls[index];
    } else {
      front = Container(color: Color.fromARGB(255, 187, 117, 27));
    }
    back = urls[0];
    frontFaced = card.frontFaced;
    color = card.color;
  }
}

class CardStriped {
  late int value;
  late CardType color;
  late int index;
  late bool frontFaced = false;
  CardStriped();

  CardStriped.fromCard(Card card) {
    value = card.value;
    index = card.index;
    color = card.color;
    frontFaced = card.frontFaced;
  }
  CardStriped.fromJson(var json) {
    print("Json:$json");
    value = json["value"];
    index = json["index"];
    color =
        CardType.values.firstWhere((element) => element.name == json["color"]);
    frontFaced = json["frontFaced"];
  }

  Map toJson() => {
        "value": value,
        "color": color.toJson(),
        "index": index,
        "frontFaced": frontFaced
      };
}

class Player {
  List<Card> deck = <Card>[];
  int score = 0;
  String name = "";
  bool usedTromph = false;
  int acumulatedScore = 0;
  int roundScore = 0;
  int bid = 0;
  String personalIp = "";
  String serverIp = "";
  Player();
  Player.fromStriped(PlayerStriped player, List<Image> urls) {
    score = player.score;
    name = player.name;
    usedTromph = player.usedTromph;
    acumulatedScore = player.acumulatedScore;
    roundScore = player.roundScore;
    bid = player.bid;
    personalIp = player.personalIp;
    serverIp = player.serverIp;
    deck = player.deck.map((el) {
      return Card.fromCardStriped(el, urls);
    }).toList();
  }
}

List<Player> players = <Player>[];

class PlayerStriped {
  List<CardStriped> deck = <CardStriped>[];
  int score = 0;
  String name = "";
  bool usedTromph = false;
  int acumulatedScore = 0;
  int roundScore = 0;
  int bid = 0;
  String personalIp = "";
  String serverIp = "";
  PlayerStriped();

  PlayerStriped.fromPlayer(Player player) {
    score = player.score;
    name = player.name;
    usedTromph = player.usedTromph;
    acumulatedScore = player.acumulatedScore;
    roundScore = player.roundScore;
    personalIp = player.personalIp;
    serverIp = player.serverIp;
    bid = player.bid;
    deck = player.deck.map((e) {
      return CardStriped.fromCard(e);
    }).toList();
  }
  PlayerStriped.fromJson(var json) {
    score = json["score"];
    name = json["name"];
    usedTromph = json["usedTromph"];
    acumulatedScore = json["acumulatedScore"];
    roundScore = json["roundScore"];
    bid = json["bid"];
    personalIp = json["personalIp"];
    serverIp = json["serverIp"];
    deck = List<CardStriped>.from(json["deck"].map((e) {
      return CardStriped.fromJson(e);
    }).toList());
  }

  static Map toJson(PlayerStriped player) => {
        "score": player.score,
        "name": player.name,
        "usedTromph": player.usedTromph,
        "acumulatedScore": player.acumulatedScore,
        "roundScore": player.roundScore,
        "bid": player.bid,
        "personalIp": player.personalIp,
        "serverIp": player.serverIp,
        "deck": player.deck.map((e) => e.toJson()).toList()
      };
}

class Game {
  late List<PlayerStriped> playersS;
  late List<CardStriped> fullDeck;
  late List<CardStriped> usedDeck;
  late String generalInfo = "";
  late String errors = "";
  late CardStriped currentCard;
  late int current_playerG;
  late CardType? tromph;
  Game();
  Game.fromJson(var json) {
    this.generalInfo = json["generalInfo"];
    playersS = List<PlayerStriped>.from(json["players"].map((e) {
      return PlayerStriped.fromJson(e);
    }).toList());

    fullDeck = List<CardStriped>.from(json["fullDeck"].map((e) {
      return CardStriped.fromJson(e);
    }).toList());
    current_playerG = json["current_player"];

    currentCard = CardStriped.fromJson(json["currentCard"]);
    usedDeck = List<CardStriped>.from(json["usedDeck"].map((e) {
      return CardStriped.fromJson(e);
    }).toList());

    tromph =
        CardType.values.firstWhere((element) => element.name == json["tromph"]);

    print(this.toString());
  }

  Game.fromState(_MyHomePageState state) {
    current_playerG = current_player;
    this.generalInfo = state.generalInfo;
    this.errors = state.errors;

    this.playersS = players.map((e) {
      return PlayerStriped.fromPlayer(e);
    }).toList();
    fullDeck = state.fullDeck.map((e) {
      return CardStriped.fromCard(e);
    }).toList();
    usedDeck = state.usedDeck.map((e) {
      return CardStriped.fromCard(e);
    }).toList();
    currentCard = CardStriped.fromCard(state.currentCard);
    tromph = state.tromph;
  }
  Map toJson() {
    return {
      "generalInfo": generalInfo,
      "errors": errors,
      "players": playersS.map((e) {
        return PlayerStriped.toJson(e);
      }).toList(),
      "fullDeck": fullDeck.map((e) {
        return e.toJson();
      }).toList(),
      "usedDeck": fullDeck.map((e) {
        return e.toJson();
      }).toList(),
      "current_player": current_playerG,
      "currentCard": currentCard.toJson(),
      "tromph": tromph != null ? tromph!.toJson() : ""
    };
  }
}

late int nr_players = 2;

class _MyHomePageState extends State<MyHomePage> {
  List<Image> urls = <Image>[];
  String indicationPrompt = "s";
  List<Card> fullDeck = <Card>[];
  List<Card> usedDeck = <Card>[];
  late CardType handColor;
  Card currentCard = Card();
  List<Card> currentDeck = <Card>[];
  int cards_start = 5;
  late CardType? tromph;

  late int BidingWinnerPlayer = 0;
  late int current_cards_nr = 0;
  int typeGame = 1;
  String errors = "";
  String changedTromph = "";
  Color colorTromphColor = Colors.black;
  bool ultim = false;
  String generalInfo = "";
  int limitScore = 21;
  bool firstBid = true;
  bool multipayer = false;
  bool newCurrent = false;

  Future<void> sendGet(String? address, {String? path = null}) async {
    try {
      if (address == null) {
        await http.get(
          Uri(
              scheme: "http",
              port: 3000,
              host: players[0].serverIp,
              path: path),
        );
      } else {
        await http.get(
          Uri(scheme: "http", port: 3002, host: address, path: path),
        );
      }
    } catch (exception) {
      print("coud not send get with path:$path, I will try again");
      if (address != null)
        print("the address to send message is:" + address!);
      else
        print("the address to send message is server:" + players[0].serverIp);
      sendGet(address, path: path);
    }
  }

  Future<void> sendState(String? address, {String? path = null}) async {
    try {
      Game game = Game.fromState(this);
      String body = jsonEncode(game, toEncodable: (g) {
        return (g as Game).toJson();
      });
      print("Serialized game Send State:$body");

      if (address == null) {
        await http.post(
            Uri(
                scheme: "http",
                port: 3000,
                host: players[0].serverIp,
                path: path),
            body: body);
      } else {
        await http.post(
          Uri(scheme: "http", port: 3002, host: address, path: path),
          body: body,
        );
      }
    } catch (exception) {
      print("coud not send state with path:$path, I will try again");
      sendState(address, path: path);
    }
  }

  void distributeGameInfo(Game game) {
    players = game.playersS.map((player) {
      return Player.fromStriped(player, urls);
    }).toList();

    setState(() {
      generalInfo = game.generalInfo;
      errors = game.errors;
      fullDeck = game.fullDeck.map((el) {
        return Card.fromCardStriped(el, urls);
      }).toList();
      usedDeck = game.usedDeck.map((el) {
        return Card.fromCardStriped(el, urls);
      }).toList();

      current_player = game.current_playerG;
      currentDeck = players[current_player].deck;

      current_cards_nr = currentDeck.length;
      print("current cards_nr:$current_cards_nr");
      tromph = game.tromph;
      changedTromph = "Tromph color was set to ${tromph!.name}";
      currentCard = Card.fromCardStriped(game.currentCard, urls);
    });
  }

  void init(var type, {bool existant = false}) async {
    print("in init");

    int nr_cards = type == 1 ? 33 : 25;
    cards_start = type == 1 ? 5 : 4;
    if (!multipayer) if (!existant) type == 1 ? nr_players = 2 : nr_players = 4;

    fullDeck.clear();

    for (var j = 0; j < nr_players / 2; j++)
      for (var i = 1; i < nr_cards; i++) {
        Card card = Card();
        card.front = urls[i];
        card.index = i;
        switch (i % 4) {
          case 0:
            card.color = CardType.bell;
            break;
          case 3:
            card.color = CardType.acorn;
            break;
          case 2:
            card.color = CardType.heart;
          case 1:
            card.color = CardType.leaf;
        }
        card.value = 0;

        if (1 <= i && i <= 4) card.value = 3;
        if (5 <= i && i <= 8) card.value = 4;
        if (9 <= i && i <= 12) card.value = 10;
        if (13 <= i && i <= 16) card.value = 9;
        if (17 <= i && i <= 20) card.value = 11;
        if (21 <= i && i <= 24) card.value = 2;
        if (25 <= i && i <= 28) card.value = 8;
        if (29 <= i && i <= 32) card.value = 7;

        fullDeck.add(card);
      }

    fullDeck.shuffle();
    if (!existant) players.clear();

    print("before players ${fullDeck.length}");
    for (var p = 0; p < nr_players; p++) {
      if (!existant) {
        Player play = Player();
        play.deck = <Card>[];
        play.score = 0;
        play.roundScore = 0;
        play.acumulatedScore = 0;
        for (var i = 1; i <= cards_start; i++) {
          play.deck.add(fullDeck.last);
          fullDeck.removeLast();
        }
        players.add(play);
      } else {
        players[p].deck = <Card>[];
        players[p].score = 0;
        players[p].roundScore = 0;
        for (var i = 1; i <= cards_start; i++) {
          players[p].deck.add(fullDeck.last);
          fullDeck.removeLast();
        }
      }
    }

    print("before player indexing${fullDeck.length}");
    print("before player indexing Players size:${players.length}");
    print("index of current_player:${current_player}");
    currentDeck = players.elementAt(current_player).deck;
    print("after player indexing${currentDeck.length}");

    if (type == 1) {
      currentCard = fullDeck.removeLast();

      tromph = currentCard.color;
      if (currentCard.value == 7) tromph = CardType.any;

      print("curent cardL${currentCard.color}");
    } else {
      currentCard = Card();
      currentCard.front = Container(color: Color.fromARGB(255, 187, 117, 27));
      currentCard.value = -1;
      currentCard.index = -1;
      currentCard.color = CardType.any;
      tromph = CardType.any;
    }

    current_cards_nr = currentDeck.length;
  }

  Future<void> showWinner(int winnerIndex) {
    if (!multipayer) {
      return showWinnerSingle(winnerIndex);
    } else {
      sendGet(null, path: "/winner/$winnerIndex");
      return showWinnerSingle(winnerIndex);
    }
  }

  Future<void> showWinnerSingle(int winnerIndex) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: Text("Winner is player ${winnerIndex + 1}"),
            content: const Padding(padding: EdgeInsets.all(8.0)),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      init(typeGame, existant: true);
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Play again")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    //Navigator.pop(context);
                  },
                  child: const Text("Cancel"))
            ],
          );
        });
  }

  Future<int> licitatie(int player) async {
    print("licitatie");
    if (!multipayer) {
      return licitatieClassic(player);
    } else {
      if (player == myIndex) {
        return licitatieMultiplayer(player);
      } else {
        sendGet(null, path: "licitatie/${player}");
        return 0;
      }
    }
  }

  Future<int> licitatieMultiplayer(int player) async {
    int value = 0;
    setState(() {
      current_player = player;
      currentDeck = players[player].deck;
      current_cards_nr = currentDeck.length;
    });
    print("LICITATIE MULTIPLAYER");
    print("licitatie $player");
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: Text("Player ${player + 1} Choose a number to bid or pass"),
            content: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                    child: Column(
                  children: [
                    TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Bid:'),
                        onChanged: (val) {
                          value = int.parse(val);
                        })
                  ],
                ))),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("bid")),
              ElevatedButton(
                  onPressed: () {
                    value = 0;
                    Navigator.pop(context);
                  },
                  child: const Text("pass"))
            ],
          );
        });
    players.elementAt(player).bid = value;
    print('bid  of player is over');

    nextRound(typeGame, giveCard: false);

    licitatie(myIndex + 1);

    if (myIndex == players.length - 1) {
      int maxBidingPlayer = 0;
      int maxBid = 0;
      for (var player in players) {
        if (player.bid > maxBid) {
          maxBidingPlayer = players.indexOf(player);
          maxBid = player.bid;
        }
      }
      setState(() {
        for (var player in players) {
          if (player != players[maxBidingPlayer])
            players[players.indexOf(player)].bid = 0;
        }

        current_player = maxBidingPlayer;
        currentDeck = players[maxBidingPlayer].deck;
        current_cards_nr = currentDeck.length;
      });

      return maxBidingPlayer;
    }
    return -1;
  }

  Future<int> licitatieClassic(int player) async {
    int value = 0;
    setState(() {
      current_player = player;
      currentDeck = players[player].deck;
      current_cards_nr = currentDeck.length;
    });
    print("licitatie clasica $player");
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: Text("Player ${player + 1} Choose a number to bid or pass"),
            content: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                    child: Column(
                  children: [
                    TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Bid:'),
                        onChanged: (val) {
                          value = int.parse(val);
                        })
                  ],
                ))),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("bid")),
              ElevatedButton(
                  onPressed: () {
                    value = 0;
                    Navigator.pop(context);
                  },
                  child: const Text("pass"))
            ],
          );
        });
    players.elementAt(player).bid = value;
    print('bid  of player is over');

    nextRound(typeGame, giveCard: false);
    if (player < players.length - 1) return await licitatie(player + 1);

    int maxBidingPlayer = 0;
    int maxBid = 0;
    for (var player in players) {
      if (player.bid > maxBid) {
        maxBidingPlayer = players.indexOf(player);
        maxBid = player.bid;
      }
    }
    setState(() {
      for (var player in players) {
        if (player != players[maxBidingPlayer])
          players[players.indexOf(player)].bid = 0;
      }

      current_player = maxBidingPlayer;
      currentDeck = players[maxBidingPlayer].deck;
      current_cards_nr = currentDeck.length;
    });
    return maxBidingPlayer;
  }

  has3And4(List<Card> cards) {
    for (var card in cards) {
      for (var card2 in cards) {
        if (card != card2 &&
            card.color == card2.color &&
            ((card.value == 3 && card2.value == 4) ||
                (card.value == 4 && card2.value == 3))) {
          if (card.color == tromph) {
            return {2, cards.indexOf(card), cards.indexOf(card2)};
          }

          return {1, cards.indexOf(card), cards.indexOf(card2)};
        }
      }
    }

    return {0};
  }

  Future<void> changeColorPrompt() async {
    indicationPrompt = "Choose a new color";
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              scrollable: true,
              title: const Text("Choose a new color"),
              content: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PopupMenuButton(
                      initialValue: "",
                      itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: "heart", child: Text("Heart")),
                            const PopupMenuItem(
                                value: "leaf", child: Text("Leaf")),
                            const PopupMenuItem(
                                value: "bell", child: Text("Bell")),
                            const PopupMenuItem(
                                value: "acorn", child: Text("Acorn")),
                          ],
                      onSelected: (selection) {
                        changedTromph = "Color was changed to $selection";
                        setState(() {
                          switch (selection) {
                            case "heart":
                              tromph = CardType.heart;
                              colorTromphColor =
                                  Color.fromARGB(255, 219, 20, 96);
                              break;
                            case "leaf":
                              tromph = CardType.leaf;
                              colorTromphColor = Colors.green;
                              break;
                            case "bell":
                              tromph = CardType.bell;
                              colorTromphColor = Colors.blue;
                              break;
                            case "acorn":
                              tromph = CardType.acorn;
                              colorTromphColor = Colors.yellow;
                              break;
                          }
                        });
                      })));
        });
    setState(() {
      current_player = (current_player + 1) % players.length;
      currentDeck = players.elementAt(current_player).deck;
      current_cards_nr = currentDeck.length;
    });
  }

  void nextRound(var type, {giveCard = true}) async {
    if (!multipayer) {
      await nextRoundClassic(type, giveCard: giveCard);
    } else {
      await nextRoundClassic(type, giveCard: giveCard);
      if (serverClients != null) {
        print("send next state to server\n");

        sendState(null, path: "next/$current_player");
      } else {
        print("send next state to all clients");

        for (var player in players.sublist(1)) {
          sendState(player.personalIp, path: "next/$current_player");
        }
      }
    }
  }

  bool winner = false;
  int winnerIndex = -1;

  Future<void> nextRoundClassic(var type, {giveCard = true}) async {
    setState(() {
      winner = false;
      winnerIndex = -1;
    });

    if (changedTromph != "") {
      Future.delayed(Duration(seconds: 30), () {
        setState(() {
          changedTromph = "Now tromph is $tromph";
        });
      });
    }

    setState(() {
      errors = "";
    });

    //septica
    if (type == 1) {
      for (var player in players) {
        if (player.deck.length == 0) {
          setState(() {
            winner = true;
            winnerIndex = players.indexOf(player);
          });
        }
      }

      if (winner) {
        for (var player in players) {
          if (players.indexOf(player) != winnerIndex) {
            for (var card in player.deck) {
              if (currentCard.value == 7)
                players[winnerIndex].score += 2 * card.value;
              else
                players[winnerIndex].score += card.value;
            }
          }
        }
        await showWinner(winnerIndex);

        return;
      }

      setState(() {
        if (newCurrent) tromph = currentCard.color;
      });

      if (currentCard.value == 7 && newCurrent) {
        await changeColorPrompt();
      }

      setState(() {
        usedDeck.add(currentCard);
        if (fullDeck.length < 1) {
          fullDeck = usedDeck.reversed.toList();
        }

        current_player = (current_player + 1) % players.length;

        if (currentCard.value == 2 && newCurrent) {
          players.elementAt(current_player).deck.add(fullDeck.last);
          fullDeck.removeLast();
          players.elementAt(current_player).deck.add(fullDeck.last);
          fullDeck.removeLast();
        }
        currentDeck = players.elementAt(current_player).deck;
        current_cards_nr = currentDeck.length;

        if (currentCard.value == 11 && newCurrent) {
          current_player = (current_player + 1) % nr_players;
          currentDeck = players.elementAt(current_player).deck;
          current_cards_nr = currentDeck.length;
        }

        newCurrent = false;
      });
    } else {
      bool moreThanAWinner = false;

      setState(() {
        winner = false;
        winnerIndex = 0;
      });

      setState(() {
        players[current_player].score = currentCard.value;
        if (currentCard.color == tromph)
          players[current_player].usedTromph = true;

        // if all players played a card
        bool isAllScoreBiggerThanZero = true;
        for (var player in players) {
          if (player.score == 0) isAllScoreBiggerThanZero = false;
        }
        //hand over
        if (isAllScoreBiggerThanZero) {
          int maxScor = -1;
          int maxScorTromph = -1;
          int WinnerHandTrumph = -1;
          int winnerHand = -1;

          int sum = 0;

          for (var player in players) {
            if (player.score == 9) {
              player.score = 0;
            }
            sum += player.score;

            if (player.usedTromph) {
              if (player.score > maxScorTromph) {
                maxScorTromph = player.score;
                WinnerHandTrumph = players.indexOf(player);
              }
            } else {
              if (player.score > maxScor) {
                maxScor = player.score;
                winnerHand = players.indexOf(player);
              }
            }
            //reinitilize players state after checked curent state
            player.score = 0;
            players[current_player].usedTromph = false;
          }
          if (WinnerHandTrumph > -1) {
            players[WinnerHandTrumph].roundScore += sum;
            generalInfo =
                "Winner  of last hand is Player ${players[WinnerHandTrumph].name} with score of:${sum}";
          } else if (winnerHand > -1) {
            players[winnerHand].roundScore += sum;
            generalInfo =
                "Winner  of last hand is Player ${players[winnerHand].name} with score of:${sum}";
          }
        }

        current_player = (current_player + 1) % players.length;
      });

      if (fullDeck.length >= 1 && giveCard) {
        for (var player in players) {
          if (fullDeck.length >= 1) {
            setState(() {
              player.deck.add(fullDeck.last);
              fullDeck.removeLast();
            });
          }
        }
      } else {
        bool OneHasEmptyHand = false;
        winner = false;
        for (var player in players) {
          if (player.deck.length == 0) OneHasEmptyHand = true;
        }
        if (OneHasEmptyHand) {
          print("One has empty hand");

          setState(() {
            for (var player in players) {
              switch (player.roundScore) {
                case < 33:
                  players[players.indexOf(player)].acumulatedScore +=
                      player.bid <= 0 ? 0 : -player.bid;
                  break;
                case >= 33 && < 66:
                  players[players.indexOf(player)].acumulatedScore +=
                      player.bid <= 1 ? 1 : -player.bid;
                  break;
                case >= 66 && < 99:
                  players[players.indexOf(player)].acumulatedScore +=
                      player.bid <= 2 ? 2 : -player.bid;
                  break;
                case >= 99 && < 132:
                  players[players.indexOf(player)].acumulatedScore +=
                      player.bid <= 3 ? 3 : -player.bid;
                  break;
                case >= 132 && < 165:
                  players[players.indexOf(player)].acumulatedScore +=
                      player.bid <= 4 ? 4 : -player.bid;
                  break;
                case >= 165 && < 198:
                  players[players.indexOf(player)].acumulatedScore +=
                      player.bid <= 5 ? 5 : -player.bid;
                  break;
                case >= 198:
                  players[players.indexOf(player)].acumulatedScore +=
                      player.bid <= 6 ? 6 : -player.bid;
                  break;
              }
              if (player.acumulatedScore >= limitScore) {
                if (winner == true) {
                  moreThanAWinner = true;
                } else {
                  setState(() {
                    winner = true;
                    winnerIndex = players.indexOf(player);
                  });
                }
              }
            }
          });

          if (moreThanAWinner) {
            limitScore += 10;
          } else {
            if (winner) {
              await showWinner(winnerIndex + 1);

              return;
            } else {
              print("licitatie din nou");
              init(typeGame, existant: true);
              print("licitatie dupa init");
              licitatie(0);
            }
          }
        }
      }
    }

    setState(() {
      currentDeck = players.elementAt(current_player).deck;
      current_cards_nr = currentDeck.length;
    });
  }

  int myIndex = 0;
  bool existant = false;
  _MyHomePageState(this.typeGame, var play, var multiplayer, var index) {
    this.multipayer = multiplayer;
    myIndex = index;
    if (play != null) {
      players = play;
      nr_players = players.length;
      existant = true;
    }
    urls = <Image>[];
    urls.add(Image.asset("lib/get_septica_cards/back.png"));
    for (var i = 1; i < 33; i++) {
      urls.add(Image.asset("lib/get_septica_cards/img${i}.png",
          width: 800, height: 800));
    }
    if (multiplayer) {
      if (server != null) {
        if (index == 0) {
          print("START INIT GAME, I AM SERVER");
          init(typeGame, existant: true);
        }

        streamServer!.forEach((element) async {
          RegExp exp = RegExp(r"/licitatie/(.*)", dotAll: true);

          String path = element.uri.path;
          RegExpMatch? match = exp.firstMatch(path);
          if (match != null) {
            print("licitatie inside server socket");
            int index_next = int.parse(match[1]!);

            if (index_next < players.length) {
              print("send to player with index:${index_next}");

              if (index_next == myIndex)
                licitatie(index_next);
              else
                sendGet(players[index_next].personalIp, path: "/licitatie");
            }
          } else {
            RegExp exp2 = RegExp(r"/winner/(.*)", dotAll: true);

            RegExpMatch? match2 = exp2.firstMatch(path);
            if (match2 != null) {
              for (var player in players.sublist(1)) {
                sendGet(player.personalIp, path: path);
              }
              showWinnerSingle(int.parse(match2[1]!));
            } else {
              String body =
                  await utf8.decoder.bind(element).asBroadcastStream().join();

              print(body);
              var stateJson = jsonDecode(body);
              Game game = Game.fromJson(stateJson);
              distributeGameInfo(game);

              for (var player in players.sublist(1)) {
                sendState(player.personalIp, path: path);
              }
            }
          }
        });
        for (var player in players.sublist(1)) {
          sendState(player.personalIp, path: "/init");
        }
      } else if (serverClients != null) {
        streamClients!.listen((element) async {
          print("Server path: ${element.uri.path}");

          RegExp exp = RegExp(r"/licitatie");
          if (exp.firstMatch(element.uri.path) != null) {
            licitatieMultiplayer(myIndex);
          } else {
            RegExp exp = RegExp(r"/winner/(.*)", dotAll: true);
            RegExpMatch? match = exp.firstMatch(element.uri.path);
            if (match != null) {
              showWinnerSingle(int.parse(match[1]!));
            } else {
              String body = await utf8.decodeStream(element);
              print("state received:$body");
              var stateJson = jsonDecode(body);
              Game game = Game.fromJson(stateJson);
              distributeGameInfo(game);

              print("my index  $myIndex vs current player $current_player");
            }
          }
        });
      }
    } else
      init(typeGame, existant: existant);
  }

  Size screenSizePortrait = Size(700, 500);
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      if (typeGame != 1 && firstBid && myIndex == 0) {
        firstBid = false;
        licitatie(0);
      }
    });
    setState(() {
      if (MediaQuery.of(context).orientation == Orientation.portrait) {
        screenSizePortrait = MediaQuery.of(context).size;
      }
    });

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Scores(players: players, type: typeGame)));
                },
                child: Text("Scores page"))
          ],
        ),
        body: LayoutBuilder(builder: ((context, constraints) {
          return SingleChildScrollView(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: ConstrainedBox(
                  constraints: BoxConstraints.tightFor(
                      height: max(
                          MediaQuery.of(context).orientation ==
                                  Orientation.portrait
                              ? 0.8 * MediaQuery.of(context).size.height
                              : 1.3 * MediaQuery.of(context).size.height,
                          constraints.maxHeight)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Column(children: [
                            Text("Player: ${players[current_player].name}:"),
                            players.length > current_player
                                ? Text("Score: now:${players[current_player].score}," +
                                    "hand:${players[current_player].roundScore}," +
                                    "all:${players[current_player].acumulatedScore}")
                                : const SizedBox.shrink(),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Draggable(
                                    onDragEnd: (details) {
                                      setState(() {
                                        players[current_player]
                                            .deck
                                            .add(fullDeck.last);
                                        fullDeck.removeLast();
                                        currentDeck =
                                            players[current_player].deck;

                                        current_cards_nr = currentDeck.length;
                                      });
                                      nextRound(typeGame);
                                    },
                                    feedback: SizedBox(
                                        width: MediaQuery.of(context)
                                                    .orientation ==
                                                Orientation.portrait
                                            ? MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                3
                                            : 3 /
                                                4 *
                                                MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                4,
                                        height: MediaQuery.of(context)
                                                    .orientation ==
                                                Orientation.portrait
                                            ? 4 *
                                                MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                9
                                            : MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                4,
                                        child: urls[0]),
                                    child: fullDeck.length > 1
                                        ? SizedBox(
                                            width: MediaQuery.of(context)
                                                        .orientation ==
                                                    Orientation.portrait
                                                ? MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    3
                                                : 3 /
                                                    4 *
                                                    MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    4,
                                            height: MediaQuery.of(context)
                                                        .orientation ==
                                                    Orientation.portrait
                                                ? 4 *
                                                    MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    9
                                                : MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    4,
                                            child: urls[0])
                                        : const Text("deck find: childished"),
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context)
                                                  .orientation ==
                                              Orientation.portrait
                                          ? MediaQuery.of(context).size.width /
                                              3
                                          : 3 /
                                              4 *
                                              MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              4,
                                      height: MediaQuery.of(context)
                                                  .orientation ==
                                              Orientation.portrait
                                          ? 4 *
                                              MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              9
                                          : MediaQuery.of(context).size.height /
                                              4,
                                      child: currentCard.front != null
                                          ? currentCard.front
                                          : Text("Card has no image"))
                                ]),
                            const Text("Buna alege o cate de jos si incepe"),
                            Text(errors,
                                style: TextStyle(color: Colors.red)), //errors
                            Text(changedTromph,
                                style: TextStyle(
                                    color: colorTromphColor)), //tromph changed
                            Text(generalInfo, style: TextStyle(fontSize: 20)),
                            MediaQuery.of(context).orientation ==
                                    Orientation.portrait
                                ? const Spacer()
                                : const SizedBox.shrink(),
                            currentDeck.length == 1 && typeGame == 1
                                ? ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        ultim = true;
                                        generalInfo =
                                            "Player $current_player said Ultim";
                                      });
                                      sendState(null, path: "ultim/");
                                    },
                                    child: const Text("Spune ultim"))
                                : const SizedBox.shrink(),
                            has3And4(currentDeck).elementAt(0) > 0 &&
                                    typeGame == 2
                                ? ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        var data = has3And4(currentDeck);
                                        players[current_player].roundScore +=
                                            20 * data.elementAt(0) as int;

                                        currentCard =
                                            currentDeck[data.elementAt(1)];
                                        players[current_player]
                                            .deck
                                            .removeAt(data.elementAt(1));
                                        currentDeck =
                                            players[current_player].deck;
                                        current_cards_nr = currentDeck.length;
                                        nextRound(typeGame);
                                      });
                                    },
                                    child: const Text("Spune 20 sau 40"))
                                : const SizedBox.shrink(),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: currentDeck.map((el) {
                                  return Draggable(
                                      maxSimultaneousDrags: multipayer &&
                                              current_player != myIndex
                                          ? 0
                                          : 1,
                                      onDragEnd: (details) {
                                        print("el.value:${el.value}");
                                        print("el.color:${el.color}");
                                        print(
                                            "current.value:${currentCard.value}");
                                        print("tromph:${tromph}");

                                        if (typeGame == 1 &&
                                            (el.color == tromph ||
                                                tromph == CardType.any ||
                                                el.value == 7 ||
                                                el.value ==
                                                    currentCard.value)) {
                                          setState(() {
                                            newCurrent = true;
                                            currentCard = el;
                                            tromph = currentCard.color;
                                            players[current_player]
                                                .deck
                                                .remove(el);

                                            if (!ultim &&
                                                players[current_player]
                                                    .deck
                                                    .isEmpty) {
                                              players[current_player]
                                                  .deck
                                                  .add(fullDeck.last);
                                              fullDeck.removeLast();
                                              if (fullDeck.isEmpty)
                                                fullDeck =
                                                    usedDeck.reversed.toList();
                                            }
                                            ultim = false;

                                            currentDeck =
                                                players[current_player].deck;
                                            current_cards_nr =
                                                currentDeck.length;
                                          });

                                          nextRound(typeGame);
                                        } else if (typeGame == 2) {
                                          setState(() {
                                            currentCard = el;
                                            if (tromph == CardType.any) {
                                              print("tromph before:$tromph");
                                              print("Changed  color");

                                              tromph = el.color;
                                              print("tromph after:$tromph");
                                              changedTromph =
                                                  "New tromph chosen by player ${current_player + 1} is ${tromph}";

                                              print(changedTromph);
                                            }

                                            players[current_player]
                                                .deck
                                                .remove(el);
                                            currentDeck =
                                                players[current_player].deck;
                                            current_cards_nr =
                                                currentDeck.length;
                                            nextRound(typeGame);
                                          });
                                        } else {
                                          setState(() {
                                            errors =
                                                "Eroare, nu poti pune cartea aleasa\n";
                                            errors +=
                                                "nu se potrivete culoarea";
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: current_cards_nr > 1
                                            ? screenSizePortrait.width /
                                                current_cards_nr
                                            : screenSizePortrait.width / 2,
                                        height: current_cards_nr > 1
                                            ? 4 /
                                                3 *
                                                MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                current_cards_nr
                                            : 2 /
                                                3 *
                                                MediaQuery.of(context)
                                                    .size
                                                    .width,
                                        color: Colors.brown,
                                        child: multipayer &&
                                                current_player != myIndex
                                            ? urls[0]
                                            : el.front != null
                                                ? el.front
                                                : Text("No image"),
                                      ),
                                      feedback: Container(
                                          width: current_cards_nr > 1
                                              ? screenSizePortrait.width /
                                                  current_cards_nr
                                              : screenSizePortrait.width / 2,
                                          height: current_cards_nr > 1
                                              ? 4 /
                                                  3 *
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  current_cards_nr
                                              : 2 /
                                                  3 *
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                          color: Colors.brown,
                                          child: multipayer &&
                                                  current_player != myIndex
                                              ? urls[0]
                                              : el.front != null
                                                  ? el.front
                                                  : Text("No image")));
                                }).toList())
                          ]),

// This trailing comma makes auto-formMediaQuery.of(context).size.height / 4,atting nicer for build methods.
                        )
                      ])));
        })));
  }
}
