import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import '../services/hakeem_service.dart';

class HakeemChatScreen extends StatefulWidget {
  const HakeemChatScreen({super.key});

  @override
  State<HakeemChatScreen> createState() => _HakeemChatScreenState();
}

class _HakeemChatScreenState extends State<HakeemChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final List<Map<String, String>> _quickActions = [
    {'title': 'خدمة العملاء', 'msg': 'حياك الله في حكواتي، كيف أقدر أخدمك طال عمرك؟'},
    {'title': 'كيف أشتري؟', 'msg': 'ممكن تشرح لي طريقة الشراء من المتجر؟'},
    {'title': 'الأسئلة المتكررة', 'msg': 'ما هي أكثر الأسئلة المكررة حول التطبيق؟'},
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'model',
      'content': 'أهلاً بك يا طال عمرك في مكتبة حكواتي! أنا حكيم، مستشارك ومساعدك التقني. كيف يمكنني خدمتك اليوم؟'
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    
    _msgController.clear();
    _scrollToBottom();

    // نمرر السجل ما عدا الرسالة الأخيرة للذكاء
    final history = _messages.sublist(0, _messages.length - 1);
    
    final response = await HakeemService.chatWithHakeem(history, text);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'model', 'content': response});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          title: const Text('المستشار حكيم', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
          backgroundColor: AppColors.deepBlack,
          foregroundColor: AppColors.secondary,
          centerTitle: true,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.secondary.withOpacity(0.2), height: 1),
          ),
        ),
        body: Column(
          children: [
            // القوائم والاختصارات العلوية (قائمة اليمين)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(bottom: BorderSide(color: AppColors.secondary.withOpacity(0.2))),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  ActionChip(
                    label: const Text('اصنع بطلك', style: TextStyle(color: AppColors.deepBlack, fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.secondary,
                    onPressed: () => context.push('/avatar-lab'),
                  ),
                  ..._quickActions.map((action) => ActionChip(
                    label: Text(action['title']!, style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.grey[850],
                    side: const BorderSide(color: AppColors.secondary),
                    onPressed: () {
                      _msgController.text = action['msg']!;
                      _sendMessage();
                    },
                  )).toList(),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.grey[800] : Colors.black,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                          bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                        ),
                        border: isUser ? null : Border.all(color: AppColors.secondary.withOpacity(0.5)),
                      ),
                      child: Text(
                        msg['content']!,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: isUser ? AppColors.secondary : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('حكيم يكتب الرد...', style: TextStyle(color: AppColors.secondary)),
              ),
              
            // منطقة الإدخال
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(top: BorderSide(color: AppColors.secondary.withOpacity(0.3))),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'تحدث مع حكيم...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.secondary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade800),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.deepBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _sendMessage,
                      child: const Text('إرسال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
