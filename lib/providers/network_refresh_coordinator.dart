import 'package:dio/dio.dart';

/// Identifies one logical visible-network refresh (all sublayers for one set
/// of bounds). Only a ticket that is still current may mutate map state.
class NetworkRefreshTicket {
  final int generation;
  final CancelToken cancelToken;
  final NetworkRefreshCoordinator _owner;

  NetworkRefreshTicket._(this.generation, this.cancelToken, this._owner);

  /// False once a newer refresh began or the coordinator was invalidated.
  bool get isCurrent => _owner._currentGeneration == generation;

  /// True when no newer refresh has started, so this ticket's owner may still
  /// release shared state (e.g. a loading flag) even if it was invalidated.
  bool get isLatestStarted => _owner._latestStarted == generation;
}

/// Latest-wins coordinator for network refreshes triggered by map movement.
///
/// Starting a refresh cancels the in-flight HTTP work of the previous one and
/// marks its results stale. Callers must check [NetworkRefreshTicket.isCurrent]
/// after every await and before touching MapLibre.
class NetworkRefreshCoordinator {
  int _latestStarted = 0;
  int _currentGeneration = 0;
  CancelToken? _activeToken;

  NetworkRefreshTicket begin() {
    _cancelActive('superseded by newer refresh');
    final generation = ++_latestStarted;
    _currentGeneration = generation;
    final token = CancelToken();
    _activeToken = token;
    return NetworkRefreshTicket._(generation, token, this);
  }

  /// Marks any in-flight refresh stale and cancels its requests
  /// (style reload, disposal).
  void invalidate([String reason = 'invalidated']) {
    _cancelActive(reason);
    _currentGeneration = 0;
  }

  void dispose() => invalidate('disposed');

  void _cancelActive(String reason) {
    final token = _activeToken;
    if (token != null && !token.isCancelled) token.cancel(reason);
    _activeToken = null;
  }

  /// True for a request we cancelled on purpose (not a network failure).
  static bool isExpectedCancellation(Object error) =>
      error is DioException && CancelToken.isCancel(error);
}
