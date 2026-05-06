import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveDocumentToStorage({
  required String sourcePath,
  required String petId,
  required String fileName,
}) async {
  final appDir = await getApplicationDocumentsDirectory();
  final destDir = Directory('${appDir.path}/health_docs/$petId');
  await destDir.create(recursive: true);
  final destPath = '${destDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
  await File(sourcePath).copy(destPath);
  return destPath;
}

Future<bool> documentExists(String path) async => File(path).exists();

Future<void> deleteDocumentIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

Future<void> openDocumentFile(String path) async {
  await OpenFilex.open(path);
}

Future<String> copyFileToCustomReports(String sourcePath, String fileName) async {
  final appDir = await getApplicationDocumentsDirectory();
  final destDir = Directory('${appDir.path}/custom_reports');
  await destDir.create(recursive: true);
  final destPath = '${destDir.path}/$fileName';
  await File(sourcePath).copy(destPath);
  return destPath;
}

Future<List<int>?> readFileBytes(String path) async {
  final file = File(path);
  if (await file.exists()) return file.readAsBytes();
  return null;
}
