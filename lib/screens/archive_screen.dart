import 'package:flutter/material.dart';
import 'package:goalock/models/goal.dart';
import 'package:goalock/services/storage_service.dart';
import 'package:goalock/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  _ArchiveScreenState createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  late StorageService _storageService;
  List<Goal> _archivedGoals = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context, listen: false);
    _loadArchivedGoals();
  }

  Future<void> _loadArchivedGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await _storageService.getArchivedGoals();
      if (mounted) {
        setState(() {
          _archivedGoals = goals;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('아카이브 목표 로딩 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "아카이브",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      color: AppTheme.primaryColor,
                      onPressed: _loadArchivedGoals,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 아카이브 목록
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _archivedGoals.isEmpty
                          ? const Center(child: Text("완료된 목표가 없습니다"))
                          : ListView.builder(
                            itemCount: _archivedGoals.length,
                            itemBuilder: (context, index) {
                              final goal = _archivedGoals[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: isDark ? Colors.grey[800] : Colors.white,
                                child: ListTile(
                                  title: Text(
                                    goal.title,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "완료: ${goal.completedAt?.toString().split(' ')[0] ?? '날짜 없음'}",
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                ),

                const SizedBox(height: 20),

                // 뒤로가기 버튼
                Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
