import 'package:flutter/material.dart';
import 'user_model.dart';
import 'api_service.dart';
import 'main.dart'; // Import Main Screen

void main() {
  runApp(MaterialApp(home: UserScreen()));
}

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late Future<List<User>> futureUsers;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  int? editingId;

  @override
  void initState() {
    super.initState();
    futureUsers = ApiService.getUsers();
  }

  void refreshUsers() {
    setState(() {
      futureUsers = ApiService.getUsers();
    });
  }

  void handleLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  Future<bool> onWillPop() async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text("Logout Confirmation"),
                content: Text("Do you want to logout before exiting?"),
                actions: [
                  TextButton(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).pop(false), // Stay in UserScreen
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed:
                        () => handleLogout(), // Logout and go to MainScreen
                    child: Text("Logout"),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void handleSave() async {
    String name = nameController.text;
    String email = emailController.text;
    String password = passwordController.text;

    if (editingId == null) {
      await ApiService.addUser(name, email, password);
    } else {
      await ApiService.updateUser(editingId!, name, email, password);
    }

    nameController.clear();
    emailController.clear();
    passwordController.clear();
    editingId = null;
    refreshUsers();
  }

  void handleEdit(User user) {
    setState(() {
      nameController.text = user.name;
      emailController.text = user.email;
      passwordController.text = user.password;
      editingId = user.id;
    });
  }

  void handleDelete(int id) async {
    await ApiService.deleteUser(id);
    refreshUsers();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Flutter CRUD with Express and MySQL"),
          actions: [
            IconButton(icon: Icon(Icons.logout), onPressed: handleLogout),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: "Email"),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: "Password"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: handleSave,
                    child: Text(editingId == null ? "Add User" : "Update User"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<User>>(
                future: futureUsers,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No Users Found"));
                  }
                  return ListView(
                    children:
                        snapshot.data!.map((user) {
                          return ListTile(
                            title: Text(user.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Email: ${user.email}"),
                                Text("Password: ${user.password}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => handleEdit(user),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => handleDelete(user.id),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
