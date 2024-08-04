import 'package:mongo_cron/mongo_cron.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final db = await Db.create('mongodb://localhost:27017/your_database');
  await db.open();

  final config = MongoCronConfig(
    database: db,
    onStart: (MongoCron cron) async {
      print('MongoCron started');
    },
    onStop: (MongoCron cron) async {
      print('MongoCron stopped');
    },
    onIdle: (MongoCron cron) async {
      print('MongoCron is idle');
    },
    onError: (dynamic error, MongoCron cron) async {
      print('Error occurred: $error');
      if (!db.isConnected) {
        print('MongoDB disconnected—reconnecting...');
        await db.close();
        await db.open();
        print('MongoDB reconnected');
      }
    },
    onJobStart: (Job job) async {
      print(
          '${DateTime.now().toIso8601String()} Job started: ${job.name} #${job.id}');
    },
    onJobComplete: (Job job) async {
      print(
          '${DateTime.now().toIso8601String()} Job complete: ${job.name} #${job.id}');
    },
  );

  final mongoCron = MongoCron(config);

  // Add a job
  await mongoCron.addJob(
    cronExpression: '*/5 * * * *',
    name: 'job1',
    handler: (Job job) async {
      print('Executing job ${job.id} with data: ${job.data}');
    },
    jobData: {'message': 'Hello, World!'},
  );

  await mongoCron.start();

  // You can add more jobs while it's running
  await mongoCron.addJob(
    cronExpression: '* * * * *',
    name: 'job2',
    handler: (Job job) async {
      print('Second job');
    },
  );

  // Run for while
  await Future.delayed(const Duration(seconds: 30));

  // Stop the cron
  await mongoCron.stop();
  await db.close();
}
