import 'dart:async';

import 'package:chia_crypto_utils/src/wallet_protocol/models/message.dart';

class Request {
  final Completer<ChiaProtocolMessage> _completer;
  void Function()? _releasePermit;

  Request(this._completer, this._releasePermit);

  void send(ChiaProtocolMessage message) {
    if (!_completer.isCompleted) {
      _completer.complete(message);
    }
  }
}

class RequestMap {
  final _items = <int, Request>{};
  final _semaphore = Semaphore(65535); // u16::MAX

  RequestMap();

  Future<int> insert(Request request) async {
    final permit = await _semaphore.acquire();

    // Remove completed requests
    _items.removeWhere((_, request) => request._completer.isCompleted);

    // Find first available index (0 to 65535 inclusive)
    final index = List<int>.generate(65536, (i) => i).firstWhere(
      (i) => !_items.containsKey(i),
      orElse: () => throw Exception('exceeded expected number of requests'),
    );

    // Store the request and associate the permit release
    request._releasePermit = permit.release;
    _items[index] = request;

    return index;
  }

  Request? remove(int id) {
    return _items.remove(id);
  }
}

// Helper Semaphore implementation since Dart doesn't have one built-in
class Semaphore {
  late final int _maxPermits;
  late int _currentPermits;
  final _waiters = <Completer<_SemaphorePermit>>[];

  Semaphore(int maxPermits) {
    _maxPermits = maxPermits;
    _currentPermits = maxPermits;
  }

  Future<_SemaphorePermit> acquire() async {
    if (_currentPermits > 0) {
      _currentPermits--;
      return _SemaphorePermit(this);
    }

    final completer = Completer<_SemaphorePermit>();
    _waiters.add(completer);
    return completer.future;
  }

  void _release() {
    if (_waiters.isEmpty) {
      _currentPermits++;
    } else {
      final waiter = _waiters.removeAt(0);
      waiter.complete(_SemaphorePermit(this));
    }
  }
}

class _SemaphorePermit {
  final Semaphore _semaphore;
  bool _released = false;

  _SemaphorePermit(this._semaphore);

  void release() {
    if (!_released) {
      _released = true;
      _semaphore._release();
    }
  }
}
