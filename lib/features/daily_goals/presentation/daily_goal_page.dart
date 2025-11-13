// Conteúdo para: lib/features/daily_goals/presentation/daily_goal_page.dart
// (Totalmente modificado para usar Riverpod e dados reais)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_journal/domain/entities/daily_goal_entity.dart';
import 'daily_goal_entity_form_dialog.dart';
import '../infrastructure/daily_goal_repository.dart'; // Importa o novo repositório

// 1. Mudar de StatefulWidget para ConsumerStatefulWidget
class DailyGoalListPage extends ConsumerStatefulWidget {
  const DailyGoalListPage({super.key, required this.entity});

  final String entity;

  @override
  ConsumerState<DailyGoalListPage> createState() => _DailyGoalListPageState();
}

class _DailyGoalListPageState extends ConsumerState<DailyGoalListPage>
    with SingleTickerProviderStateMixin {
  bool showTip = true;
  bool showTutorial = false;
  // 2. REMOVER a lista mockada: final List<dynamic> items = [];

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticInOut),
    );

    // 3. Checar se a lista está vazia após o build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(dailyGoalRepositoryProvider).isEmpty) {
        if (showTip) _fabController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 4. Obter a lista real do provider
    final List<DailyGoalEntity> items = ref.watch(dailyGoalRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entity),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // 5. Passar os itens reais para o _buildBody
              child: _buildBody(context, items),
            ),
          ),
          // ... (O resto do Stack com o tutorial overlay pode continuar o mesmo)
          if (showTutorial)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tutorial',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aqui você verá uma lista com ${widget.entity.toUpperCase()}s. Use o botão flutuante para adicionar.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => showTutorial = false),
                          child: const Text('Entendi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ... (O resto dos Positioned com o opt-out e tip bubble)
          Positioned(
            left: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: TextButton(
              onPressed: () => setState(() {
                showTip = false;
                _fabController.stop();
                _fabController.reset();
              }),
              child: const Text(
                'Não exibir dica novamente',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (showTip && items.isEmpty) // Só mostrar dica se a lista estiver vazia
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 72,
              child: AnimatedBuilder(
                animation: _fabController,
                builder: (context, child) {
                  final v = _fabController.value;
                  return Transform.translate(
                    offset: Offset(0, 10 * (1 - v)),
                    child: child,
                  );
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Toque aqui para adicionar ${widget.entity.toLowerCase()}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // 6. Atualizar o FAB OnPressed
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await showDailyGoalEntityFormDialog(context);

            if (result != null && mounted) {
              // 7. Chamar o repositório para salvar a meta
              await ref
                  .read(dailyGoalRepositoryProvider.notifier)
                  .upsertGoal(result);

              // Parar a animação do FAB se este foi o primeiro item
              if (items.length == 1) {
                _fabController.stop();
                _fabController.reset();
                setState(() {
                  showTip = false;
                });
              }
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // 8. Atualizar o _buildBody para aceitar a lista real
  Widget _buildBody(BuildContext context, List<DailyGoalEntity> items) {
    if (items.isEmpty) {
      // O estado vazio (igual ao original)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum ${widget.entity.toUpperCase()} cadastrado ainda.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Use o botão abaixo para criar o primeiro ${widget.entity.toLowerCase()}.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 9. Atualizar a lista para mostrar dados reais
    return ListView.separated(
      itemBuilder: (context, index) {
        final goal = items[index];
        return ListTile(
          leading: Text(goal.type.icon, style: const TextStyle(fontSize: 24)),
          title: Text(goal.type.description),
          subtitle: Text(
              'Progresso: ${goal.currentValue} / ${goal.targetValue}'),
          trailing: goal.isAchieved
              ? Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () async {
            // 10. Chamar a dialog para EDIÇÃO
            final updatedGoal = await showDailyGoalEntityFormDialog(
              context,
              initial: goal, // Passa a meta existente para edição
            );
            if (updatedGoal != null && mounted) {
              await ref
                  .read(dailyGoalRepositoryProvider.notifier)
                  .upsertGoal(updatedGoal);
            }
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: items.length,
    );
  }
}