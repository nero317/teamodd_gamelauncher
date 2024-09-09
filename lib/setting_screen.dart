import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final List<Map<String, String>> games;
  final Function(int) onDeleteGame;
  final Function(String) onSubtitleChange;
  final String currentSubtitle;

  const SettingsScreen({
    super.key,
    required this.games,
    required this.onDeleteGame,
    required this.onSubtitleChange,
    required this.currentSubtitle,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<Map<String, String>> _games;
  late TextEditingController _subtitleController;

  @override
  void initState() {
    super.initState();
    _games = List.from(widget.games);
    _subtitleController = TextEditingController(text: widget.currentSubtitle);
  }

  @override
  void dispose() {
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 200),
            child: TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                hintText: '부제목 입력',
              ),
              onChanged: (value) {
                widget.onSubtitleChange(value);
              },
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: _games.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_games[index]['title'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      widget.onDeleteGame(index);
                      setState(() {
                        _games.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
