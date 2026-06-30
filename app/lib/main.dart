import 'package:flutter/material.dart';

import 'api.dart';
import 'glass.dart';
import 'models.dart';

void main() {
  runApp(const PhoneIQApp());
}

class PhoneIQApp extends StatelessWidget {
  const PhoneIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhoneIQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Segoe UI',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B7CF8),
          secondary: Color(0xFF2BD9D0),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiClient();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  final List<String> _suggestions = const [
    '3 mln so\'mgacha kamerasi zo\'r telefon',
    'O\'yin uchun eng yaxshi telefon',
    'Uzoq batareya, arzon',
    'iPhone tavsiya qiling',
  ];

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _loading) return;
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: t));
      _loading = true;
      _controller.clear();
    });
    _jump();
    try {
      final history = _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1)
          : <ChatMessage>[];
      final reply = await _api.chat(t, history);
      setState(() => _messages.add(reply));
    } catch (_) {
      setState(() => _messages.add(ChatMessage(
            role: 'assistant',
            text: 'Kechirasiz, serverga ulanib bo\'lmadi. Keyinroq urinib ko\'ring.',
          )));
    } finally {
      setState(() => _loading = false);
      _jump();
    }
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06080F),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: _messages.isEmpty
                      ? _welcome()
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _messages.length + (_loading ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= _messages.length) return _typing();
                            return _bubble(_messages[i]);
                          },
                        ),
                ),
                _inputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Glass(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B7CF8), Color(0xFF2BD9D0)],
                ),
              ),
              child: const Icon(Icons.smartphone, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('PhoneIQ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text('AI telefon maslahatchi',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2BD9D0).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('online',
                  style: TextStyle(color: Color(0xFF7CF5EE), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFB9AFff), Color(0xFF7CF5EE)],
              ).createShader(b),
              child: const Text(
                'Qanday telefon kerak?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Byudjet va maqsadingizni yozing — eng mosini topaman.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return GestureDetector(
                  onTap: () => _send(s),
                  child: Glass(
                    radius: 16,
                    blur: 10,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(s,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF8B7CF8), Color(0xFF6D5DF6)],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.07),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18), width: 1),
                ),
                child: Text(
                  m.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            if (m.phones.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  children: m.phones.map(_phoneCard).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _phoneCard(Phone p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 20,
        blur: 14,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2BD9D0), Color(0xFF8B7CF8)],
                    ),
                  ),
                  child: const Icon(Icons.smartphone,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p.brand} ${p.model}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text(p.priceLabel,
                          style: const TextStyle(
                              color: Color(0xFF7CF5EE),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _spec(Icons.memory, '${p.ramGb}GB'),
                _spec(Icons.sd_storage, '${p.storageGb}GB'),
                _spec(Icons.battery_full, '${p.batteryMah} mAh'),
                _spec(Icons.camera_alt, '${p.mainCameraMp}MP'),
                _spec(Icons.bolt, p.fiveG ? '5G' : '4G'),
              ],
            ),
            const SizedBox(height: 10),
            Text(p.bestFor,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _spec(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _typing() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Glass(
          radius: 20,
          blur: 12,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF7CF5EE)),
              ),
              SizedBox(width: 10),
              Text('Tanlayapman...',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Glass(
        radius: 26,
        blur: 18,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: _send,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Byudjet va maqsadingizni yozing...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _send(_controller.text),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B7CF8), Color(0xFF2BD9D0)],
                  ),
                ),
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
