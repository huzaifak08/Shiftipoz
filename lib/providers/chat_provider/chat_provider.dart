import 'dart:io';
import 'package:flutter/material.dart'; // Added for BuildContext
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/chat_model.dart';
import 'package:shiftipoz/models/message_model.dart';
import 'package:shiftipoz/services/chat_service.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/views/chats_view/chats_view.dart';
import 'dart:developer' as dev;

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final inboxProvider = StreamProvider.autoDispose<List<ChatModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(chatServiceProvider).getInbox(user.uid);
});

final chatMessagesProvider = StreamProvider.family
    .autoDispose<List<MessageModel>, String>((ref, chatId) {
      if (chatId.isEmpty) {
        dev.log(
          "⚠️ Received empty chatId. Returning empty stream.",
          name: "chatMessagesProvider",
        );
        return Stream.value([]);
      }
      return ref.watch(chatServiceProvider).getMessages(chatId);
    });

final chatControllerProvider =
    StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
      return ChatController(ref);
    });

class ChatController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ChatController(this.ref) : super(const AsyncValue.data(null));

  ChatService get _service => ref.read(chatServiceProvider);

  /// Logic for entering a chat from a Product Detail page
  // Inside ChatController
  void navigateToChat({
    required BuildContext context,
    required String receiverId,
    required String receiverName, // Add this
    required String receiverImage, // Add this
    required Map<String, dynamic> productContext,
  }) {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final chatId = _service.getChatId(user.uid, receiverId);

    final chatShell = ChatModel(
      id: chatId,
      participants: [user.uid, receiverId],
      unreadCount: {user.uid: 0, receiverId: 0},
      lastSeenMessageId: {},
      isTyping: {},
      // Store temporary receiver info in the shell's metadata or active context
      activeProductContext: {
        ...productContext,
        'receiverName': receiverName,
        'receiverImage': receiverImage,
      },
      updatedAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatView(chat: chatShell)),
    );
  }

  Future<void> sendTextMessage({
    required String receiverId,
    required String text,
    Map<String, dynamic>? productContext,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || text.trim().isEmpty) return;

    final chatId = _service.getChatId(user.uid, receiverId);

    final message = MessageModel(
      id: '',
      senderId: user.uid,
      content: text.trim(),
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.sendMessage(
        chatId: chatId,
        message: message,
        receiverId: receiverId,
        productContext: productContext,
      ),
    );
  }

  Future<void> sendMediaMessage({
    required String receiverId,
    required File file,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final chatId = _service.getChatId(user.uid, receiverId);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final url = await _service.uploadChatMedia(file, chatId, type);
      final message = MessageModel(
        id: '',
        senderId: user.uid,
        content: url,
        timestamp: DateTime.now(),
        type: type,
        metadata: metadata,
      );
      await _service.sendMessage(
        chatId: chatId,
        message: message,
        receiverId: receiverId,
      );
    });
  }

  Future<void> updateReadStatus(String chatId, String lastMessageId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    await _service.markAsRead(chatId, user.uid, lastMessageId);
  }

  Future<void> toggleTyping(String chatId, bool isTyping) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    await _service.setTypingStatus(chatId, user.uid, isTyping);
  }
}
