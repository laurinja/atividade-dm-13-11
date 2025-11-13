// Conteúdo para: lib/features/mood_entry/infrastructure/mood_entry_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_journal/data/dtos/mood_entry_dto.dart';
import 'package:mood_journal/data/mappers/mood_entry_mapper.dart';
import 'package:mood_journal/domain/entities/mood_entry_entity.dart';
import 'package:mood_journal/features/mood_entry/infrastructure/local/mood_entry_local_dto.dart';
import 'package:mood_journal/features/mood_entry/infrastructure/local/mood_entry_local_dto_shared_prefs.dart';
// Importar o repositório de metas para fazer a integração
import 'package:mood_journal/features/daily_goals/infrastructure/daily_goal_repository.dart';

// 1. Provider para a fonte de dados local (SharedPreferences)
final moodEntryLocalDtoProvider = Provider<MoodEntryLocalDto>((ref) {
  return MoodEntryLocalDtoSharedPrefs();
});

// 2. O Repositório (que gerencia o estado da lista de humores)
class MoodEntryRepository extends StateNotifier<List<MoodEntryEntity>> {
  final MoodEntryLocalDto _localDataSource;
  final Ref _ref; // Precisamos do Ref para chamar outro provider

  MoodEntryRepository(this._localDataSource, this._ref) : super([]) {
    loadMoodEntries();
  }

  Future<void> loadMoodEntries() async {
    try {
      final dtos = await _localDataSource.listAll();
      final entities = MoodEntryMapper.toEntityList(dtos);
      // Ordenar por data (mais recentes primeiro)
      entities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = entities;
    } catch (e) {
      state = [];
    }
  }

  /// Salva um novo registro de humor
  Future<void> saveMoodEntry(MoodEntryEntity entry) async {
    try {
      final dto = MoodEntryMapper.toDto(entry);
      await _localDataSource.upsertAll([dto]);

      // Atualiza o estado local
      state = [entry, ...state];

      // *** IMPLEMENTAÇÃO DA FEATURE 2 ***
      // Notifica o repositório de metas para incrementar a meta do dia
      await _ref
          .read(dailyGoalRepositoryProvider.notifier)
          .incrementMoodEntryGoal(entry.timestamp);
    } catch (e) {
      print('Erro ao salvar mood entry: $e');
    }
  }

  Future<void> deleteMoodEntry(String id) async {
    // (Lógica para deletar, não necessária para a feature, mas bom ter)
    // ...
  }

  // Verifica se já existe entrada para hoje
  bool get hasEntryToday {
    final now = DateTime.now();
    return state.any((entry) {
      return entry.timestamp.year == now.year &&
          entry.timestamp.month == now.month &&
          entry.timestamp.day == now.day;
    });
  }
}

// 3. O Provider principal que a UI vai consumir
final moodEntryRepositoryProvider =
    StateNotifierProvider<MoodEntryRepository, List<MoodEntryEntity>>((ref) {
  final localDataSource = ref.watch(moodEntryLocalDtoProvider);
  return MoodEntryRepository(localDataSource, ref);
});