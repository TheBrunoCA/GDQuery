# GDQuery

A simple and powerful library for running asynchronous database queries in Godot, inspired by Dapper.

It uses a C# backend to leverage ADO.NET providers, offering a clean GDScript API based on `async/await` for your game's logic.

---

## English

### Setup

1.  Install the plugin from the Godot Asset Library or by copying the `addons/gdquery` folder into your project's root.
2.  Enable the plugin in `Project -> Project Settings -> Plugins`. This will add the `GDQuery` autoload singleton.
3.  **This plugin requires the .NET version of Godot.**
    *   Compatible with Godot 4.5 and 4.6 dev.
4.  You must add the appropriate ADO.NET database provider to your C# project. For example, to use SQLite, add the `Microsoft.Data.Sqlite` NuGet package.

### Basic Usage

All operations are asynchronous and should be called with `await`.

**Provider and Connection String**

First, get your provider name and connection string. For SQLite, it would look like this:

```gdscript
const PROVIDER := "Microsoft.Data.Sqlite"
const CONNECTION_STRING := "Data Source=database.db"
```

**Running a Query**

To select records and get results as an array of dictionaries:

```gdscript
func get_players():
    var results = await GDQuery.query_async(
        PROVIDER,
        CONNECTION_STRING,
        "SELECT id, name, score FROM players WHERE score > @min_score",
        {"@min_score": 100}
    )
    for row in results:
        print("Player: %s, Score: %s" % [row.name, row.score])
```

**Executing a Command**

To `INSERT`, `UPDATE`, or `DELETE` records. Returns the number of affected rows.

```gdscript
func add_player(player_name):
    var affected_rows = await GDQuery.execute_async(
        PROVIDER,
        CONNECTION_STRING,
        "INSERT INTO players (name, score) VALUES (@name, @score)",
        {"@name": player_name, "@score": 0}
    )
    if affected_rows > 0:
        print("Player added successfully!")
```

**Mapping Results to a Class**

Automatically map query results to your own GDScript classes.

```gdscript
# Define your data class
class_name PlayerData extends RefCounted:
    var id: int
    var name: String
    var score: int

# Run the mapping query
func get_all_players_as_objects():
    # Note: While the array will contain instances of PlayerData,
    # GDScript's type system will show the returned array as Array[Variant].
    var players: Array[Variant] = await GDQuery.map_query_async(
        PlayerData,
        PROVIDER,
        CONNECTION_STRING,
        "SELECT id, name, score FROM players"
    )
    for player in players:
        print("Player object: %s" % player.name)

```

**Transactions**

Group multiple operations into a single transaction.

```gdscript
func transfer_score():
    var tx: GDQueryTransaction = await GDQuery.begin_transaction_async(PROVIDER, CONNECTION_STRING)
    if not tx.is_valid():
        printerr("Failed to start transaction.")
        return

    await tx.execute_async("UPDATE players SET score = score - 50 WHERE name = 'Bruno'")
    await tx.execute_async("UPDATE players SET score = score + 50 WHERE name = 'John'")

    var success = await tx.commit_async()
    if success:
        print("Transfer complete.")
    else:
        print("Transaction failed and was rolled back.")
```

As a safety measure, if a transaction object is freed before `commit_async()` or `rollback_async()` is called, it will be automatically rolled back to prevent open transactions.

---

## Português (BR)

### Instalação

1.  Instale o plugin pela Godot Asset Library ou copiando a pasta `addons/gdquery` para a raiz do seu projeto.
2.  Ative o plugin em `Projeto -> Configurações do Projeto -> Plugins`. Isso adicionará o autoload singleton `GDQuery`.
3.  **Este plugin requer a versão .NET do Godot.**
    *   Compatível com Godot 4.5 e 4.6 dev.
4.  Você deve adicionar o provedor de banco de dados ADO.NET ao seu projeto C#. Por exemplo, para usar SQLite, adicione o pacote NuGet `Microsoft.Data.Sqlite`.

### Uso Básico

Todas as operações são assíncronas e devem ser chamadas com `await`.

**Provider e Connection String**

Primeiro, defina o nome do seu provedor e a connection string. Para SQLite, seria algo assim:

```gdscript
const PROVIDER := "Microsoft.Data.Sqlite"
const CONNECTION_STRING := "Data Source=database.db"
```

**Executando uma Consulta (Query)**

Para selecionar registros e obter os resultados como um array de dicionários:

```gdscript
func get_players():
    var results = await GDQuery.query_async(
        PROVIDER,
        CONNECTION_STRING,
        "SELECT id, name, score FROM players WHERE score > @min_score",
        {"@min_score": 100}
    )
    for row in results:
        print("Jogador: %s, Pontos: %s" % [row.name, row.score])
```

**Executando um Comando (Execute)**

Para `INSERT`, `UPDATE` ou `DELETE`. Retorna o número de linhas afetadas.

```gdscript
func add_player(player_name):
    var affected_rows = await GDQuery.execute_async(
        PROVIDER,
        CONNECTION_STRING,
        "INSERT INTO players (name, score) VALUES (@name, @score)",
        {"@name": player_name, "@score": 0}
    )
    if affected_rows > 0:
        print("Jogador adicionado com sucesso!")
```

**Mapeando Resultados para uma Classe**

Mapeie automaticamente os resultados de uma consulta para suas próprias classes GDScript.

```gdscript
# Defina sua classe de dados
class_name PlayerData extends RefCounted:
    var id: int
    var name: String
    var score: int

# Execute a consulta com mapeamento
func get_all_players_as_objects():
    # Nota: Embora o array contenha instâncias de PlayerData,
    # o sistema de tipos do GDScript mostrará o array retornado como Array[Variant].
    var players: Array[Variant] = await GDQuery.map_query_async(
        PlayerData,
        PROVIDER,
        CONNECTION_STRING,
        "SELECT id, name, score FROM players"
    )
    for player in players:
        print("Objeto Player: %s" % player.name)
```

**Transações**

Agrupe múltiplas operações em uma única transação.

```gdscript
func transfer_score():
    var tx: GDQueryTransaction = await GDQuery.begin_transaction_async(PROVIDER, CONNECTION_STRING)
    if not tx.is_valid():
        printerr("Falha ao iniciar transação.")
        return

    await tx.execute_async("UPDATE players SET score = score - 50 WHERE name = 'Bruno'")
    await tx.execute_async("UPDATE players SET score = score + 50 WHERE name = 'John'")

    var success = await tx.commit_async()
    if success:
        print("Transferência completa.")
    else:
        print("A transação falhou e foi revertida.")
```

Como medida de segurança, se um objeto de transação for liberado antes que `commit_async()` ou `rollback_async()` seja chamado, um rollback automático será executado para evitar transações abertas.
