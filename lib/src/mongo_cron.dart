import 'dart:async';

import 'package:easy_cron/easy_cron.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'job.dart';
import 'mongo_cron_config.dart';

typedef JobHandler = Future<void> Function(Job job);

class MongoCron {
  final MongoCronConfig config;
  late DbCollection _collection;
  bool _running = false;
  bool _processing = false;
  bool _idle = false;
  Timer? _ticker;
  final Map<String, JobHandler> _handlers = {};

  MongoCron(this.config) {
    _collection = config.database.collection(config.collectionName);
  }

  Future<Job> addJob({
    required String cronExpression,
    required String name,
    required JobHandler handler,
    DateTime? repeatUntil,
    bool autoRemove = false,
    Map<String, dynamic>? jobData,
  }) async {
    final job = Job(
      name: name,
      cronExpression: cronExpression,
      repeatUntil: repeatUntil,
      autoRemove: autoRemove,
      data: jobData ?? {},
    );

    _handlers[job.name] = handler;

    await _collection.insertOne(job.toMap());
    return job;
  }

  Future<void> start() async {
    if (!_running) {
      _running = true;
      if (config.onStart != null) {
        await config.onStart!(this);
      }
      _scheduleTick();
    }
  }

  Future<void> stop() async {
    _running = false;
    _ticker?.cancel();
    while (_processing) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (config.onStop != null) {
      await config.onStop!(this);
    }
  }

  void _scheduleTick() {
    _ticker = Timer(config.nextDelay, _tick);
  }

  Future<void> _tick() async {
    if (!_running) return;

    _processing = true;
    try {
      final doc = await _lockNext();
      if (doc == null) {
        _processing = false;
        if (!_idle) {
          _idle = true;
          if (config.onIdle != null) {
            await config.onIdle!(this);
          }
        }
        await Future.delayed(config.idleDelay);
      } else {
        _idle = false;
        final job = Job.fromMap(doc);
        await _executeJob(job);
        await _reschedule(job);
        _processing = false;
      }
    } catch (e) {
      if (config.onError != null) {
        await config.onError!(e, this);
      } else {
        print('Error: $e');
      }
    }

    _scheduleTick();
  }

  Future<Map<String, dynamic>?> _lockNext() async {
    final now = DateTime.now();
    final lockUntil = now.add(config.lockDuration);

    final result = await _collection.findAndModify(
      query: {
        'sleepUntil': {'\$exists': true, '\$lte': now},
      },
      update: {
        '\$set': {'sleepUntil': lockUntil}
      },
      returnNew: false,
    );

    return result;
  }

  Future<void> _executeJob(Job job) async {
    config.onJobStart?.call(job);
    if (_handlers.containsKey(job.name)) {
      await _handlers[job.name]!(job).then((_) {
        config.onJobComplete?.call(job);
      });
    } else {
      print('No handler found for job: ${job.name}, ${job.id}');
    }
  }

  Future<void> _reschedule(Job job) async {
    final now = DateTime.now();
    final nextRun = _getNextRun(job, now);

    if (nextRun == null && job.autoRemove) {
      await _collection.deleteOne({'_id': job.id});
      _handlers.remove(job.name);
    } else if (nextRun == null) {
      await _collection.updateOne(
        {'_id': job.id},
        {
          '\$set': {'sleepUntil': null}
        },
      );
    } else {
      await _collection.updateOne(
        {'_id': job.id},
        {
          '\$set': {'sleepUntil': nextRun}
        },
      );
    }
  }

  DateTime? _getNextRun(Job job, DateTime fromTime) {
    try {
      final schedule = UnixCronParser().parse(job.cronExpression);
      final next = schedule.next(fromTime).time;
      if (job.repeatUntil != null && next.isAfter(job.repeatUntil!)) {
        return null;
      }
      return next;
    } catch (e) {
      print('Invalid cron expression: ${job.cronExpression}');
      return null;
    }
  }

  bool isRunning() => _running;

  bool isProcessing() => _processing;

  bool isIdle() => _idle;
}
