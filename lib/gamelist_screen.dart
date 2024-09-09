import 'dart:io';
import 'dart:convert';
import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'addgame_screen.dart';
import 'setting_screen.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  _GameListScreenState createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  List<Map<String, String>> games = [];
  List<bool> hoveredStates = [];
  String subtitle = "GAME LAUNCHER";

  final String _settingsPassword =
      'xladhem1234'; // 실제 사용 시 더 안전한 방법으로 관리해야 합니다.

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gamesJson = prefs.getString('games');
    setState(() {
      if (gamesJson != null) {
        final Map<String, dynamic> data = json.decode(gamesJson);
        games = (data['games'] as List<dynamic>).map((game) {
          return Map<String, String>.from(game);
        }).toList();
        subtitle = data['subtitle'] ?? "GAME LAUNCHER";
      } else {
        subtitle = "GAME LAUNCHER"; // 기본값 설정
      }
      _updateHoveredStates();
    });
  }

  Future<void> _saveGames() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'games': games.map((game) => Map<String, dynamic>.from(game)).toList(),
      'subtitle': subtitle,
    };
    await prefs.setString('games', json.encode(data));
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/games.json');
  }

  void _updateHoveredStates() {
    setState(() {
      hoveredStates = List.generate(games.length, (_) => false);
    });
  }

  void _addNewGame() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGameScreen()),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        games.add(result);
        _updateHoveredStates();
      });
      _saveGames();
    }
  }

  Future<void> _launchGame(String execPath) async {
    try {
      if (Platform.isWindows) {
        await Process.run(execPath, [], runInShell: true);
      } else {
        print('Game execution is only supported on Windows for now.');
      }
    } catch (e) {
      print('Error launching game: $e');
    }
  }

  void _deleteGame(int index) {
    setState(() {
      games.removeAt(index);
      _updateHoveredStates();
    });
    _saveGames();
    Navigator.of(context).pop(); // 삭제 확인 대화상자 닫기
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('게임 삭제'),
          content: Text(
            '정말로 "${games[index]['title']}" 게임을 삭제하시겠습니까?',
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'PretendardMedium',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('삭제'),
              onPressed: () {
                _deleteGame(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String enteredPassword = '';
        return AlertDialog(
          title: const Text('비밀번호 입력'),
          content: TextField(
            obscureText: true,
            onChanged: (value) {
              enteredPassword = value;
            },
            decoration: const InputDecoration(hintText: "비밀번호를 입력하세요"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                if (enteredPassword == _settingsPassword) {
                  Navigator.of(context).pop();
                  _openSettingsScreen();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('비밀번호가 올바르지 않습니다.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateSubtitle(String newSubtitle) {
    setState(() {
      subtitle = newSubtitle;
    });
    _saveGames(); // subtitle 변경 후 저장
  }

  void _openSettingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          games: games,
          onDeleteGame: (index) {
            setState(() {
              games.removeAt(index);
              _updateHoveredStates();
            });
            _saveGames();
          },
          onSubtitleChange: _updateSubtitle,
          currentSubtitle: subtitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WindowTitleBarBox(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _showPasswordDialog,
                  ),
                  Expanded(
                    child: MoveWindow(),
                  ),
                  const WindowButtons(),
                ],
              ),
            ),
            const SizedBox(
              height: 70,
            ),
            Container(
              height: 1.0,
              width: 1080.0,
              color: Colors.black,
            ),
            const Text(
              "TEAM ODD",
              style: TextStyle(
                fontSize: 80,
                fontFamily: 'PretendardBlack',
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'PretendardMedium',
              ),
            ),
            const SizedBox(
              height: 70,
            ),
            Expanded(
              child: games.isEmpty
                  ? const Center(
                      child: Text(
                        '게임이 없습니다. 게임을 추가해주세요.',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.5 / 1,
                          crossAxisSpacing: 50,
                          mainAxisSpacing: 50,
                        ),
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          return _buildGameTile(
                            games[index]['title']!,
                            games[index]['imagePath']!,
                            games[index]['execPath']!,
                            index,
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(
              height: 100,
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: _addNewGame,
        tooltip: '새 게임 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGameTile(
      String title, String imagePath, String execPath, int index) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        while (hoveredStates.length <= index) {
          hoveredStates.add(false);
        }
        hoveredStates[index] = true;
      }),
      onExit: (_) => setState(() {
        if (index < hoveredStates.length) {
          hoveredStates[index] = false;
        }
      }),
      child: GestureDetector(
        onTap: () => _launchGame(execPath),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // 카드의 모서리를 더 둥글게 만듭니다.
          ),
          elevation:
              index < hoveredStates.length && hoveredStates[index] ? 20 : 2,
          color: Colors.transparent,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 100);
                        },
                      ),
                      if (index < hoveredStates.length && hoveredStates[index])
                        Container(
                          color: Colors.black.withOpacity(0.1),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              color: Colors.transparent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 221, 219, 219),
                                      fontSize: 20,
                                      fontFamily: 'PretendardBold',
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  const Text(
                                    'Click to Play',
                                    style: TextStyle(
                                      color: Color.fromARGB(174, 255, 255, 255),
                                      fontSize: 15,
                                      fontFamily: 'PretendardLight',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      MinimizeWindowButton(),
      MaximizeWindowButton(),
      CloseWindowButton(),
    ]);
  }
}
