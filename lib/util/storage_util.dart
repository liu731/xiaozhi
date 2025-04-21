import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xiaozhi/model/storage_message.dart';

class StorageUtil {
  static final String tableMessage = 'message';

  static final String tableMessageColumnId = 'id';

  static final String tableMessageColumnData = 'data';

  static final String tableMessageColumnSendByMe = 'send_by_me';

  static final String tableMessageColumnCreatedAt = 'created_at';

  late Database _database;

  static final StorageUtil _instance = StorageUtil._internal();

  factory StorageUtil() => _instance;

  StorageUtil._internal();

  Future<void> init() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'chat_database.db'),
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE $tableMessage($tableMessageColumnId TEXT PRIMARY KEY,$tableMessageColumnData TEXT,$tableMessageColumnSendByMe INTEGER,$tableMessageColumnCreatedAt INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertMessage(StorageMessage storageMessage) async {
    await _database.insert(
      tableMessage,
      storageMessage.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StorageMessage>> getPaginatedMessages({
    required int limit,
    required int offset,
  }) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      tableMessage,
      orderBy: '$tableMessageColumnCreatedAt DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((e) => StorageMessage.fromJson(e)).toList();
  }
}
