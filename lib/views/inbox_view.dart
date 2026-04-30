import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/models/chat_model.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/providers/chat_provider/chat_provider.dart';
import 'package:shiftipoz/providers/user_provider/user_provider.dart';
import 'package:shiftipoz/views/chats_view/chats_view.dart';
import 'dart:developer' as dev;

class InboxView extends ConsumerWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inboxAsync = ref.watch(inboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: inboxAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return _buildEmptyState(theme);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chats.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _InboxTile(chat: chat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: theme.hintColor.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text("No messages yet", style: TextStyle(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _InboxTile extends ConsumerWidget {
  final ChatModel chat;
  const _InboxTile({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print(chat.updatedAt);
    final theme = Theme.of(context);
    final myUid = ref.watch(authControllerProvider).value?.uid;

    // Find the other user's ID
    final otherUid = chat.participants.firstWhere(
      (id) => id != myUid,
      orElse: () => '',
    );

    // Watch the live profile of the other person
    final otherUserAsync = ref.watch(userProfileProvider(otherUid));

    final String formattedTime =
        "${chat.updatedAt.hour.toString().padLeft(2, '0')}:${chat.updatedAt.minute.toString().padLeft(2, '0')}";

    return ListTile(
      // Inside _InboxTile
      onTap: () {
        dev.log(
          "📦 Navigating from Inbox. Chat ID: ${chat.id}",
          name: "CHAT_DEBUG",
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatView(chat: chat)),
        );
      },
      leading: otherUserAsync.when(
        data: (user) => CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          backgroundImage: (user?.profilePic.isNotEmpty ?? false)
              ? NetworkImage(user!.profilePic)
              : null,
          child: (user?.profilePic.isEmpty ?? true)
              ? Icon(Icons.person, color: theme.colorScheme.primary)
              : null,
        ),
        loading: () => const CircleAvatar(
          radius: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) =>
            const CircleAvatar(radius: 28, child: Icon(Icons.error)),
      ),
      title: Text(
        otherUserAsync.value?.name ?? "Loading...",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        chat.lastMessage?['text'] ?? "Sent an attachment",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.hintColor),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          // Optional: Add unread badge here later
        ],
      ),
    );
  }
}
