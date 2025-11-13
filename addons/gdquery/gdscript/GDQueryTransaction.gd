class_name GDQueryTransaction extends RefCounted

const _utils := preload("uid://fxvf2x7lkmf3")

const _empty_provider := ""
const _empty_connection_string := ""

var _handle: String
var _is_valid: bool = false

func _init(handle: String) -> void:
	_handle = handle
	_is_valid = not _handle.is_empty()


func is_valid() -> bool: return _is_valid


func execute_async(sql: String, params: Dictionary[String, Variant] = {},
	high_priority: bool = false) -> int:

	if not _is_valid: return -1
	var job := GDQueryJob.new(GDBridge.execute.bind(_empty_provider, _empty_connection_string, sql, params, _handle))
	job.run(high_priority)
	return await job.done


func query_async(sql: String, params: Dictionary[String, Variant] = {},
	high_priority: bool = false) -> Array[Dictionary]:

	if not _is_valid: return []
	var job := GDQueryJob.new(GDBridge.query.bind(_empty_provider, _empty_connection_string, sql, params, _handle))
	job.run(high_priority)
	return await job.done


func map_query_async(type: GDScript, sql: String, params: Dictionary[String, Variant] = {},
	high_priority: bool = false) -> Array:

	var results: Array[Dictionary] = await query_async(sql, params, high_priority)
	var job := GDQueryJob.new(_utils.from_dict_array.bind(type, results))
	job.run(high_priority)
	return await job.done


func scalar_async(sql: String, params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> Variant:

	if not _is_valid: return []
	var job := GDQueryJob.new(GDBridge.scalar.bind(_empty_provider, _empty_connection_string, sql, params, _handle))
	job.run(high_priority)
	return await job.done


func commit_async(high_priority: bool = false) -> bool:

	if not _is_valid: return false
	_is_valid = false
	var job := GDQueryJob.new(GDBridge.commit_transaction.bind(_handle))
	job.run(high_priority)
	return await job.done


func rollback_async(high_priority: bool = false) -> bool:

	if not _is_valid: return false
	_is_valid = false
	var job := GDQueryJob.new(GDBridge.rollback_transaction.bind(_handle))
	job.run(high_priority)
	return await job.done
