// lib/services/save_utils.dart
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

String _inferMime(String ext) {
  switch (ext.toLowerCase()) {
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    default:
      return 'application/octet-stream';
  }
}
final _ms = MediaStore();

/// bytes를 안드로이드 'Download/YourSubfolder'에 저장
Future<SaveInfo?> saveBytesToDownloads({
  required Uint8List bytes,
  required String fileName,          // 예: '고압일지_헤더.xlsx' or 'report.pdf'
  String subfolder = 'ElectricInspection', // Download 하위 폴더명
}) async {
  // 1) 임시 파일로 먼저 저장
  final tmp = await getTemporaryDirectory();
  final tempFile = File('${tmp.path}/$fileName');
  await tempFile.writeAsBytes(bytes, flush: true);

  // 2) MediaStore 초기화 및 앱 폴더(선택) 설정
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = subfolder; // 또는 아래 relativePath만 써도 OK

  // 3) Download에 저장
  final info = await _ms.saveFile(
    tempFilePath: tempFile.path,
    dirType: DirType.download,      // ✅ 단수형
    dirName: DirName.download,      // ✅ 단수형
    relativePath: subfolder,        // Download/subfolder/ 에 저장
  );

  // info?.path는 API30+에서 null일 수 있어요. uriString을 신뢰하세요.
  // print('Saved path: ${info?.path}, uri: ${info?.uriString}');
  return info;
}