import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'background_wrapper.dart';

class ClientIDScreen extends StatefulWidget {
  @override
  _ClientIDScreenState createState() => _ClientIDScreenState();
}

class _ClientIDScreenState extends State<ClientIDScreen> {
  String? clientID;
  bool isDeleted = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    generateAndStoreClientID();
  }

  Future<void> generateAndStoreClientID() async {
    final id = _generateClientID();
    setState(() {
      clientID = id;
    });

    await _firestore.collection('clientIDs').doc(id).set({
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _generateClientID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> deleteClientIDAfterDelay(Duration delay) async {
    if (isDeleted || clientID == null) return;
    isDeleted = true;

    await Future.delayed(delay);

    try {
      await _firestore.collection('clientIDs').doc(clientID).delete();
      print("Client ID $clientID deleted after ${delay.inSeconds} seconds.");
    } catch (e) {
      print("Error deleting client ID: $e");
    }
  }

  Future<bool> _onWillPop() async {
    // Phone's back button
    deleteClientIDAfterDelay(Duration(seconds: 3));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
        decoration: const BoxDecoration(
        gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [ Color(0xFFCDFFD8),Color(0xFF94B9FF)  ],
    ),
    ),
        child: AppBar(
          title: Text("Client ID Generator"),
           backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              await deleteClientIDAfterDelay(Duration(seconds: 5)); // UI back
              Navigator.pop(context);
            },
          ),
        )
    )
        ),
        body: BackgroundWrapper(
          child: Center(
            child: clientID == null
                ? const CircularProgressIndicator()
                : Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Your Client ID:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    clientID!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}