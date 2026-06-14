/// Riverpod providers that expose [StorageService] to the widget tree.
///
/// These providers handle storage initialization asynchronously so that
/// dependents (repositories, view models, UI) can access the storage layer
/// without managing its lifecycle directly.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';

/// A [FutureProvider] that asynchronously creates and caches a [StorageService]
/// instance.
///
/// The provider calls [StorageService.init] once and makes the resulting
/// service available throughout the application.  Because it is a
/// `FutureProvider`, consumers should use `ref.watch` with a
/// `.when`/`.maybeWhen` pattern (or an `AsyncValue` helper) to handle the
/// loading, data, and error states.
final storageServiceProvider = FutureProvider<StorageService>(
  (ref) => StorageService.init(),
);
