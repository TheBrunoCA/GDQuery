extends Node

const _bridge_cs := preload("uid://dji7tgoskfqor")


func execute(provider_name: String,
	connection_string: String,
	sql: String,
	parameters: Dictionary[String, Variant] = {},
	tx_handle: String = "") -> int:

		return _bridge_cs.Execute(provider_name,
			connection_string,
			sql,
			parameters,
			tx_handle)


func scalar(provider_name: String,
	connection_string: String,
	sql: String,
	parameters: Dictionary[String, Variant] = {},
	tx_handle: String = "") -> Variant:

		return _bridge_cs.Scalar(provider_name,
			connection_string,
			sql,
			parameters,
			tx_handle)


func query(provider_name: String,
	connection_string: String,
	sql: String,
	parameters: Dictionary[String, Variant] = {},
	tx_handle: String = "") -> Array[Dictionary]:

		return _bridge_cs.Query(provider_name,
			connection_string,
			sql,
			parameters,
			tx_handle)


func begin_transaction(provider_name: String, connection_string: String) -> String:
	return _bridge_cs.BeginTransaction(provider_name, connection_string)


func commit_transaction(handle:String) -> bool:
	return _bridge_cs.CommitTransaction(handle)


func rollback_transaction(handle:String) -> bool:
	return _bridge_cs.RollbackTransaction(handle)
