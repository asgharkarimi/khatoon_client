import 'package:flutter/material.dart';

/// Common button styles and components for reuse across the app
class AppButtons {
  /// Primary extended floating action button for main actions
  static Widget extendedFloatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      // You can customize the styling here:
      // backgroundColor: Colors.orange,
      // foregroundColor: Colors.white,
      // elevation: 6.0,
    );
  }

  /// Styled primary button
  static Widget primaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading ? const CircularProgressIndicator() : Icon(icon),
      label: Text(label),
      // You can customize the styling here
    );
  }

  /// Styled danger/delete button
  static Widget dangerButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.red),
      label: Text(label, style: const TextStyle(color: Colors.red)),
      // You can customize the styling here
    );
  }

  /// Simple text button for dialogs
  static Widget textButton({
    required VoidCallback onPressed,
    required String label,
    Color? textColor,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: textColor != null ? TextStyle(color: textColor) : null,
      ),
    );
  }

  /// Danger text button for dialogs (for destructive actions)
  static Widget dangerTextButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return textButton(
      onPressed: onPressed,
      label: label,
      textColor: Colors.red,
    );
  }
} 