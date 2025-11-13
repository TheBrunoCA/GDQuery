extends Node
const demo_class := preload("uid://vkvcdy2egm35")
func _ready() -> void:
	var provider = "Microsoft.Data.Sqlite"
	var connection_string = "Data Source=%s" % ProjectSettings.globalize_path("res://database.db")

	var sql = """
CREATE TABLE IF NOT EXISTS Players (
	Id INTEGER PRIMARY KEY AUTOINCREMENT,
	Name TEXT NOT NULL
)
"""
	await GDQuery.execute_async(provider, connection_string, sql, {})

	print(await GDQuery.query_async(provider, connection_string, "SELECT * FROM Players"))
	print(await GDQuery.scalar_async(provider, connection_string, "SELECT COUNT(*) FROM Players"))

	var tx := await GDQuery.begin_transaction_async(provider, connection_string)
	print(await tx.execute_async("INSERT INTO Players (Name) Values (@name)", {"@name":"Cabaço"}))

	#print(await tx.commit_async())
	print(await tx.query_async("SELECT * FROM Players"))
	var players := await tx.map_query_async(DemoClass ,"SELECT * FROM Players")
	print(players[0].Name)
	print(await tx.commit_async())
	players = await GDQuery.map_query_async(DemoClass, provider, connection_string, "SELECT * FROM Players")
	print(players[0].Name)
	print(await GDQuery.query_async(provider, connection_string, "SELECT (Name) FROM Players"))

	print(await GDQuery.execute_async(provider, connection_string, "DROP TABLE Players"))
