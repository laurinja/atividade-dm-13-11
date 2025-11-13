# Apresentação: Features de Daily Goals

**Aluno:** Laura Bareto
**Repositório:** github.com/laurinja/atividade-dm-13-11

---

## 1. Sumário Executivo

[cite_start]Este documento detalha a implementação das features da funcionalidade "Daily Goals" (Metas Diárias) do projeto MoodJournal, partindo da base de layout e persistência fornecida [cite: 125-128].

A **Feature 1 (Concluída)** conecta a interface de usuário (UI) à persistência local. A tela de listagem de metas agora é funcional, permitindo carregar, criar, editar e persistir metas no SharedPreferences usando a arquitetura Riverpod.

A **Feature 2 (Em Desenvolvimento)** tratará da integração automática entre o registro de humor e o progresso das metas diárias.

## 2. Arquitetura e Fluxo de Dados

A arquitetura segue o padrão MVVM (Model-View-ViewModel) utilizando **Riverpod** para gerenciamento de estado e injeção de dependência. O fluxo de dados da UI para a persistência local (Feature 1) é o seguinte:



1.  **View (`DailyGoalListPage`):** A tela, agora um `ConsumerStatefulWidget`, "observa" (`ref.watch`) o provider principal.
2.  **ViewModel/Provider (`dailyGoalRepositoryProvider`):** Este `StateNotifierProvider` expõe a lista atual de metas (`List<DailyGoalEntity>`).
3.  **Repository (`DailyGoalRepository`):** Quando a UI dispara uma ação (ex: `upsertGoal`), o repositório é chamado.
4.  **Mapper (`DailyGoalMapper`):** O repositório usa o mapper para converter a `DailyGoalEntity` (domínio) em um `DailyGoalDto` (dados).
5.  **Data Source (`DailyGoalLocalDto`):** O repositório injeta a fonte de dados local, que é implementada pelo `DailyGoalLocalDtoSharedPrefs` para salvar os dados no SharedPreferences.
6.  **Rebuild:** A mudança no estado do provider faz a UI reconstruir automaticamente, exibindo a meta nova ou atualizada.

## 3. Detalhes das Features Implementadas

---

### Feature 1: Conexão da UI com Persistência Local (Concluída)

* **Objetivo:** Tornar a tela `DailyGoalListPage` funcional, permitindo ao usuário ver, criar e editar metas diárias que persistem localmente no dispositivo após o fechamento do app.

* **Como Testar Localmente:**
    1.  Execute o aplicativo. A `HomeScreen` (conforme modificada pelo professor) irá carregar a `DailyGoalListPage`.
    2.  A tela deve exibir a mensagem "Nenhum METAS DIÁRIAS cadastrado ainda."
    3.  Clique no FAB (+). A dialog de criação será aberta.
    4.  Preencha os campos (Ex: ID "1", UserID "user1", Tipo "Registros de Humor", Alvo 1).
    5.  Clique em "Adicionar".
    6.  Verifique se a UI atualiza e a meta "Registros de Humor" (Progresso: 0 / 1) aparece na lista.
    7.  Clique na meta recém-criada. A dialog deve reabrir com os dados preenchidos.
    8.  Altere o "Valor alvo" para 5 e clique em "Salvar".
    9.  Verifique se a lista atualiza para "Progresso: 0 / 5".
    10. Feche e reinicie o aplicativo (Hot Restart ou fechar e reabrir).
    11. Verifique se a meta "0 / 5" foi carregada do SharedPreferences e ainda está na lista.

* **Limitações e Riscos:**
    * A implementação `DailyGoalLocalDtoSharedPrefs` lê e reescreve a lista JSON inteira a cada salvamento. Isso é aceitável para poucas metas, mas pode se tornar lento se o usuário tiver centenas de registros.

---

### Feature 2: Integração de Registro de Humor com Metas (Em Desenvolvimento)

* **Objetivo:** Atualizar automaticamente o progresso (`currentValue`) da Meta Diária do tipo `GoalType.moodEntries` sempre que um novo `MoodEntry` for salvo no dia correspondente.
* **Status:** Em desenvolvimento. A infraestrutura (método `incrementMoodEntryGoal` no `DailyGoalRepository`) está pronta, mas a conexão com a UI de registro de humor (Passos 3, 4 e 5) ainda não foi implementada.

## 4. Roteiro de Apresentação Oral (Parcial)

1.  **Introdução:** Apresentar o objetivo da atividade (completar 2 features) e o status atual (Feature 1 concluída).
2.  **Arquitetura (Slide/Diagrama):** Explicar o fluxo de dados com Riverpod (View -> Notifier -> Repository -> Local DTO). Mostrar o diagrama de fluxo.
3.  **Demo - Feature 1 (Conexão UI):**
    * Mostrar o app abrindo com a lista vazia (estado inicial).
    * Criar uma meta usando o FAB e a dialog.
    * Mostrar que ela aparece na lista (UI reagindo ao estado).
    * Editar a meta (mudar o Alvo de 1 para 5).
    * Mostrar que ela atualiza.
    * Reiniciar o app e mostrar que a meta persistiu (prova de que o SharedPreferences funcionou).
    * *Código-chave:* Mostrar o `daily_goal_repository.dart` (método `upsertGoal`) e o `daily_goal_page.dart` (o `ref.watch` e o `onPressed` do FAB).
4.  **(Aguardando Implementação) Demo - Feature 2:** (A ser apresentado após a conclusão dos próximos passos).