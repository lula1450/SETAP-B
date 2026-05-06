Future<String> saveDocumentToStorage({
  required String sourcePath,
  required String petId,
  required String fileName,
}) async => '';

Future<bool> documentExists(String path) async => false;

Future<void> deleteDocumentIfExists(String path) async {}

Future<void> openDocumentFile(String path) async {}

Future<String> copyFileToCustomReports(String sourcePath, String fileName) async => '';

Future<List<int>?> readFileBytes(String path) async => null;
