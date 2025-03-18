import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goalock/services/lock_screen_service.dart';

class LockScreenSettings extends StatefulWidget {
  const LockScreenSettings({Key? key}) : super(key: key);

  @override
  _LockScreenSettingsState createState() => _LockScreenSettingsState();
}

class _LockScreenSettingsState extends State<LockScreenSettings> {
  bool _serviceEnabled = false;
  bool _isLoading = true;
  bool _hasPermission = false;

  final _goalTextController = TextEditingController();
  Color _backgroundColor = Colors.black;
  Color _textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _goalTextController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 권한 확인
      _hasPermission = await LockScreenService.checkPermissions();

      // 서비스 상태 확인
      _serviceEnabled = await LockScreenService.isServiceEnabled();

      // 설정 불러오기
      final prefs = await SharedPreferences.getInstance();
      _goalTextController.text =
          prefs.getString('goalText') ?? '하루를 소중하게 사용하세요';

      String? bgColorStr = prefs.getString('backgroundColor');
      if (bgColorStr != null && bgColorStr.isNotEmpty) {
        _backgroundColor = Color(
          int.parse(bgColorStr.replaceFirst('#', 'FF'), radix: 16),
        );
      }

      String? textColorStr = prefs.getString('textColor');
      if (textColorStr != null && textColorStr.isNotEmpty) {
        _textColor = Color(
          int.parse(textColorStr.replaceFirst('#', 'FF'), radix: 16),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('설정을 불러오는 중 오류가 발생했습니다: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_serviceEnabled) {
        // 서비스 중지
        success = await LockScreenService.stopService();
      } else {
        // 권한 확인 및 요청
        if (!_hasPermission) {
          _hasPermission = await LockScreenService.requestPermissions();
          if (!_hasPermission) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '권한이 부여되지 않았습니다. 잠금화면 서비스를 사용하려면 오버레이 권한이 필요합니다.',
                ),
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        // 목표 텍스트 및 색상 설정
        await _saveSettings();

        // 서비스 시작
        success = await LockScreenService.startService();
      }

      if (success) {
        setState(() {
          _serviceEnabled = !_serviceEnabled;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _serviceEnabled ? '잠금화면 서비스가 활성화되었습니다.' : '잠금화면 서비스가 비활성화되었습니다.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _serviceEnabled ? '잠금화면 서비스 중지 실패' : '잠금화면 서비스 시작 실패',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    // SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goalText', _goalTextController.text);
    await prefs.setString(
      'backgroundColor',
      '#${_backgroundColor.value.toRadixString(16).substring(2)}',
    );
    await prefs.setString(
      'textColor',
      '#${_textColor.value.toRadixString(16).substring(2)}',
    );

    // 네이티브 서비스에 전달
    await LockScreenService.setGoalText(_goalTextController.text);
    await LockScreenService.setBackgroundColor(
      '#${_backgroundColor.value.toRadixString(16).substring(2)}',
    );
    await LockScreenService.setTextColor(
      '#${_textColor.value.toRadixString(16).substring(2)}',
    );
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _hasPermission = await LockScreenService.requestPermissions();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasPermission
                ? '권한이 성공적으로 부여되었습니다.'
                : '권한이 부여되지 않았습니다. 앱 설정에서 오버레이 권한을 활성화해주세요.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('권한 요청 중 오류가 발생했습니다: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showColorPicker(bool isBackground) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isBackground ? '배경색 선택' : '텍스트 색상 선택'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: isBackground ? _backgroundColor : _textColor,
                onColorChanged: (color) {
                  setState(() {
                    if (isBackground) {
                      _backgroundColor = color;
                    } else {
                      _textColor = color;
                    }
                  });
                },
                pickerAreaHeightPercent: 0.8,
                enableAlpha: false,
                displayThumbColor: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('선택'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('잠금화면 설정')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 권한 상태 및 요청 버튼
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _hasPermission
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color:
                                        _hasPermission
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '오버레이 권한',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _hasPermission
                                    ? '권한이 부여되었습니다.'
                                    : '잠금화면을 표시하려면 오버레이 권한이 필요합니다.',
                              ),
                              const SizedBox(height: 8),
                              if (!_hasPermission)
                                ElevatedButton(
                                  onPressed: _requestPermissions,
                                  child: const Text('권한 요청'),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 서비스 활성화 토글
                      SwitchListTile(
                        title: const Text(
                          '잠금화면 서비스',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          _serviceEnabled
                              ? '잠금화면 서비스가 활성화되어 있습니다.'
                              : '잠금화면 서비스가 비활성화되어 있습니다.',
                        ),
                        value: _serviceEnabled,
                        onChanged: (value) => _toggleService(),
                      ),

                      const SizedBox(height: 16),

                      // 목표 텍스트 입력
                      const Text(
                        '목표 텍스트',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _goalTextController,
                        decoration: const InputDecoration(
                          hintText: '잠금화면에 표시할 목표 텍스트를 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // 색상 설정
                      const Text(
                        '색상 설정',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showColorPicker(true),
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '배경색',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showColorPicker(false),
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _textColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '텍스트 색상',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 설정 저장 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _serviceEnabled ? _saveSettings : null,
                          child: const Text('설정 저장'),
                        ),
                      ),

                      const SizedBox(height: 8),
                      if (_serviceEnabled)
                        const Center(
                          child: Text(
                            '변경사항은 즉시 적용됩니다',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 주의사항
                      Card(
                        color: Colors.amber.shade50,
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '주의사항',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• 일부 기기에서는 제조사 특성에 따라 잠금화면이 정상적으로 표시되지 않을 수 있습니다.\n'
                                '• 배터리 최적화 설정에서 이 앱을 제외하면 더 안정적으로 동작합니다.\n'
                                '• 기기를 재부팅하면 잠금화면 서비스가 자동으로 시작됩니다.\n'
                                '• 화면 상단에서 아래로 스와이프하여 잠금화면을 해제할 수 있습니다.',
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
