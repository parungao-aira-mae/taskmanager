import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_add_screen.dart';
import 'task_edit_screen.dart';

class TaskListScreen extends StatelessWidget {
  final CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tasks")),
      body: StreamBuilder(
        stream: tasks.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((task) {
              return ListTile(
                title: Text(task['title']),
                subtitle: Text(task['description']),
                leading: Checkbox(
                  value: task['completed'] ?? false,
                  onChanged: (bool? value) {
                    tasks.doc(task.id).update({'completed': value ?? false});
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskEditScreen(
                              taskId: task.id,
                              taskData: task.data() as Map<String, dynamic>,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        tasks.doc(task.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Task deleted successfully!")),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskAddScreen()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
