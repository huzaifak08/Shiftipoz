import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/models/chat_model.dart';
import 'package:shiftipoz/models/message_model.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/providers/chat_provider/chat_provider.dart';

class ChatView extends ConsumerStatefulWidget {
  final ChatModel chat;
  const ChatView({super.key, required this.chat});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    Future.microtask(() {
      final myUid = ref.read(authControllerProvider).value?.uid;

      // Safety check to ensure we have messages and a valid UID
      if (myUid != null && widget.chat.lastMessage != null) {
        final lastMsgId = widget.chat.lastMessage?['id'] ?? '';

        // Resets unreadCount.$myUid to 0 in Firestore
        ref
            .read(chatServiceProvider)
            .markAsRead(widget.chat.id, myUid, lastMsgId);
      }
    });
    super.initState();
  }

  void _onSend() {
    if (_msgController.text.trim().isEmpty) return;
    final otherUid = widget.chat.participants.firstWhere(
      (id) => id != ref.read(authControllerProvider).value?.uid,
    );

    ref
        .read(chatControllerProvider.notifier)
        .sendTextMessage(
          receiverId: otherUid,
          text: _msgController.text,
          productContext: widget.chat.activeProductContext,
        );
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chat.id));
    final myUid = ref.watch(authControllerProvider).value?.uid;

    return Scaffold(
      appBar: _buildAppBar(theme, ref),
      body: Column(
        children: [
          _buildProductContextBar(theme),
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                controller: _scrollController,
                reverse: true, // Newest at bottom
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == myUid;

                  // Logic for Drop Avatar
                  final otherUid = widget.chat.participants.firstWhere(
                    (id) => id != myUid,
                  );
                  final bool showDropAvatar =
                      widget.chat.lastSeenMessageId[otherUid] == msg.id;

                  return _MessageBubble(
                    message: msg,
                    isMe: isMe,
                    showDropAvatar: showDropAvatar,
                    otherAvatarUrl:
                        "https://api.dicebear.com/7.x/avataaars/svg?seed=$otherUid",
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error loading chat")),
            ),
          ),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  // --- UI Components ---

  // Inside ChatView AppBar
  AppBar _buildAppBar(ThemeData theme, WidgetRef ref) {
    // Watch the live user data for online status

    return AppBar(
      elevation: 0,
      title: Row(
        children: [
          // 1. DYNAMIC PROFILE PIC
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage:
                (widget.chat.activeProductContext?['receiverImage'] != null &&
                    widget
                        .chat
                        .activeProductContext!['receiverImage']
                        .isNotEmpty)
                ? NetworkImage(
                    widget.chat.activeProductContext!['receiverImage'],
                  )
                : null,
            child: (widget.chat.activeProductContext?['receiverImage'] == null)
                ? Icon(Icons.person, color: theme.colorScheme.primary, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          // 2. DYNAMIC NAME & ONLINE STATUS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.activeProductContext?['receiverName'] ?? "User",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                // otherUserAsync.when(
                //   data: (user) {
                //     // Assuming your UserModel has an 'isOnline' field synced via Firestore
                //     final bool isOnline = user?.isOnline ?? false;
                //     return Text(
                //       isOnline ? "Online" : "Offline",
                //       style: theme.textTheme.bodySmall?.copyWith(
                //         color: isOnline ? Colors.green : theme.hintColor,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     );
                //   },
                //   loading: () => const SizedBox.shrink(),
                //   error: (_, __) => const SizedBox.shrink(),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContextBar(ThemeData theme) {
    if (widget.chat.activeProductContext == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.chat.activeProductContext!['image'],
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.activeProductContext!['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text("Discussing this item", style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
            ), // Add Image/Media
            IconButton(
              icon: const Icon(Icons.mic_none_rounded),
              onPressed: () {},
            ), // Hold to record
            Expanded(
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showDropAvatar;
  final String otherAvatarUrl;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showDropAvatar,
    required this.otherAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 20),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (showDropAvatar)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: CircleAvatar(
                radius: 9,
                backgroundImage: NetworkImage(otherAvatarUrl),
              ),
            ),
        ],
      ),
    );
  }
}
