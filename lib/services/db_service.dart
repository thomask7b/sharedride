import 'package:objectid/objectid.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import '../models/user.dart';

const _userRecordKey = 'user';
const _sharedRideIdRecordKey = 'shared_ride_id';

late final Database _db;
final _store = StoreRef.main();

Future<void> initDb() async {
  var dir = await getApplicationDocumentsDirectory();
  await dir.create(recursive: true);
  _db = await databaseFactoryIo.openDatabase(join(dir.path, 'shared_ride.db'));
}

//User

Future saveUser(User user) {
  return _store.record(_userRecordKey).put(_db, user.toMap());
}

Future<User?> fetchUser() async {
  final result = await _store.record(_userRecordKey).get(_db);
  if (result != null) {
    return User.fromMap(result as Map<String, dynamic>);
  }
  return null;
}

Future deleteUser() {
  return _store.record(_userRecordKey).delete(_db);
}

//Shared ride ID

Future saveSharedRideId(ObjectId sharedRideId) {
  //TODO sauver le shared ride pour un user (inutile si on save directement le shared ride)
  return _store.record(_sharedRideIdRecordKey).put(_db, sharedRideId.hexString);
}

Future<ObjectId?> fetchSharedRideId() async {
  final result = await _store.record(_sharedRideIdRecordKey).get(_db);
  if (result != null) {
    return ObjectId.fromHexString(result);
  }
  return null;
}

Future deleteSharedRideId() {
  return _store.record(_sharedRideIdRecordKey).delete(_db);
}
