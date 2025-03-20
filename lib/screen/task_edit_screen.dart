import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TaskEditScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  TaskEditScreen({required this.taskId, required this.taskData});

  @override
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.taskData['title']);
  }

  void _updateTask() async {
    if (titleController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Task title cannot be empty!");
      return;
    }

    await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
      'title': titleController.text.trim(),
    });

    // Magpakita ng toast message bago bumalik sa Dashboard
    Fluttertoast.showToast(msg: "Task updated successfully!", toastLength: Toast.LENGTH_SHORT);

    // Babalik sa previous screen (Dashboard) at magpapasa ng result
    Navigator.pop(context, {"updated": true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Task")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Task Title"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateTask,
              child: Text("Update Task"),
            ),
          ],
        ),
      ),
    );
  }
}
