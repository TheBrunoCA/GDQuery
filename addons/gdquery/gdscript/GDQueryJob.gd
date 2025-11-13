class_name GDQueryJob extends RefCounted

signal done(result)

var _callable: Callable

func _init(callable: Callable) -> void:
	_callable = callable

func _thread_run() -> void: done.emit(_callable.call())

func run(high_priority: bool = false) -> void: WorkerThreadPool.add_task(_thread_run, high_priority)
