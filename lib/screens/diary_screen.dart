import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/diary_provider.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _diaryController = TextEditingController();
  final String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await context.read<DiaryProvider>().loadDiaryByDate(dateStr);
    if (_diaryController.text.isEmpty && context.read<DiaryProvider>().todayDiary != null) {
      _diaryController.text = context.read<DiaryProvider>().todayDiary!.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 顶部橙色区域
          Container(
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFF8700),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('每日总结', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ),
          // 白色背景内容区
          Expanded(
            child: Container(
              color: Colors.white,
              child: Consumer<DiaryProvider>(
                builder: (context, diaryProvider, _) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 日期选择器
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8700).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF8700).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, color: Color(0xFFFF8700)),
                                onPressed: () {
                                  setState(() {
                                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                                  });
                                  _loadData();
                                },
                              ),
                              Expanded(
                                child: Text(
                                  DateFormat('yyyy年MM月dd日').format(_selectedDate),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, color: Color(0xFFFF8700)),
                                onPressed: () {
                                  setState(() {
                                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                                  });
                                  _loadData();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 书写区域
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00A99D),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text('今日记录', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _diaryController,
                                maxLines: 8,
                                style: const TextStyle(color: Color(0xFF333333)),
                                decoration: InputDecoration(
                                  hintText: '写下今天的记录...',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A99D),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                                    diaryProvider.saveDiary(dateStr, _diaryController.text);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('保存成功'),
                                        backgroundColor: Color(0xFF00A99D),
                                      ),
                                    );
                                  },
                                  child: const Text('保存', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 历史记录
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8700),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('历史记录', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        if (diaryProvider.diaries.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(child: Text('暂无记录', style: TextStyle(color: Colors.grey.shade600))),
                          )
                        else
                          ...diaryProvider.diaries.take(10).map((diary) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('MM月dd日').format(DateTime.parse(diary.date)),
                                  style: const TextStyle(color: Color(0xFFFF8700), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  diary.content,
                                  style: const TextStyle(color: Color(0xFF333333), fontSize: 14),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8700),
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }
}