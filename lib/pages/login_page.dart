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

  Future<void> _sendCode() async {
    setState(() {
      fullPhoneNumber =
          '${_countryCodeController.text.trim()}${_phoneNumberController.text.trim()}';
    });
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        codeSent: (verificationId, forceResendingToken) {
          setState(() {
            _verificationId = verificationId;
          });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
            MediaQuery.of(context).size.height / 3), // 1/3 screen height
        child: AppBar(
          backgroundColor: theme.colorScheme.primary,
          flexibleSpace: Column(
            mainAxisAlignment:
                MainAxisAlignment.end, // Moves everything to the bottom
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    bottom:
                        100), // Adjust this value to lower everything further
                child: Column(
                  children: [
                    // Logo and title row
                    Row(
                      mainAxisSize: MainAxisSize.min, // Keeps it compact
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          theme.brightness == Brightness.dark
                              ? 'assets/GroceryGuru_light.png' // Dark mode icon
                              : 'assets/GroceryGuru_dark.png', // Light mode icon
                          height: 50, // Adjust size as needed
                          width: 50,
                        ),
                        const SizedBox(
                            width: 12), // Space between icon and text
                        Text(
                          'Grocery Guru',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black // Dark mode text color
                                    : Colors.white, // Light mode text color
                            fontFamily: 'RobotoSerif',
                            fontWeight: FontWeight.bold,
                            fontSize: 30, // Adjust text size
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Space between title and slogan
                    // Slogan
                    Text(
                      'Your Personal Grocery Assistant.',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black // Dark mode text color
                            : Colors.white, // Light mode text color
                        fontFamily: 'RobotoSerif',
                        fontSize: 16, // Adjust text size
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Moves everything higher
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Left-aligns welcome text
                  children: [
                    const SizedBox(
                        height:
                            40), // Adjust this value to move welcome text higher
                    if (_verificationId == null) ...[
                      // Welcome text section (Left-aligned)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Adjust text size
                              ),
                            ),
                            SizedBox(height: 12), // Space between welcome texts
                            Text(
                              'Enter your phone number to proceed.',
                              style: TextStyle(
                                fontSize: 14, // Adjust text size
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36), // Space before input fields

                      // Input fields & Button section (Centered)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center, // Ensures centering
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
                                          color:
                                              theme.textTheme.bodyLarge?.color),
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
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneNumberController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Phone Number',
                                      labelStyle: TextStyle(
                                          color:
                                              theme.textTheme.bodyLarge?.color),
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),

                            // Full-width Continue button
                            SizedBox(
                              width: double.infinity, // Makes button full-width
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12), // Keeps height fixed
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
                    ] else ...[
                      // OTP instruction text (Left-aligned & Higher)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 8, top: 8), // Moves text higher & aligns
                          child: Text(
                            'Please enter the OTP sent to $fullPhoneNumber.', // Dynamically insert phone number
                            style: const TextStyle(
                              fontSize: 14, // Adjust text size
                              // fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36), // Space before input field

                      Center(
                        child: Column(
                          children: [
                            // OTP Input Field
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

                            const SizedBox(height: 36), // Space before button

                            // Full-width Verify button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _verifyCode,
                                child: const Text('Verify Code'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
