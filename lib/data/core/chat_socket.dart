import 'dart:async';

import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// The live half of chat.
///
/// An INTERFACE rather than the socket client directly, for the same reason
/// every repository here is one: a controller test must run with no network and
/// no platform channels. [SocketIoChatSocket] is the real thing; tests pass a
/// fake that pushes onto the same stream.
abstract class ChatSocket {
  /// Every message the server pushes to this user, for ALL their threads.
  ///
  /// The server broadcasts to a per-user room, so a caller watching one
  /// conversation must filter by [ChatMessage.conversationId] — see
  /// ChatRoomController. Broadcast, so the inbox and a room can both listen.
  Stream<ChatMessage> get incoming;

  /// Whether a live connection is currently established. The room falls back
  /// to polling while this is false, which is what makes the socket an
  /// optimisation rather than a single point of failure.
  bool get isConnected;

  /// Connection state changes, so a screen can restart polling when the socket
  /// drops rather than sitting silent.
  Stream<bool> get connectionChanges;

  /// Live conversation session status changes (paused/resumed).
  Stream<Map<String, dynamic>> get statusChanges;

  void connect();
  void disconnect();
}

/// Socket.io over the same origin as the REST API.
///
/// AUTH IS THE HANDSHAKE TOKEN, verified by the server with the same
/// `verifyBearerToken` the HTTP middleware uses — so a banned user is refused
/// here too, not just on REST.
class SocketIoChatSocket implements ChatSocket {
  SocketIoChatSocket({required String baseUrl, required TokenStore tokens})
    : _baseUrl = baseUrl,
      _tokens = tokens;

  final String _baseUrl;
  final TokenStore _tokens;

  io.Socket? _socket;

  final StreamController<ChatMessage> _incoming =
      StreamController<ChatMessage>.broadcast();
  final StreamController<bool> _connection = StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _statusChanges =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _connected = false;

  @override
  Stream<ChatMessage> get incoming => _incoming.stream;

  @override
  Stream<bool> get connectionChanges => _connection.stream;

  @override
  Stream<Map<String, dynamic>> get statusChanges => _statusChanges.stream;

  @override
  bool get isConnected => _connected;

  @override
  void connect() {
    final token = _tokens.accessToken;
    // No token means no session; connecting would only be refused. The room
    // keeps polling, which uses the same (absent) session and fails the same
    // way — one failure mode, not two.
    if (token == null || token.isEmpty || _socket != null) return;

    final socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          // WEBSOCKET ONLY. The default starts on HTTP long-polling and
          // upgrades, and that first poll is a plain XHR that our auth
          // handshake does not ride on cleanly through a proxy.
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) => _setConnected(true));
    socket.onDisconnect((_) => _setConnected(false));
    socket.onConnectError((err) {
      _setConnected(false);
      debugPrint('chat socket connect error: $err');
    });

    socket.on('message:new', (data) {
      if (data is! Map) return;
      try {
        _incoming.add(ChatMessage.fromJson(data.cast<String, dynamic>()));
      } catch (e) {
        // A payload this build cannot decode must not kill the stream — the
        // room still has polling behind it.
        debugPrint('chat socket decode failed: $e');
      }
    });

    socket.on('conversation:status', (data) {
      if (data is! Map) return;
      try {
        _statusChanges.add(data.cast<String, dynamic>());
      } catch (e) {
        debugPrint('chat socket status decode failed: $e');
      }
    });

    _socket = socket;
    socket.connect();
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    if (!_connection.isClosed) _connection.add(value);
  }

  @override
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _setConnected(false);
  }
}
