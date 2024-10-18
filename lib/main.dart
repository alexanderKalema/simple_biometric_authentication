import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocalAuthentication auth = LocalAuthentication();

  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Let OS determine authentication method',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      debugPrint('$e');
      setState(() {
        _isAuthenticating = false;
        _authorized = "Error - ${e.message}";
      });
      return;
    }
    if (!mounted) return;

    setState(
        () => _authorized = authenticated ? 'Authorized' : 'Not Authorized');
  }

  void _cancelAuthentication() async {
    await auth.stopAuthentication();
    setState(() => _isAuthenticating = false);
  }

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _checkBiometric() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('$e');
      canCheckBiometrics = false;
    }
    return canCheckBiometrics;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Biometric Authentication'),
        ),
        body: Center(
          child: FutureBuilder<bool>(
              future: _checkBiometric(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error checking biometrics');
                } else if (snapshot.hasData && !snapshot.data!) {
                  return const Text('Biometrics not supported on this device');
                } else {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Current State: $_authorized\n'),
                      (_isAuthenticating)
                          ? ElevatedButton(
                              onPressed: _cancelAuthentication,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Cancel Authentication"),
                                  Icon(Icons.cancel),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _authenticate,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Authenticate'),
                                      Icon(Icons.fingerprint),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ],
                  );
                }
              }),
        ),
      ),
    );
  }
}
