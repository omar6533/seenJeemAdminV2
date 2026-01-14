import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../models/game_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_data_table.dart';
import '../widgets/empty_state.dart';
import 'package:intl/intl.dart';

@RoutePage()
class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Games',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<GameModel>>(
                stream: _firestoreService.getGames(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
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

                  final games = snapshot.data ?? [];

                  if (games.isEmpty) {
                    return const EmptyState(
                      icon: Icons.gamepad_outlined,
                      title: 'No Games',
                      message: 'No games have been played yet.',
                    );
                  }

                  final rows = games.map((game) {
                    return [
                      game.userId,
                      game.categoryId,
                      '${game.score}/${game.totalQuestions}',
                      game.status,
                      DateFormat('MMM dd, yyyy HH:mm').format(game.createdAt),
                    ];
                  }).toList();

                  return CustomDataTable(
                    columns: const [
                      'User ID',
                      'Category',
                      'Score',
                      'Status',
                      'Created At'
                    ],
                    rows: rows,
                    onDelete: (index) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Game'),
                          content: const Text(
                              'Are you sure you want to delete this game?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _firestoreService.deleteGame(games[index].id);
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
