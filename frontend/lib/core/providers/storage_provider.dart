import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';

final storageServiceProvider = FutureProvider<StorageService>(
  (ref) => StorageService.init(),
);
