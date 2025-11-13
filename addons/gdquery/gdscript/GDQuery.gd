extends Node

const _utils := preload("uid://fxvf2x7lkmf3")

const _empty_handle := ""


func execute_async(provider: String, connection_string: String, sql: String,
	params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> int:

	var job := GDQueryJob.new(GDBridge.execute.bind(provider, connection_string, sql, params, _empty_handle))
	job.run(high_priority)
	return await job.done


func query_async(provider: String, connection_string: String, sql: String,
	params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> Array[Dictionary]:

	var job := GDQueryJob.new(GDBridge.query.bind(provider, connection_string, sql, params, _empty_handle))
	job.run(high_priority)
	return await job.done


func map_query_async(type: GDScript, provider: String, connection_string: String, sql: String,
	params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> Array:

	var results := await query_async(provider, connection_string, sql, params, high_priority)
	var job := GDQueryJob.new(_utils.from_dict_array.bind(type, results))
	job.run(high_priority)
	return await job.done


func scalar_async(provider: String, connection_string: String, sql: String,
	params: Dictionary[String, Variant] = {}, high_priority: bool = false) -> Variant:

	var job := GDQueryJob.new(GDBridge.scalar.bind(provider, connection_string, sql, params, _empty_handle))
	job.run(high_priority)
	return await job.done


func begin_transaction_async(provider: String, connection_string: String, high_priority: bool = false) -> GDQueryTransaction:
	var job := GDQueryJob.new(GDBridge.begin_transaction.bind(provider, connection_string))
	job.run(high_priority)
	var handle: String = await job.done
	if handle.is_empty(): printerr("Failed to create transaction")
	return GDQueryTransaction.new(handle)
