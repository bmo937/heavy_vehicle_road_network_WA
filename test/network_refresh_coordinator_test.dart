import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/providers/network_refresh_coordinator.dart';

/// Adapter whose responses are completed manually, so ordering is deterministic.
class _ManualAdapter implements HttpClientAdapter {
  final Map<String, Completer<ResponseBody>> pending = {};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    final c = Completer<ResponseBody>();
    pending[options.path] = c;
    return c.future;
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _ok(String body) => ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: ['text/plain'],
    });

/// Mirrors the production pattern: fetch, check freshness, then apply.
Future<void> _refresh(Dio dio, NetworkRefreshCoordinator coordinator, String path, List<String> applied) async {
  final ticket = coordinator.begin();
  try {
    final response = await dio.get<String>(path, cancelToken: ticket.cancelToken);
    if (!ticket.isCurrent) return;
    applied.add(response.data!);
  } catch (e) {
    if (NetworkRefreshCoordinator.isExpectedCancellation(e)) return;
    rethrow;
  }
}

void main() {
  late _ManualAdapter adapter;
  late Dio dio;
  late NetworkRefreshCoordinator coordinator;
  late List<String> applied;

  setUp(() {
    adapter = _ManualAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    coordinator = NetworkRefreshCoordinator();
    applied = [];
  });

  tearDown(() => coordinator.dispose());

  test('current request succeeds and is applied', () async {
    final f = _refresh(dio, coordinator, 'A', applied);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    adapter.pending['A']!.complete(_ok('dataA'));
    await f;
    expect(applied, ['dataA']);
  });

  test('B completes first, then A: only B is applied', () async {
    final fa = _refresh(dio, coordinator, 'A', applied);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final fb = _refresh(dio, coordinator, 'B', applied);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    adapter.pending['B']!.complete(_ok('dataB'));
    await fb;
    adapter.pending['A']!.complete(_ok('dataA'));
    await fa;

    expect(applied, ['dataB']);
  });

  test('stale success is ignored even if the latest request fails', () async {
    final fa = _refresh(dio, coordinator, 'A', applied);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final fb = _refresh(dio, coordinator, 'B', applied);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    adapter.pending['B']!.completeError(DioException(requestOptions: RequestOptions(path: 'B'), type: DioExceptionType.connectionTimeout));
    await expectLater(fb, throwsA(isA<DioException>()));
    adapter.pending['A']!.complete(_ok('dataA'));
    await fa;

    expect(applied, isEmpty);
  });

  test('new request supersedes and cancels the previous one', () {
    final a = coordinator.begin();
    expect(a.isCurrent, isTrue);
    final b = coordinator.begin();
    expect(a.isCurrent, isFalse);
    expect(a.cancelToken.isCancelled, isTrue);
    expect(a.isLatestStarted, isFalse);
    expect(b.isCurrent, isTrue);
    expect(b.cancelToken.isCancelled, isFalse);
  });

  test('intentional cancellation is distinguished from real failures', () async {
    final fa = dio.get<String>('A', cancelToken: coordinator.begin().cancelToken);
    final errA = fa.then<Object>((_) => 'no error', onError: (Object e) => e);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    coordinator.begin();
    adapter.pending['A']!.complete(_ok('late')); // adapters may only notice cancellation on completion
    final cancelled = await errA;
    expect(NetworkRefreshCoordinator.isExpectedCancellation(cancelled), isTrue);

    final timeout = DioException(requestOptions: RequestOptions(path: 'x'), type: DioExceptionType.connectionTimeout);
    expect(NetworkRefreshCoordinator.isExpectedCancellation(timeout), isFalse);
    expect(NetworkRefreshCoordinator.isExpectedCancellation(Exception('boom')), isFalse);
  });

  test('invalidate marks in-flight work stale; dispose cancels it', () {
    final a = coordinator.begin();
    coordinator.invalidate('style reloaded');
    expect(a.isCurrent, isFalse);
    expect(a.isLatestStarted, isTrue);
    expect(a.cancelToken.isCancelled, isTrue);

    final b = coordinator.begin();
    coordinator.dispose();
    expect(b.isCurrent, isFalse);
    expect(b.cancelToken.isCancelled, isTrue);
  });
}
