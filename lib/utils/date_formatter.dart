import 'package:intl/intl.dart';

class DateFormatter {
  /// Formats the chat inbox time:
  /// - Today: Show time (e.g., 11:39 PM)
  /// - Yesterday: Show "Yesterday"
  /// - This week: Show Day name (e.g., Monday)
  /// - Older: Show short date (e.g., 4/30/26)
  static String formatChatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final chatDate = DateTime(date.year, date.month, date.day);

    if (chatDate == today) {
      return DateFormat.jm().format(date); // 11:39 PM
    } else if (chatDate == yesterday) {
      return "Yesterday";
    } else if (now.difference(chatDate).inDays < 7) {
      return DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
    } else {
      return DateFormat.yMd().format(date); // 4/30/2026
    }
  }

  /// Formats message timestamps inside the ChatView (e.g., "11:40 PM")
  static String formatMessageTime(DateTime date) {
    return DateFormat.jm().format(date);
  }

  /// Full date for product listings or profile "Member since" (e.g., "April 2026")
  static String formatMonthYear(DateTime date) {
    return DateFormat.yMMMM().format(date);
  }

  /// Relative "Time Ago" for post listings (e.g., "5 mins ago", "2 hours ago")
  /// Note: For complex relative time, the 'timeago' package is better,
  /// but this is a solid manual implementation.
  static String timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);

    if (duration.inMinutes < 1) return "Just now";
    if (duration.inMinutes < 60) return "${duration.inMinutes}m ago";
    if (duration.inHours < 24) return "${duration.inHours}h ago";
    if (duration.inDays < 7) return "${duration.inDays}d ago";

    return DateFormat.yMMMd().format(date); // Apr 30, 2026
  }
}
