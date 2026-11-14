import 'dart:typed_data';

import 'package:zuraffa/zuraffa.dart';

import 'tesseract_exception.dart';
import 'tesseract_model.dart';
import 'tesseract_port.dart';
import 'tesseract_value.dart';

/// Facade over the [TesseractPort]: owns the loaded-model registry and turns
/// lifecycle mistakes (double load, recognize-before-load) into typed
/// failures before they reach the platform.
class TesseractService {
  final TesseractPort port;
  final Map<String, TesseractModel> _models = <String, TesseractModel>{};

  TesseractService({required this.port});

  /// The models currently held by this service.
  Set<String> get loadedModels => Set<String>.unmodifiable(_models.keys);

  Future<bool> supported() => port.isSupported();

  Future<TesseractModel> loadModel({
    required String id,
    required Uint8List bytes,
  }) async {
    if (_models.containsKey(id)) {
      throw TesseractException(
        'already_loaded',
        'Model "$id" is already loaded — unload it first.',
        recoverable: false,
      );
    }
    final model = await port.loadModel(id: id, bytes: bytes);
    _models[id] = model;
    return model;
  }

  Future<TesseractText> recognize({
    required String modelId,
    required TesseractRequest request,
  }) async {
    _requireLoaded(modelId);
    return port.recognize(modelId: modelId, request: request);
  }

  Future<void> unloadModel({required String id}) async {
    _requireLoaded(id);
    await port.unloadModel(id: id);
    _models.remove(id);
  }

  void _requireLoaded(String id) {
    if (!_models.containsKey(id)) {
      throw TesseractException(
        'not_loaded',
        'Model "$id" is not loaded — call loadModel() first.',
        recoverable: false,
      );
    }
  }
}

/// A port placeholder registered when no platform adapter was wired: every
/// operation surfaces the typed `port_not_wired` failure instead of a null
/// dereference at resolve time.
class _UnwiredTesseractPort implements TesseractPort {
  const _UnwiredTesseractPort();

  Never _unwired() => throw const TesseractException(
        'port_not_wired',
        'No TesseractPort was registered — wire the platform adapter '
        'for the running platform before resolving TesseractService.',
        recoverable: false,
      );

  @override
  Future<bool> isSupported() async => _unwired();

  @override
  Future<TesseractModel> loadModel({
    required String id,
    required Uint8List bytes,
  }) =>
      _unwired();

  @override
  Future<TesseractText> recognize({
    required String modelId,
    required TesseractRequest request,
  }) =>
      _unwired();

  @override
  Future<void> unloadModel({required String id}) => _unwired();
}

/// Registers the zuraffa_tesseract stack onto [getIt]: the [TesseractPort] is
/// normally supplied by the platform adapter package for the running platform
/// (e.g. `registerIosTesseractDependencies`), so the service falls back to the
/// GetIt-registered port when no explicit one is passed. Without any
/// registered port the service resolves over the unwired placeholder and
/// surfaces typed `port_not_wired` failures.
void registerTesseractDependencies(
  GetIt getIt, {
  TesseractPort? port,
}) {
  getIt.registerLazySingleton<TesseractService>(
    () => TesseractService(
      port: port ??
          (getIt.isRegistered<TesseractPort>()
              ? getIt<TesseractPort>()
              : const _UnwiredTesseractPort()),
    ),
  );
}