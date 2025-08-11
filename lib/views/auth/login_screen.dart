import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/auth/login_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen();
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _id = '', _pw = '';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // 로고
             
       
              // 타이틀
              Text(
                '전기설비 점검',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
              ),
              const SizedBox(height: 32),
              // 에러 메시지
              if (vm.errorMessage != null) ...[
                Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              // 입력 폼을 카드로 감싸기
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '아이디',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '아이디를 입력하세요' : null,
                          onSaved: (v) => _id = v!.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: '비밀번호',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                vm.isLoading
                                    ? Icons.hourglass_empty
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  // vm에서는 obscure 상태를 관리하지 않도록 했으니
                                  // 여기서만 토글용 boolean을 하나 쓰세요.
                                });
                              },
                            ),
                          ),
                          obscureText: true,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '비밀번호를 입력하세요' : null,
                          onSaved: (v) => _pw = v!,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 로그인 버튼
              vm.isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            vm.login(_id, _pw).then((_) {
                              if (vm.loginResult?.success == true) {
                                Navigator.pushReplacementNamed(context, '/home');
                              }
                            });
                          }
                        },
                        child: const Text(
                          '로그인',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
             
            ],
          ),
        ),
      ),
    );
  }
}
