import 'package:beacon/views/mobile/auth_service.dart';
import 'package:flutter/material.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}


class _PasswordPageState extends State<PasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _resetPassword() async {
    setState(() { _loading = true; _message = null; });
    try {
      await authService.value.resetPassword(email: _emailController.text.trim());
      setState(() { _message = "Password reset email sent!"; });
    } catch (e) {
      setState(() { _message = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(tag: "hero_1", child: Icon(Icons.lock_reset, size: 120, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 20),
                Text("Reset Password", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _resetPassword,
                    child: _loading ? CircularProgressIndicator.adaptive() : Text("Send Reset Email"),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 20),
                  Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}