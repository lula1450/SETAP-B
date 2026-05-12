// Exports the correct file I/O implementation based on platform.
// Conditional export: mobile (dart:io available) gets the real implementation;
// web gets the stub which returns safe no-ops since dart:io is unavailable there.
export 'file_io_stub.dart'
    if (dart.library.io) 'file_io_impl.dart';
