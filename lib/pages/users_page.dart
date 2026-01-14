import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_data_table.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/empty_state.dart';
import 'package:intl/intl.dart';

@RoutePage()
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  UserModel? _editingUser;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _showUserDialog([UserModel? user]) {
    _editingUser = user;
    if (user != null) {
      _emailController.text = user.email;
      _nameController.text = user.name;
      _roleController.text = user.role;
    } else {
      _emailController.clear();
      _nameController.clear();
      _roleController.text = 'user';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Add User' : 'Edit User'),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Role',
                  controller: _roleController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter role';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Save',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final userModel = UserModel(
                  id: _editingUser?.id ?? '',
                  email: _emailController.text,
                  name: _nameController.text,
                  role: _roleController.text,
                  isActive: _editingUser?.isActive ?? true,
                  createdAt: _editingUser?.createdAt ?? DateTime.now(),
                  gamesPlayed: _editingUser?.gamesPlayed ?? 0,
                  totalWinnings: _editingUser?.totalWinnings ?? 0,
                );

                if (_editingUser == null) {
                  await _firestoreService.addUser(userModel);
                } else {
                  await _firestoreService.updateUser(_editingUser!.id, userModel);
                }

                if (mounted) {
                  Navigator.pop(context);
                }
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
      backgroundColor: const Color(0xFFF3F4F6),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Users',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                CustomButton(
                  text: 'Add User',
                  icon: Icons.add,
                  onPressed: () => _showUserDialog(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _firestoreService.getUsers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data ?? [];
                  
                  if (users.isEmpty) {
                    return EmptyState(
                      icon: Icons.people_outline,
                      title: 'No Users',
                      message: 'Get started by adding your first user.',
                      action: CustomButton(
                        text: 'Add User',
                        icon: Icons.add,
                        onPressed: () => _showUserDialog(),
                      ),
                    );
                  }

                  final rows = users.map((user) {
                    return [
                      user.name,
                      user.email,
                      user.role,
                      user.gamesPlayed.toString(),
                      '\$${user.totalWinnings.toStringAsFixed(2)}',
                      user.isActive ? 'Active' : 'Inactive',
                      DateFormat('MMM dd, yyyy').format(user.createdAt),
                    ];
                  }).toList();

                  return CustomDataTable(
                    columns: const ['Name', 'Email', 'Role', 'Games Played', 'Winnings', 'Status', 'Created At'],
                    rows: rows,
                    onEdit: (index) => _showUserDialog(users[index]),
                    onDelete: (index) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete User'),
                          content: const Text('Are you sure you want to delete this user?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _firestoreService.deleteUser(users[index].id);
                      }
                    },
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
