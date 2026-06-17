/// IAP（应用内购买）提供者的 Riverpod 状态管理测试
/// 测试覆盖：无权益时 isPremium=false、iapStateProvider 在 init 后返回 ready 状态
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';

/// 伪 IapService，不实际连接 StoreKit
class FakeIapService implements IapService {
  final _stateCtrl = StreamController<IapState>.broadcast();
  IapState _state = const IapState();

  @override
  Stream<IapState> get stateStream => _stateCtrl.stream;
  @override
  IapState get state => _state;

  @override
  Future<void> init() async {
    // Emit after a tiny delay so StreamProvider can start listening first
    await Future.delayed(Duration.zero);
    _emit(IapState(status: IapStatus.ready));
  }

  @override
  Future<void> purchase(String productId) async {}
  @override
  Future<void> restore() async {}

  void _emit(IapState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  @override
  void dispose() => _stateCtrl.close();
}

void main() {
  // 没有任何权益时 isPremiumProvider 返回 false
  test('isPremiumProvider returns false with no entitlements', () async {
    final container = ProviderContainer(
      overrides: [iapServiceProvider.overrideWith((ref) => FakeIapService())],
    );
    addTearDown(container.dispose);

    // Give async init time to complete
    await Future.delayed(const Duration(milliseconds: 50));

    expect(container.read(isPremiumProvider), isFalse);
  });

  // iapStateProvider 在 init 完成后发出 ready 状态
  test('iapStateProvider emits ready after init', () async {
    final container = ProviderContainer(
      overrides: [iapServiceProvider.overrideWith((ref) => FakeIapService())],
    );
    addTearDown(container.dispose);

    // Listen to the stream before init resolves
    final future = container.read(iapStateProvider.future);
    final svc = container.read(iapServiceProvider);
    await svc.init(); // re-trigger after listener is attached
    final asyncValue = await future.timeout(const Duration(seconds: 2));
    expect(asyncValue.status, IapStatus.ready);
  });
}
