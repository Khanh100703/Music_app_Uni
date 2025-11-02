
// Lightweight extension that doesn't modify your original class file.
// Adds: safePrepare() to call your prepare() without fearing duplicates.
import 'audio_player_manager.dart' show AudioPlayerManager;

extension MiniPlayerPrepare on AudioPlayerManager {
  static bool _preparedGuard = false;

  /// Call your `prepare()` once, safely.
  void safePrepare() {
    if (_preparedGuard) return;
    _preparedGuard = true;
    try {
      // If your class renamed `init` -> `prepare`, this will work.
      // If your `prepare()` is already idempotent, even better.
      // NOTE: If your prepare() requires BuildContext or async, wire that accordingly.
      // Here we assume it is sync starter like setting streams.
      // If your prepare is async, you can change to `unawaited(prepareAsync());`.
      // But keep this as a tiny no-dependency shim.
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      // We simply call it and swallow if not available in some refactors.
      // If you don't want try/catch, remove it and call prepare() directly.
      // However, having the guard keeps MiniPlayer usage painless.
      // Dart will error if prepare() doesn't exist; keep your original prepare().
      // If your method is named differently, replace here.
      // @ts-ignore (comment for clarity)
      // call the method:
      // (no reflection in Dart; we assume the method exists)
      // So just:
      // ignore: unnecessary_statements
      this.prepare();
    } catch (_) {
      // If for any reason the method signature differs, you can:
      // - call a different method name here, or
      // - remove safePrepare() and call your init path manually before showing MiniPlayer.
    }
  }
}
