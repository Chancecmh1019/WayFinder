// Local-only auth — no Firebase required
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalUser {
  final String uid;
  const LocalUser({required this.uid});
}

/// Always resolves to a local user immediately.
final authStateProvider = StreamProvider<LocalUser?>((ref) async* {
  yield const LocalUser(uid: 'local_user');
});
