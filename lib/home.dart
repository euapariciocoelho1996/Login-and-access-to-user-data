import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:to_do_/login_page.dart';
import 'package:to_do_/services/auth_service.dart';

class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final currentUser = authService.getCurrentUser();

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    // Função para exibir o diálogo de editar tarefa
    void _showEditTaskDialog(
        BuildContext context, String taskId, String currentTaskName) {
      final TextEditingController taskController =
          TextEditingController(text: currentTaskName);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Editar Tarefa'),
            content: TextField(
              controller: taskController,
              decoration: const InputDecoration(hintText: 'Nome da Tarefa'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o diálogo
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final taskName = taskController.text.trim();
                  if (taskName.isNotEmpty) {
                    // Atualiza a tarefa no Firestore
                    await FirebaseFirestore.instance
                        .collection('todos')
                        .doc(taskId)
                        .update({
                      'task': taskName,
                    });
                  }
                  Navigator.of(context).pop(); // Fecha o diálogo
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );
    }

    // Recupera o UID do usuário
    final String uid = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Abre o formulário para adicionar uma nova tarefa
              _showAddTaskDialog(context, uid);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('todos') // Coleção onde estão as tarefas
            .where('uid',
                isEqualTo: uid) // Filtra as tarefas pelo UID do usuário
            .snapshots(),
        builder: (context, snapshot) {
          // Se a conexão estiver aguardando, exibe o carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Se houver erro, exibe a mensagem de erro
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          // Se não houver dados, exibe a mensagem de que não há tarefas
          final tasks = snapshot.data?.docs ?? [];
          if (tasks.isEmpty) {
            return const Center(child: Text('Nenhuma tarefa encontrada.'));
          }

          // Exibe a lista de tarefas

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final taskData =
                  task.data() as Map<String, dynamic>; // Converte para Map
              final taskName =
                  taskData['task'] ?? 'Sem título'; // Nome da tarefa
              final taskUid =
                  taskData['uid'] ?? 'Desconhecido'; // UID do criador
              final isCompleted = taskData.containsKey('completed')
                  ? taskData['completed'] as bool
                  : false; // Verifica o campo

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Checkbox(
                    value: isCompleted,
                    onChanged: (value) async {
                      await FirebaseFirestore.instance
                          .collection('todos')
                          .doc(task.id)
                          .update({
                        'completed': value
                      }); // Atualiza o status no Firestore
                    },
                  ),
                  title: Text(
                    taskName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null, // Linha sobre o texto se concluído
                      color: isCompleted
                          ? Colors.grey
                          : Colors.black, // Cor mais clara se concluído
                    ),
                  ),
                  subtitle: Text(
                    'Cadastrada por: $taskUid',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão de editar
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditTaskDialog(context, task.id,
                              taskName); // Abre o diálogo de edição
                        },
                      ),
                      // Botão de deletar
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('todos')
                              .doc(task.id)
                              .delete();
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
    );
  }

  // Função para exibir o diálogo de adicionar tarefa
  void _showAddTaskDialog(BuildContext context, String uid) {
    final TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Nova Tarefa'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: 'Nome da Tarefa'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final taskName = taskController.text.trim();
                if (taskName.isNotEmpty) {
                  // Adiciona a tarefa no Firestore
                  await FirebaseFirestore.instance.collection('todos').add({
                    'task': taskName,
                    'uid': uid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }
                Navigator.of(context).pop(); // Fecha o diálogo
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }
}
