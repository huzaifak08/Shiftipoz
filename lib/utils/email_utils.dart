import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as dev;

Future<bool> sendProductInquiry({
  required String ownerEmail,
  required String productName,
  required String productType,
}) async {
  // 1. Construct the Subject and Body
  final String subject = Uri.encodeComponent(
    "Inquiry about Shiftipoz Product: $productName",
  );
  final String body = Uri.encodeComponent(
    "Hi, I saw your listing for '$productName' ($productType) on Shiftipoz and I'm interested. "
    "Is this still available? \n\nSent from Shiftipoz App.",
  );

  // 2. Create the mailto URI
  final Uri mailUri = Uri.parse(
    "mailto:$ownerEmail?subject=$subject&body=$body",
  );

  // 3. Launch the Email App
  try {
    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
      return true;
    } else {
      // Fallback if no email client is found
      dev.log("Could not launch email client", name: "Email Utils");
      return false;
    }
  } catch (e) {
    dev.log("Error launching email: $e");
    return false;
  }
}
