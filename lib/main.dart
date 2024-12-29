import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(HorseRaceApp());
}

class HorseRaceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Horse Race',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.green[600],
        appBarTheme: AppBarTheme(color: Colors.grey[350]),
        primarySwatch: Colors.green,
      ),
      home: HorseRaceHomePage(),
    );
  }
}

class HorseRaceHomePage extends StatefulWidget {
  const HorseRaceHomePage({super.key});

  @override
  _HorseRaceHomePageState createState() => _HorseRaceHomePageState();
}

class _HorseRaceHomePageState extends State<HorseRaceHomePage> {
  List<String> suits = ["♠", "♥", "♦", "♣"];
  List<int> horsePositions = [7, 7, 7, 7];
  List<int> horseCounters = [0, 0, 0, 0];
  List<int> horseBet = [0, 0, 0, 0];
  List<bool> cardRevealed = [false, false, false, false, false, false, false];
  List<String> revealedCardSymbols = ['', '', '', '', '', '', ''];
  List<String> deck = [];
  String currentCard = "";

  int count = 0;
  bool gameOver = false;
  String winner = "";

  @override
  void initState() {
    super.initState();
    _initializeDeck();
  }

  void _initializeDeck() {
    deck.clear();
    for (var suit in suits) {
      for (int i = 2; i <= 10; i++) {
        deck.add("$suit$i");
      }
      deck.add("${suit}J");
      deck.add("${suit}Q");
      deck.add("${suit}K");
    }
    deck.shuffle();
  }

  void advanceRace() {
    /// End race, if game is over
    if (deck.isEmpty) {
      setState(() {
        resetRace();
      });
      return;
    }

    setState(() {
      count += 1;
      //print(count);
      /// Get the next card from the deck
      currentCard = deck.removeLast();
      //print(deck);
      String suit = currentCard.substring(0, 1);
      int horseIndex = suits.indexOf(suit);

      /// Move the horse, as long as it is under index 7 (goal)
      if (horseIndex != -1 && horseCounters[horseIndex] < 7) {
        horsePositions[horseIndex]--;
        horseCounters[horseIndex]++;
      }

      /// Logic to unhide the negative cards on the left
      for (int i = 1; i < cardRevealed.length; i++) {
        if (horseCounters.every((count) => count >= i) && !cardRevealed[7 - i]) {
          cardRevealed[7 - i] = true;
          String backCard = deck.removeLast();
          String backSuit = backCard.substring(0, 1);
          revealedCardSymbols[7 - i] = backSuit;
          int backHorseIndex = suits.indexOf(backSuit);
          if (backHorseIndex != -1 && horseCounters[backHorseIndex] > 0) {
            gameOver = true;

            /// Time delay of horse for 700 ms
            Future.delayed(const Duration(milliseconds: 700), () {
              count == 0
                  ? null
                  : setState(() {
                      gameOver = false;
                      horsePositions[backHorseIndex]++;
                      horseCounters[backHorseIndex]--;
                    });
            });
          }
          break;
        }
      }

      /// When a horse got into the goal, end the game and show the winner
      if (horseCounters.any((count) => count > cardRevealed.length - 1)) {
        winner = suits[horseCounters.indexWhere((count) => count > cardRevealed.length - 1)];
        _endGame();
      }
    });
  }
      ///Explanation (i) symbol
  void showExplanationDialog(BuildContext context, String explanationText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Spielanleitung'),
          content: Text(explanationText),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  void resetRace() {
    setState(() {
      currentCard = "";
      horsePositions = [7, 7, 7, 7];
      horseCounters = [0, 0, 0, 0];
      cardRevealed = [false, false, false, false, false, false, false];
      revealedCardSymbols = ['', '', '', '', '', '', ''];
      count = 0;
      gameOver = false;
      winner = "";
      _initializeDeck();
    });
    //timer?.cancel();
  }

  void _endGame() {
    gameOver = true;
  }

  @override
  void dispose() {
    //timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double cardHeight = 70.0;
    double cardWidth = 50.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Pferderennen',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          count != 0
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200]),
                  onPressed: resetRace,
                  child: const Text(
                    "Reset",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                )
              : const SizedBox(),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1,
                      mainAxisSpacing: 5.0,
                      crossAxisSpacing: 5.0,
                    ),
                    itemCount: 40, // Total number of slots (7 rows x 5 columns + (Startbereich & Zielbereich))
                    itemBuilder: (context, index) {
                      int row = index ~/ 5; // Current row index
                      int col = index % 5; // Current column index

                      if (col == 0 && row == 0) {
                        return IconButton(
                            onPressed: () {
                              showExplanationDialog(
                                  context,
                                  '1. Jeder Spieler wählt ein Symbol der vier Ass-Karten aus (das ist das Pferd des Spielers)'
                                  '\n2. Drücke auf die unterste Karte mit der Aufschrift "Start", um eine Karte vom Stapel zu ziehen'
                                  '\n3. Mit jedem Druck auf den Stapel läuft ein Pferd weiter'
                                  '\n4. Wird eine der links verdeckten Karten aufgedeckt, so wird das Pferd mit demselben Symbol um einen Platz zurückgeworfen'
                                  '\n5. Gewonnen hat derjenige, dessen Karte als erstes im Ziel angekommen ist'
                                  '\n6. Um eine weitere Runde zu spielen, drücke in der oberen rechten Ecke auf "Reset"');
                            },
                            icon: Icon(Icons.info_outline));
                      }

                      if (col == 0 && row > 0 && row < 7) {
                        /// Verdeckte Karten links (erste Spalte)
                        return Column(
                          children: [
                            Card(
                              elevation: 6,
                              color: cardRevealed[row] ? Colors.white : Colors.grey,
                              child: SizedBox(
                                width: cardWidth,
                                height: cardHeight,
                                child: Center(
                                  child: Text(cardRevealed[row] ? revealedCardSymbols[row] : ''),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else if (col > 0 && col <= 4 && row == horsePositions[col - 1]) {
                        /// Ass Karten im Grid positioniert basierend auf horsePositions
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Card(
                              elevation: 6,
                              child: SizedBox(
                                width: cardWidth,
                                height: cardHeight,
                                child: Center(
                                  child: Text(
                                    '${suits[col - 1]}A',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        /// Leere Slots im Grid
                        return const SizedBox();
                      }
                    },
                  ),
                ),
                const Divider(thickness: 2.0),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Karte: ',
                        style: TextStyle(fontSize: 24),
                      ),
                      Card(
                        elevation: 6,
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: gameOver ? () {} : advanceRace,
                          child: count == 0
                              ? SizedBox(
                                  width: cardWidth,
                                  height: cardHeight,
                                  child: const Center(
                                    child: Text(
                                      "Start",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(0.5, 0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: cardWidth,
                                  height: cardHeight,
                                  child: Center(
                                    child: Text(
                                      currentCard,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (winner == "")
            const SizedBox()
          else
            Positioned(
              bottom: 100,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Text(
                        "Gewonnen hat ",
                        style: TextStyle(
                          fontSize: 45,
                          color: Colors.yellow,
                          shadows: [
                            Shadow(
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      winner,
                      style: const TextStyle(
                        fontSize: 35,
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
