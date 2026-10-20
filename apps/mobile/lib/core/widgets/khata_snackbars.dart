import 'package:flutter/material.dart';

/// Shows a red snackbar with an error message. Used across feature pages
/// for API/validation errors.
///
/// [message] is rendered verbatim, so the caller owns localization: pass an
/// already-localized string rather than a bare exception.
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

/// Shows a neutral snackbar for success confirmations.
void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// Confirms a save that did not reach the server and is waiting in the sync
/// queue. Deliberately not an error: the work is safe, it just has not left
/// the device yet, so the icon says "cloud off" rather than "failed".
void showQueuedOfflineSnackBar(BuildContext context, String message) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.cloud_upload_outlined,
              size: 18, color: theme.colorScheme.onInverseSurface),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}
