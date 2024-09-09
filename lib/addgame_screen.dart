import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddGameScreen extends StatefulWidget {
  const AddGameScreen({super.key});

  @override
  _AddGameScreenState createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _imagePath = '';
  String _execPath = '';

  Future<void> _pickFile(bool isImage) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isImage ? FileType.image : FileType.any,
    );

    if (result != null) {
      setState(() {
        if (isImage) {
          _imagePath = result.files.single.path!;
        } else {
          _execPath = result.files.single.path!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 게임 추가')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 300, vertical: 100),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: '게임 제목'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '게임 제목을 입력해주세요';
                }
                return null;
              },
              onSaved: (value) => _title = value!,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(
                  '게임 이미지: ${_imagePath.isEmpty ? "선택되지 않음" : _imagePath}'),
              trailing: ElevatedButton(
                onPressed: () => _pickFile(true),
                child: const Text('이미지 선택'),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title:
                  Text('실행 파일: ${_execPath.isEmpty ? "선택되지 않음" : _execPath}'),
              trailing: ElevatedButton(
                onPressed: () => _pickFile(false),
                child: const Text('실행 파일 선택'),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate() &&
                    _imagePath.isNotEmpty &&
                    _execPath.isNotEmpty) {
                  _formKey.currentState!.save();
                  Navigator.pop(context, {
                    'title': _title,
                    'imagePath': _imagePath,
                    'execPath': _execPath,
                  });
                }
              },
              child: const Text('게임 추가'),
            ),
          ],
        ),
      ),
    );
  }
}
