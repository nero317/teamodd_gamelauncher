import 'dart:io';
import 'dart:convert';
import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'addgame_screen.dart';
import 'setting_screen.dart';

/*
메인화면 클래스
*/

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  _GameListScreenState createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  // 게임 목록을 저장하는 리스트
  List<Map<String, String>> games = [];

  // 각 게임 항목의 호버 상태를 저장하는 리스트
  List<bool> hoveredStates = [];
  bool isLaunching = false;

  // 부제목
  String subtitle = "GAME LAUNCHER";

  // 설정 화면 접근을 위한 비밀번호
  final String _settingsPassword = 'xladhem1234';

  @override
  void initState() {
    super.initState();
    // 위젯이 초기화될 때 게임 목록을 로드
    _loadGames();
  }

  // 게임 목록과 부제목을 로드하는 함수
  Future<void> _loadGames() async {
    // SharedPreferences 인스턴스를 가져옴
    final prefs = await SharedPreferences.getInstance();
    // 'games' 키로 저장된 JSON 문자열을 가져옴
    final String? gamesJson = prefs.getString('games');
    setState(() {
      if (gamesJson != null) {
        // JSON 문자열을 Map으로 디코딩
        final Map<String, dynamic> data = json.decode(gamesJson);
        // 'games' 키의 값을 List<Map<String, String>>으로 변환
        games = (data['games'] as List<dynamic>).map((game) {
          return Map<String, String>.from(game);
        }).toList();
        // 'subtitle' 키의 값을 가져오거나 기본값 설정
        subtitle = data['subtitle'] ?? "GAME LAUNCHER";
      } else {
        // 저장된 데이터가 없으면 기본 부제목 설정
        subtitle = "GAME LAUNCHER";
      }
      // 호버 상태 업데이트
      _updateHoveredStates();
    });
  }

  // 게임 목록과 부제목을 저장하는 함수
  Future<void> _saveGames() async {
    // SharedPreferences 인스턴스를 가져옴
    final prefs = await SharedPreferences.getInstance();
    // 게임 목록과 부제목을 포함하는 데이터 맵 생성
    final data = {
      'games': games.map((game) => Map<String, dynamic>.from(game)).toList(),
      'subtitle': subtitle,
    };
    // 데이터를 JSON 문자열로 인코딩하여 SharedPreferences에 저장
    await prefs.setString('games', json.encode(data));
  }

  // 로컬 파일 시스템에서 games.json 파일의 경로를 가져오는 함수
  Future<File> _getLocalFile() async {
    // 애플리케이션의 문서 디렉토리 경로를 가져옴
    final directory = await getApplicationDocumentsDirectory();
    // 문서 디렉토리 내의 'games.json' 파일에 대한 File 객체를 반환
    return File('${directory.path}/games.json');
  }

  void _updateHoveredStates() {
    setState(() {
      hoveredStates = List.generate(games.length, (_) => false); // 호버 상태 업데이트
    });
  }

  // 새 게임을 추가하는 함수
  void _addNewGame() async {
    // AddGameScreen으로 이동하여 결과를 기다림
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGameScreen()),
    );

    // 결과가 null이 아니고 Map<String, String> 타입인 경우
    if (result != null && result is Map<String, String>) {
      setState(() {
        // 게임 목록에 새 게임 추가
        games.add(result);
        // 호버 상태 업데이트
        _updateHoveredStates();
      });
      // 변경된 게임 목록 저장
      _saveGames();
    }
  }

  Future<void> _launchGame(String execPath) async {
    if (isLaunching) return;

    setState(() {
      isLaunching = true;
    });

    try {
      if (Platform.isWindows) {
        await Process.run(execPath, [], runInShell: true);
      } else {
        print('Game execution is only supported on Windows for now.');
      }
    } catch (e) {
      print('Error launching game: $e');
    } finally {
      setState(() {
        isLaunching = false;
      });
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
