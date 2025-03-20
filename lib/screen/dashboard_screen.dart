import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'auth_screen.dart';
import 'task_edit_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, bool> selectedTasks = {}; // Store selected task IDs

  Future<void> _logout() async {
    bool confirmLogout = await _showConfirmationDialog("Logout", "Are you sure you want to log out?");

    if (!confirmLogout) return; // Hindi na kailangang mag-check ng `mounted` dito

    await FirebaseAuth.instance.signOut();
    Fluttertoast.showToast(msg: "Logged out successfully!");

    if (!mounted) return; // Iwasan ang pag-access sa `context` kung hindi na mounted

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }


  Future<bool> _showConfirmationDialog(String title, String message) async {
    if (!mounted) return false;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Yes"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _deleteSelectedTasks() async {
    bool confirmDelete = await _showConfirmationDialog("Delete Selected Tasks", "Are you sure you want to delete selected tasks?");
    if (!mounted) return;

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
        title: const Text("Add Task"),
        content: TextField(
          controller: taskController,
          decoration: const InputDecoration(hintText: "Enter task"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Add"),
            onPressed: () {
              String taskText = taskController.text.trim();
              if (taskText.isNotEmpty) {
                Navigator.pop(context); // Isara ang dialog bago ang async operation

                FirebaseFirestore.instance.collection('tasks').add({
                  'title': taskText,
                  'userId': user?.uid,
                  'createdAt': Timestamp.now(),
                }).then((_) {
                  Fluttertoast.showToast(msg: "Task added successfully!");
                  setState(() {}); // I-refresh ang UI kung mounted pa
                }).catchError((error) {
                  Fluttertoast.showToast(msg: "Failed to add task: $error");
                });
              } else {
                Fluttertoast.showToast(msg: "Task cannot be empty!");
              }
            },
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("User Profile", style: TextStyle(fontSize: 18)),
              accountEmail: Text(user?.email ?? "No email"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: _logout,
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No tasks available"));
                }

                var tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    String taskId = task.id;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(task['title'], style: const TextStyle(fontSize: 18)),
                        leading: Checkbox(
                          value: selectedTasks[taskId] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedTasks[taskId] = value ?? false;
                            });
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
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

                                if (mounted && result != null && result["updated"] == true) {
                                  Fluttertoast.showToast(msg: "Task updated successfully!");
                                  setState(() {});
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                bool confirmDelete = await _showConfirmationDialog("Delete Task", "Are you sure you want to delete this task?");
                                if (confirmDelete) {
                                  await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
                                  if (mounted) {
                                    setState(() {});
                                    Fluttertoast.showToast(msg: "Task deleted!");
                                  }
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
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("Delete Selected"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _deleteSelectedTasks,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _addTask,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
