import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'clientid_screen.dart';
import 'background_wrapper.dart';


class CTSlotManagerScreen extends StatefulWidget {
  @override
  _CTSlotManagerScreenState createState() => _CTSlotManagerScreenState();
}

class _CTSlotManagerScreenState extends State<CTSlotManagerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? clientID;
  bool clientIDDeleted = false;
  late final String slotKey;
  late final String username;

  @override
  void initState() {
    super.initState();
    initializeSlotNode();
    handleClientIDCheckAndDelete();

  }


  Future<void> handleClientIDCheckAndDelete() async {
    final docRef = _firestore.collection('clientIDs');
    final snapshot = await docRef.get();

    if (snapshot.docs.isNotEmpty && !clientIDDeleted) {
      final firstDoc = snapshot.docs.first;
      clientID = firstDoc.id;

      print("Found client ID: $clientID");

      // Optional delay to simulate "after execution completes"
      await Future.delayed(Duration(seconds: 2));

      try {
        await docRef.doc(clientID).delete();
        clientIDDeleted = true;
        print("Client ID $clientID deleted from Firestore.");
      } catch (e) {
        print("Error deleting client ID: $e");
      }
    } else {
      print("No client ID found to delete.");
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> initializeSlotNode() async {
    final docRef = _firestore.collection('slots').doc('activeSlots');
    final doc = await docRef.get();

    if (!doc.exists) {
      final emptySlots = {
        for (int i = 1; i <= 10; i++) 'slot$i': null,
      };
      await docRef.set(emptySlots);
    }
  }

  Future<void> resetAllSlots() async {
    final emptySlots = {
      for (int i = 1; i <= 10; i++) 'slot$i': null,
    };
    await _firestore.collection('slots').doc('activeSlots').set(emptySlots);
  }

  Future<void> removeSlotUser(String slotKey) async {
    await _firestore.collection('slots').doc('activeSlots').update({slotKey: null});
  }

  void _showRemoveDialog(String slotKey) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Removal"),
        content: Text("Are you sure you want to remove the user from $slotKey?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await removeSlotUser(slotKey);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text("Settings"),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClientIDScreen()), // Replace with your actual screen
              );
            },
            child: Text("Generate ClientID"),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              await resetAllSlots();
            },
            child: Text("Reset All Slots"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFCDFFD8), // Light green
                Color(0xFF94B9FF), // Light blue
              ],
            ),
          ),
          child: AppBar(
            title: Text("CT Slot Manager",
              style: TextStyle(
                  fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
                      textAlign: TextAlign.center),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.settings),
                tooltip: "Settings",
                onPressed: _showSettingsDialog,
              ),
            ],
          ),
        ),
      ),

      body: BackgroundWrapper(
    child:StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('slots').doc('activeSlots').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              final slotKey = 'slot${index + 1}';
              final slotData = data[slotKey];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("$slotKey"),
                  subtitle: slotData != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Username: ${slotData['username'] ?? 'N/A'}"),
                      Text("User ID: ${slotData['clientID'] ?? 'N/A'}"),
                      Text("Joined at: ${_formatDate(slotData['joinedAt'])}"),
                      SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: () => _showRemoveDialog(slotKey),
                          child: Text("Remove", style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            backgroundColor: Colors.red,
                          ),
                        ),
                      )
                    ],
                  )
                      : Text("Available"),
                  trailing: slotData != null
                      ? Icon(Icons.person, color: Colors.green)
                      : Icon(Icons.person_outline, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),)
    );
  }
}

