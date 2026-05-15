import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const TwoCarRaceApp());
}

class TwoCarRaceApp extends StatelessWidget {
  const TwoCarRaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Two Car Race',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartScreen(),
        '/game': (context) => const GameScreen(),
      },
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'TWO CAR RACE',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Dodge the blocks!\\nLeft side controls Red, Right side controls Blue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: Colors.greenAccent.shade400,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/game');
              },
              child: const Text(
                'START GAME',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Game states
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  Timer? gameTimer;

  // Track dimensions and positions
  // 4 lanes total: 0, 1 (Player 1) | 2, 3 (Player 2)
  int p1Lane = 0;
  int p2Lane = 3;

  // Obstacles: List of maps containing lane (0-3) and y-position (0.0 to 1.0)
  List<Obstacle> obstacles = [];
  double speed = 0.01;
  int tickCount = 0;

  final Random random = Random();

  void startGame() {
    setState(() {
      isPlaying = true;
      isGameOver = false;
      score = 0;
      p1Lane = 0;
      p2Lane = 3;
      obstacles.clear();
      speed = 0.01;
      tickCount = 0;
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      gameLoop();
    });
  }

  void gameLoop() {
    setState(() {
      // Update score and difficulty
      tickCount++;
      if (tickCount % 60 == 0) {
        score++;
        if (score % 10 == 0) {
          speed += 0.001; // Gradually increase speed
        }
      }

      // Move obstacles down
      for (var obs in obstacles) {
        obs.y += speed;
      }

      // Remove off-screen obstacles
      obstacles.removeWhere((obs) => obs.y > 1.2);

      // Spawn new obstacles
      if (tickCount % max(20, (60 - (speed * 1000)).toInt()) == 0) {
        spawnObstacle();
      }

      // Collision detection
      checkCollisions();
    });
  }

  void spawnObstacle() {
    // Determine which side to spawn on, or both
    bool spawnLeft = random.nextBool();
    bool spawnRight = random.nextBool();

    if (!spawnLeft && !spawnRight) {
      spawnLeft = true; // Ensure at least one spawns occasionally
    }

    if (spawnLeft) {
      int lane = random.nextBool() ? 0 : 1;
      obstacles.add(Obstacle(lane: lane, y: -0.1));
    }
    if (spawnRight) {
      int lane = random.nextBool() ? 2 : 3;
      obstacles.add(Obstacle(lane: lane, y: -0.1));
    }
  }

  void checkCollisions() {
    // Car y-position is fixed near the bottom (e.g., 0.8 to 0.9 in normalized coordinates)
    const double carTop = 0.80;
    const double carBottom = 0.95;

    for (var obs in obstacles) {
      // Obstacle height is roughly 0.1 in normalized coords
      double obsTop = obs.y;
      double obsBottom = obs.y + 0.1;

      if (obsBottom > carTop && obsTop < carBottom) {
        if (obs.lane == p1Lane || obs.lane == p2Lane) {
          gameOver();
          break;
        }
      }
    }
  }

  void gameOver() {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
  }

  void switchLane(int player) {
    if (!isPlaying) return;
    setState(() {
      if (player == 1) {
        p1Lane = p1Lane == 0 ? 1 : 0;
      } else {
        p2Lane = p2Lane == 2 ? 3 : 2;
      }
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Stack(
          children: [
            // Track Background
            Row(
              children: [
                // Player 1 Side (Left)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => switchLane(1),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.white24, width: 2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildLaneBackground()),
                          const VerticalDivider(color: Colors.white12, width: 1),
                          Expanded(child: _buildLaneBackground()),
                        ],
                      ),
                    ),
                  ),
                ),
                // Player 2 Side (Right)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => switchLane(2),
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(child: _buildLaneBackground()),
                          const VerticalDivider(color: Colors.white12, width: 1),
                          Expanded(child: _buildLaneBackground()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Game Elements (Cars and Obstacles)
            if (isPlaying || isGameOver)
              LayoutBuilder(
                builder: (context, constraints) {
                  double laneWidth = constraints.maxWidth / 4;
                  return Stack(
                    children: [
                      // Obstacles
                      ...obstacles.map((obs) {
                        return Positioned(
                          left: obs.lane * laneWidth + (laneWidth * 0.15),
                          top: obs.y * constraints.maxHeight,
                          width: laneWidth * 0.7,
                          height: constraints.maxHeight * 0.1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: obs.lane < 2 ? Colors.redAccent.withOpacity(0.8) : Colors.blueAccent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }),

                      // Player 1 Car
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        left: p1Lane * laneWidth + (laneWidth * 0.1),
                        top: constraints.maxHeight * 0.82,
                        width: laneWidth * 0.8,
                        height: constraints.maxHeight * 0.12,
                        child: _buildCar(Colors.red),
                      ),

                      // Player 2 Car
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        left: p2Lane * laneWidth + (laneWidth * 0.1),
                        top: constraints.maxHeight * 0.82,
                        width: laneWidth * 0.8,
                        height: constraints.maxHeight * 0.12,
                        child: _buildCar(Colors.blue),
                      ),
                    ],
                  );
                },
              ),

            // Score Display
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),

            // Start / Game Over Overlay
            if (!isPlaying)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGameOver) ...[
                        const Text(
                          'CRASHED!',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Score: $score',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: startGame,
                        child: Text(
                          isGameOver ? 'PLAY AGAIN' : 'TAP TO START',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isGameOver) ...[
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/');
                          },
                          child: const Text('Back to Menu', style: TextStyle(color: Colors.grey)),
                        )
                      ]
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaneBackground() {
    return Container(
      color: Colors.transparent,
    );
  }

  Widget _buildCar(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            height: 20,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class Obstacle {
  int lane; // 0, 1, 2, 3
  double y; // 0.0 to 1.0

  Obstacle({required this.lane, required this.y});
}
