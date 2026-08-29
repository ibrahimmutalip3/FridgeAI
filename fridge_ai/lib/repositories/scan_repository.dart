import 'dart:io';

import '../models/scan_result.dart';
import '../services/groq_service.dart';
import '../services/storage_service.dart';

/// Repository for the AI food-scanning flow. Wraps [GroqService] for the
/// vision call and records the "ingredients scanned" stat via
/// [StorageService] on success.
class ScanRepository {
  ScanRepository({GroqService? groqService, StorageService? storage})
      : _groqService = groqService ?? GroqService(),
        _storage = storage ?? StorageService.instance;

  final GroqService _groqService;
  final StorageService _storage;

  Future<ScanResult> analyzeImage(File imageFile) async {
    final result = await _groqService.analyzeFoodImage(imageFile);
    if (result.success && result.ingredients.isNotEmpty) {
      await _storage.incrementIngredientsScanned(result.ingredients.length);
    }
    return result;
  }

  void dispose() => _groqService.dispose();
}
