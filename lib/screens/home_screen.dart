// Conteúdo para: lib/screens/home_screen.dart
// (Restaurado ao original, mas usando Riverpod)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_journal/domain/entities/mood_entry_entity.dart'; // Importar entidade
import 'package:mood_journal/models/mood_entry.dart' as old_model; // Manter para o seletor
import 'package:uuid/uuid.dart'; // Precisamos de IDs
import '../widgets/mood_selector.dart';
import '../widgets/mood_card.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/app_drawer.dart';
// Importar o novo repositório de humor
import '../features/mood_entry/infrastructure/mood_entry_repository.dart';

// 1. Mudar para ConsumerStatefulWidget
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 2. Não precisamos mais de _isLoading ou _loadMoodEntries,
  // pois o provider gerencia isso.

  final Uuid _uuid = const Uuid();

  // 3. Método para salvar o humor (usando o repositório)
  Future<void> _onMoodSelected(old_model.MoodType mood) async {
    // Converter o MoodType antigo (do widget) para a Entidade (domínio)
    final moodLevel = MoodLevel.fromValue(mood.value.toInt());

    final newEntry = MoodEntryEntity(
      id: _uuid.v4(),
      level: moodLevel,
      timestamp: DateTime.now(),
      // nota e tags podem ser adicionadas depois
    );

    // Chamar o repositório para salvar (isso vai disparar a Feature 2)
    await ref
        .read(moodEntryRepositoryProvider.notifier)
        .saveMoodEntry(newEntry);
  }

  // (Opcional) Método para deletar humor
  Future<void> _onMoodDeleted(String id) async {
    // await ref.read(moodEntryRepositoryProvider.notifier).deleteMoodEntry(id);
    // (Ainda não implementado no repo, mas seria aqui)
  }

  @override
  Widget build(BuildContext context) {
    // 4. Obter dados do repositório
    final moodEntries = ref.watch(moodEntryRepositoryProvider);
    final hasEntryToday =
        ref.watch(moodEntryRepositoryProvider.notifier).hasEntryToday;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('MoodJournal'), // Título original
      ),
      // 5. Restaurar o corpo original da Home
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (Esta parte é do código original comentado em home_screen.dart)
            Text(
              'Como você está se sentindo hoje?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            MoodSelector(
              onMoodSelected: _onMoodSelected,
              hasEntryToday: hasEntryToday,
            ),
            const SizedBox(height: 24),
            const DailyGoalCard(), // Este é um widget antigo, pode ser trocado
            const SizedBox(height: 24),
            if (moodEntries.isNotEmpty) ...[
              Text(
                'Entradas recentes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              // Exibir as 3 entradas mais recentes
              ...moodEntries.take(3).map(
                (entry) {
                  // Precisamos converter a Entity para o modelo antigo
                  // que o MoodCard espera.
                  final oldEntry = old_model.MoodEntry(
                    id: entry.id,
                    mood: old_model.MoodType.values[entry.level.value - 1],
                    timestamp: entry.timestamp,
                    note: entry.note,
                    tags: entry.tags,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MoodCard(
                      entry: oldEntry,
                      onDelete: () => _onMoodDeleted(entry.id),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}