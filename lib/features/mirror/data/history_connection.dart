// How the history database is opened: encrypted on the platforms with a file system, as browsers store it on the web.
export 'history_connection_io.dart' if (dart.library.js_interop) 'history_connection_web.dart';
