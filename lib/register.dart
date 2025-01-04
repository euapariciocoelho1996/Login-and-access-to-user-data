import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:to_do_/services/auth_service.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TextEditingController _taskController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Função para salvar tarefa no Firestore
  Future<void> _saveTask() async {
    if (_taskController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        // Salvar tarefa no Firestore
        await FirebaseFirestore.instance.collection('todos').add({
          'task': _taskController.text,
          'uid': currentUser.uid,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Limpar o campo de texto
        _taskController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tarefa salva com sucesso!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar tarefa: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _taskController,
            decoration: InputDecoration(
              labelText: 'Nova Tarefa',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _saveTask,
                  child: const Text('Salvar Tarefa'),
                ),
        ],
      ),
    );
  }
}
