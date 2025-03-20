import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'auth_screen.dart';
import 'task_edit_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, bool> selectedTasks = {}; // Store selected task IDs

  void _logout(BuildContext context) async {
    bool confirmLogout = await _showConfirmationDialog(context, "Logout", "Are you sure you want to log out?");
    if (confirmLogout) {
      await FirebaseAuth.instance.signOut();
      Fluttertoast.showToast(msg: "Logged out successfully!");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthScreen()));
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String title, String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Yes")),
        ],
      ),
    ) ?? false;
  }

  void _deleteSelectedTasks() async {
    bool confirmDelete = await _showConfirmationDialog(context, "Delete Selected Tasks", "Are you sure you want to delete selected tasks?");
    if (confirmDelete) {
      for (String taskId in selectedTasks.keys.where((id) => selectedTasks[id]!)) {
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      }
      setState(() {
        selectedTasks.clear();
      });
      Fluttertoast.showToast(msg: "Selected tasks deleted!");
    }
  }

  void _addTask() {
    TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Task"),
        content: TextField(
          controller: taskController,
          decoration: InputDecoration(hintText: "Enter task"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (taskController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('tasks').add({
                  'title': taskController.text.trim(),
                  'userId': user?.uid,
                  'createdAt': Timestamp.now(),
                });
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "Task added successfully!");
                setState(() {});
              } else {
                Fluttertoast.showToast(msg: "Task cannot be empty!");
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("User Profile", style: TextStyle(fontSize: 18)),
              accountEmail: Text(user?.email ?? "No email"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout"),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    String taskId = task.id;

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: Checkbox(
                          value: selectedTasks[taskId] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedTasks[taskId] = value ?? false;
                            });
                          },
                        ),
                        title: Text(task['title'], style: TextStyle(fontSize: 18)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                var result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaskEditScreen(
                                      taskId: taskId,
                                      taskData: task.data() as Map<String, dynamic>,
                                    ),
                                  ),
                                );

                                // Kung updated, magpakita ng toast message
                                if (result != null && result is Map<String, dynamic> && result["updated"] == true) {
                                  Fluttertoast.showToast(msg: "Task updated successfully!");
                                  setState(() {});
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                bool confirmDelete = await _showConfirmationDialog(context, "Delete Task", "Are you sure you want to delete this task?");
                                if (confirmDelete) {
                                  await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
                                  setState(() {});
                                  Fluttertoast.showToast(msg: "Task deleted!");
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (selectedTasks.containsValue(true))
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: Icon(Icons.delete, color: Colors.white),
                label: Text("Delete Selected"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _deleteSelectedTasks,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
