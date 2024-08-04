import 'package:mongo_cron/src/job.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'mongo_cron.dart';

class MongoCronConfig {
  final Db database;
  final String collectionName;
  final Duration nextDelay;
  final Duration reprocessDelay;
  final Duration idleDelay;
  final Duration lockDuration;
  final Future<void> Function(MongoCron cron)? onStart;
  final Future<void> Function(MongoCron cron)? onStop;
  final Future<void> Function(MongoCron cron)? onIdle;
  final Future<void> Function(dynamic error, MongoCron cron)? onError;
  final Future<void> Function(Job job)? onJobStart;
  final Future<void> Function(Job job)? onJobComplete;

  MongoCronConfig({
    required this.database,
    this.collectionName = 'cron_jobs',
    this.nextDelay = Duration.zero,
    this.reprocessDelay = Duration.zero,
    this.idleDelay = Duration.zero,
    this.lockDuration = const Duration(minutes: 10),
    this.onStart,
    this.onStop,
    this.onIdle,
    this.onError,
    this.onJobStart,
    this.onJobComplete,
  });
}
