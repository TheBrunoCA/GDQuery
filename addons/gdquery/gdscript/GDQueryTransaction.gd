## Manages a database transaction.
##
## This object represents an active database transaction. Use it to execute commands
## and queries that belong together.
##
## To finalize the transaction, you must call either [method commit_async] or [method rollback_async].
##
## As a safety measure, if this object is freed before being manually finalized,
## it will automatically issue a rollback to prevent leaving the transaction open.
## A warning will be printed to the console if this occurs.
class_name GDQueryTransaction extends RefCounted

const _utils := preload("uid://fxvf2x7lkmf3")

const _empty_provider := ""
const _empty_connection_string := ""

var _handle: String
var _is_valid: bool = false

func _init(handle: String) -> void:
	_handle = handle
	_is_valid = not _handle.is_empty()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _is_valid:
			printerr("GDQuery: Transaction object was freed before being committed or rolled back. Rolling back automatically.")
			rollback_async()


## Returns [code]true[/code] if the transaction is active and has not been committed or rolled back.
func is_valid() -> bool: return _is_valid


## Executes a non-query command within this transaction. Returns the number of affected rows.
func execute_async(sql: String, params: Dictionary[String, Variant] = {},
	high_priority: bool = false) -> int:

	if not _is_valid: return -1
	var job := GDQueryJob.new(GDBridge.execute.bind(_empty_provider, _empty_connection_string, sql, params, _handle))
	job.run(high_priority)
	return await job.done


## Runs a query within this transaction and returns an Array of Dictionaries.
func query_async(sql: String, params: Dictionary[String, Variant] = {},
	high_priority: bool = false) -> Array[Dictionary]:

	if not _is_valid: return []
	var job := GDQueryJob.new(GDBridge.query.bind(_empty_provider, _empty_connection_string, sql, params, _handle))
	job.run(high_priority)
	return await job.done


## Runs a query within this transaction and maps the results to an Array of custom objects.
func map_query_async(type: GDScript, sql: String, params: Dictionary[String, Variant] = {},
	high_priority: bool = false) -> Array:

	var results: Array[Dictionary] = await query_async(sql, params, high_priority)
	var job := GDQueryJob.new(_utils.from_dict_array.bind(type, results))
	job.run(high_priority)
	return await job.done


## Executes a query within this transaction and returns a single value.
func scalar_async(sql: String, params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> Variant:

	if not _is_valid: return []
	var job := GDQueryJob.new(GDBridge.scalar.bind(_empty_provider, _empty_connection_string, sql, params, _handle))
	job.run(high_priority)
	return await job.done


## Commits all changes made in this transaction to the database.
## The transaction becomes invalid after this call.
func commit_async(high_priority: bool = false) -> bool:

	if not _is_valid: return false
	_is_valid = false
	var job := GDQueryJob.new(GDBridge.commit_transaction.bind(_handle))
	job.run(high_priority)
	return await job.done


## Rolls back all changes made in this transaction.
## The transaction becomes invalid after this call.
func rollback_async(high_priority: bool = false) -> bool:

	if not _is_valid: return false
	_is_valid = false
	var job := GDQueryJob.new(GDBridge.rollback_transaction.bind(_handle))
	job.run(high_priority)
	return await job.done
