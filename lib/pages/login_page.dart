import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final TextEditingController _countryCodeController =
      TextEditingController(text: '+65');
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();

  String? _verificationId;
  String fullPhoneNumber = ''; // Stores the full phone number

  int _startCountdown = 60;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _startCountdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_startCountdown == 0) {
        timer.cancel();
        setState(() {}); // Refresh UI to show Resend OTP
      } else {
        setState(() {
          _startCountdown--;
        });
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      fullPhoneNumber =
          '${_countryCodeController.text.trim()}${_phoneNumberController.text.trim()}';
      _isLoading = true;
    });
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        codeSent: (verificationId, forceResendingToken) {
          setState(() {
            _verificationId = verificationId;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification code sent.')),
          );
        },
        verificationCompleted: (phoneAuthCredential) async {
          await _authService.signInWithCredential(phoneAuthCredential);
        },
        verificationFailed: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${error.message}')),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending code: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);
    try {
      if (_verificationId != null) {
        final smsCode = _smsCodeController.text.trim();
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: smsCode,
        );
        await _authService.signInWithCredential(credential);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying code: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    // Simply call _sendCode again
    await _sendCode();
  }

  // Reset the OTP state (back to phone input)
  void _reset() {
    _timer?.cancel();
    setState(() {
      _verificationId = null;
      _smsCodeController.clear();
      _startCountdown = 60;
    });
  }

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneNumberController.dispose();
    _smsCodeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height / 3),
        child: AppBar(
          backgroundColor: theme.colorScheme.primary,
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // Logo and title row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          theme.brightness == Brightness.dark
                              ? 'assets/GroceryGuru_light.png'
                              : 'assets/GroceryGuru_dark.png',
                          height: 50,
                          width: 50,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Grocery Guru',
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            fontFamily: 'RobotoSerif',
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Personal Grocery Assistant.',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        fontFamily: 'RobotoSerif',
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Show a back button when in OTP mode.
          leading: _verificationId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: theme.brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                  onPressed: _reset,
                )
              : null,
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: _verificationId == null
                    ? _buildPhoneInput(theme)
                    : _buildOTPInput(theme),
              ),
      ),
    );
  }

  Widget _buildPhoneInput(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Enter your phone number to proceed.',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _countryCodeController,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Code',
                        labelStyle: TextStyle(
                            color: theme.textTheme.bodyLarge?.color),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.secondary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(
                            color: theme.textTheme.bodyLarge?.color),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.secondary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _sendCode,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPInput(ThemeData theme) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: Text(
              'Please enter the OTP sent to $fullPhoneNumber.',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 36),
        Center(
          child: Column(
            children: [
              TextField(
                controller: _smsCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'One-Time Password',
                  labelStyle: TextStyle(
                      color: theme.textTheme.bodyLarge?.color),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: theme.colorScheme.secondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _verifyCode,
                  child: const Text('Verify Code'),
                ),
              ),
              const SizedBox(height: 24),
              _startCountdown > 0
                  ? Text(
                      'Resend OTP in $_startCountdown seconds',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    )
                  : TextButton(
                      onPressed: _resendCode,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
