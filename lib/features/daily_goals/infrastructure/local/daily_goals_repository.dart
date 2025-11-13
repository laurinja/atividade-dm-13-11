// Conteúdo para: lib/features/daily_goals/infrastructure/daily_goal_repository.dart

import 'package.flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_journal/data/dtos/daily_goal_dto.dart';
import 'package:mood_journal/data/mappers/daily_goal_mapper.dart';
import 'package:mood_journal/domain/entities/daily_goal_entity.dart';
import 'package:mood_journal/features/daily_goals/infrastructure/local/daily_goal_local_dto.dart';
import 'package:mood_journal/features/daily_goals/infrastructure/local/daily_goal_local_dto_shared_prefs.dart';

// 1. Provider para a fonte de dados local (SharedPreferences)
final dailyGoalLocalDtoProvider = Provider<DailyGoalLocalDto>((ref) {
  return DailyGoalLocalDtoSharedPrefs();
});

// 2. O Repositório (que gerencia o estado da lista)
class DailyGoalRepository extends StateNotifier<List<DailyGoalEntity>> {
  final DailyGoalLocalDto _localDataSource;

  DailyGoalRepository(this._localDataSource) : super([]) {
    // Carrega as metas salvas assim que o app inicia
    loadGoals();
  }

  /// Carrega todas as metas do SharedPreferences para o estado
  Future<void> loadGoals() async {
    try {
      final dtos = await _localDataSource.listAll();
      state = DailyGoalMapper.toEntityList(dtos);
    } catch (e) {
      state = [];
    }
  }

  /// Adiciona ou atualiza uma meta no estado e persiste no SharedPreferences
  Future<void> upsertGoal(DailyGoalEntity goal) async {
    try {
      final dto = DailyGoalMapper.toDto(goal);
      await _localDataSource.upsertAll([dto]);

      // Atualiza o estado da UI de forma imutável
      final currentState = state;
      final index = currentState.indexWhere((g) => g.id == goal.id);

      if (index != -1) {
        // Atualiza item existente
        state = [
          ...currentState.sublist(0, index),
          goal,
          ...currentState.sublist(index + 1),
        ];
      } else {
        // Adiciona novo item
        state = [goal, ...currentState]; // Adiciona no início
      }
    } catch (e) {
      // Idealmente, logar o erro
      print('Erro ao salvar meta: $e');
    }
  }

  /// Método para a Feature 2: Incrementar meta de humor
  Future<void> incrementMoodEntryGoal(DateTime date) async {
    // Encontra a meta de "Registros de Humor" para a data específica
    final goalToUpdate = state.firstWhere(
      (goal) {
        final isMoodGoal = goal.type == GoalType.moodEntries;
        // Compara apenas Ano, Mês e Dia
        final isSameDay = goal.date.year == date.year &&
            goal.date.month == date.month &&
            goal.date.day == date.day;
        return isMoodGoal && isSameDay;
      },
      orElse: () =>
          DailyGoalEntity(
        id: '',
        userId: '',
        type: GoalType.moodEntries,
        targetValue: 1,
        currentValue: -1,
        date: date,
        isCompleted: false,
      ), // Retorna uma entidade "vazia" se não encontrar
    );

    // Se encontrou uma meta válida (currentValue >= 0)
    if (goalToUpdate.currentValue >= 0) {
      final updatedGoal = goalToUpdate.copyWith(
        currentValue: goalToUpdate.currentValue + 1,
      );
      // Salva a meta atualizada
      await upsertGoal(updatedGoal);
    }
  }
}

// 3. O Provider principal que a UI vai consumir
final dailyGoalRepositoryProvider =
    StateNotifierProvider<DailyGoalRepository, List<DailyGoalEntity>>((ref) {
  final localDataSource = ref.watch(dailyGoalLocalDtoProvider);
  return DailyGoalRepository(localDataSource);
});