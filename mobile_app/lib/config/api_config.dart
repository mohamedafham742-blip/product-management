class ApiConfig {
  // Default Base URL
  // When phone is connected via USB cable (adb reverse tcp:8000 tcp:8000), 127.0.0.1 connects directly!
  static String get defaultBaseUrl {
    return 'http://127.0.0.1:8000/api';
  }

  // Endpoints
  static const String loginEndpoint = '/login';
  static const String userEndpoint = '/user';
  static const String logoutEndpoint = '/logout';
  static const String productsEndpoint = '/products';
  static const String recycleBinEndpoint = '/recycle-bin';
  static String restoreEndpoint(int id) => '/recycle-bin/$id/restore';
  static String forceDeleteEndpoint(int id) => '/recycle-bin/$id/force';
  static const String restoreAllEndpoint = '/recycle-bin/restore-all';
  static const String emptyTrashEndpoint = '/recycle-bin/empty';
}
