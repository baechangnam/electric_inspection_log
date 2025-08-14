// lib/views/home/home_screen.dart
import 'package:electric_inspection_log/viewmodels/auth/login_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = '사용자';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('memName');
    if (stored != null && stored.isNotEmpty) {
      setState(() => _name = stored);
    }
  }

  Future<void> _onLogoutPressed() async {
    // 확인 팝업
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('확인')),
        ],
      ),
    );
    if (ok != true) return;

    // 1) 뷰모델 로그아웃 (SharedPreferences 정리 포함)
    await context.read<LoginViewModel>().logout();

    if (!mounted) return;
    // 2) 라우트 스택 제거 후 로그인 화면으로
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전기점검일지'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: _onLogoutPressed,
          ),
        ],
      ),
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_name님, 반갑습니다!',
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _OptionCard(
                      title: '전기설비 점검결과 통지서\n(고압용)',
                      icon: Icons.flash_on,
                      color: Colors.deepOrange,
                      onTap: () { 
                         Navigator.of(context).pushNamed('/hv-log');
                         },
                    ),
                    const SizedBox(height: 80),
                    _OptionCard(
                      title: '전기설비 점검결과 통지서\n(저압용)',
                      icon: Icons.bolt,
                      color: Colors.blueGrey,
                      onTap: () { 
                          Navigator.of(context).pushNamed('/hv-log_low');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _OptionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
