// lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onTap: () { /* TODO */ },
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
