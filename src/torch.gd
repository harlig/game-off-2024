class_name Torch extends Node3D;

func _ready() -> void:
    var seek_time := randf();
    $AnimationPlayer.seek(seek_time);
    print(seek_time);