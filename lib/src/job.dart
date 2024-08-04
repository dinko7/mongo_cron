import 'package:mongo_dart/mongo_dart.dart';

class Job {
  final ObjectId id;
  final String name;
  final String cronExpression;
  final DateTime sleepUntil;
  final DateTime? repeatUntil;
  final bool autoRemove;
  final Map<String, dynamic> data;

  Job({
    ObjectId? id,
    required this.name,
    required this.cronExpression,
    DateTime? sleepUntil,
    this.repeatUntil,
    this.autoRemove = false,
    this.data = const {},
  })  : id = id ?? ObjectId(),
        sleepUntil = sleepUntil ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'cronExpression': cronExpression,
      'sleepUntil': sleepUntil,
      'repeatUntil': repeatUntil,
      'autoRemove': autoRemove,
      'data': data,
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['_id'] as ObjectId,
      name: map['name'] as String,
      cronExpression: map['cronExpression'] as String,
      sleepUntil: map['sleepUntil'] as DateTime,
      repeatUntil: map['repeatUntil'] as DateTime?,
      autoRemove: map['autoRemove'] as bool,
      data: Map<String, dynamic>.from(map['data'] as Map),
    );
  }
}
