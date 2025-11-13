extends Node

const _utils := preload("uid://fxvf2x7lkmf3")

const _empty_handle := ""


## Executes a non-query command (e.g., INSERT, UPDATE, DELETE) and returns the number of affected rows.
## Returns -1 on failure.
## [codeblock]
## var affected_rows = await GDQuery.execute_async(PROVIDER, CONN_STR, "DELETE FROM players WHERE score < 0")
## [/codeblock]
func execute_async(provider: String, connection_string: String, sql: String,
	params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> int:

	var job := GDQueryJob.new(GDBridge.execute.bind(provider, connection_string, sql, params, _empty_handle))
	job.run(high_priority)
	return await job.done


## Runs a query and returns the results as an Array of Dictionaries.
## [codeblock]
## var players = await GDQuery.query_async(PROVIDER, CONN_STR, "SELECT * FROM players")
## [/codeblock]
func query_async(provider: String, connection_string: String, sql: String,
	params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> Array[Dictionary]:

	var job := GDQueryJob.new(GDBridge.query.bind(provider, connection_string, sql, params, _empty_handle))
	job.run(high_priority)
	return await job.done


## Runs a query and maps the results to an Array of custom objects.
## Note: The returned type is [code]Array[Variant][/code], but each element will be an instance of the specified [param type].
## [codeblock]
## class_name PlayerData extends RefCounted:
##     var id: int
##     var name: String
##
## var players: Array = await GDQuery.map_query_async(PlayerData, PROVIDER, CONN_STR, "SELECT id, name FROM players")
## [/codeblock]
func map_query_async(type: GDScript, provider: String, connection_string: String, sql: String,
	params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> Array:

	var results := await query_async(provider, connection_string, sql, params, high_priority)
	var job := GDQueryJob.new(_utils.from_dict_array.bind(type, results))
	job.run(high_priority)
	return await job.done


## Executes a query and returns the first column of the first row in the result set.
## [codeblock]
## var player_count = await GDQuery.scalar_async(PROVIDER, CONN_STR, "SELECT COUNT(*) FROM players")
## [/codeblock]
func scalar_async(provider: String, connection_string: String, sql: String,
	params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> Variant:

	var job := GDQueryJob.new(GDBridge.scalar.bind(provider, connection_string, sql, params, _empty_handle))
	job.run(high_priority)
	return await job.done


## Begins a new database transaction and returns a [GDQueryTransaction] object.
## Remember to [method commit_async] or [method rollback_async] the transaction object.
## [codeblock]
## var tx = await GDQuery.begin_transaction_async(PROVIDER, CONN_STR)
## if tx.is_valid():
##     await tx.execute_async("UPDATE players SET score = 0")
##     await tx.commit_async()
## [/codeblock]
func begin_transaction_async(provider: String, connection_string: String, high_priority: bool = false) -> GDQueryTransaction:
	var job := GDQueryJob.new(GDBridge.begin_transaction.bind(provider, connection_string))
	job.run(high_priority)
	var handle: String = await job.done
	if handle.is_empty(): printerr("Failed to create transaction")
	return GDQueryTransaction.new(handle)
