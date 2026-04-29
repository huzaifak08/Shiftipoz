import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final VoidCallback onPressed;
  const DeleteDialog({
    super.key,
    this.title,
    this.content,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? "Delete Listing?"),
      content: Text(
        content ??
            "This action cannot be undone. The product and its images will be permanently removed.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text("Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
