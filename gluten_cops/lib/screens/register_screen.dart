import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gluten_cops/screens/login_screen.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({Key? key}) : super(key: key);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordRepeatController =
      TextEditingController();

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _register(BuildContext context) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Kullanıcı başarıyla kaydedildiğinde, giriş ekranına yönlendir.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Kayıt işlemi sırasında bir hata oluştu.';
      if (e.code == 'weak-password') {
        message = 'Sağlanan şifre çok zayıf.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta adresi zaten kullanımda.';
      } else {
        message = 'Bilinmeyen bir hata oluştu.';
      }

      _showSnackBar(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "GLUTEN",
                      style: TextStyle(
                        color: Colors.pink,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "COPS",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                _buildTextField(_nameController, "Ad Soyad", false),
                const SizedBox(height: 10),
                _buildTextField(_cityController, "Şehir", false),
                const SizedBox(height: 10),
                _buildTextField(_emailController, "Email", false),
                const SizedBox(height: 10),
                _buildTextField(_passwordController, "Şifre", true),
                const SizedBox(height: 10),
                _buildTextField(
                    _passwordRepeatController, "Şifre Tekrar", true),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.pink, // background
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () {
                    _register(context);
                  },
                  child: const Text("KAYIT OL"),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black)),
                    Text("veya"),
                    Expanded(child: Divider(color: Colors.black)),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Zaten hesabın var mı? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "Giriş yap.",
                        style: TextStyle(color: Colors.pink),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextField _buildTextField(
      TextEditingController controller, String labelText, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        fillColor: Colors.grey.shade200,
        filled: true,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(4),
          ),
        ),
      ),
    );
  }
}
