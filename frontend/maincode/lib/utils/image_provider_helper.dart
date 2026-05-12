// Exports the correct ImageProvider builder based on platform.
// Conditional export: mobile gets FileImage (reads from disk);
// web gets the stub which falls back to NetworkImage (blob URLs only).
export 'image_provider_stub.dart'
    if (dart.library.io) 'image_provider_io.dart';
