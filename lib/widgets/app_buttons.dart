import 'package:flutter/material.dart';

/// Common button styles and components for reuse across the app
class AppButtons {
  /// Primary extended floating action button for main actions
  static Widget extendedFloatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Builder(
      builder: (context) => FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        // Enhanced styling for consistency
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 8.0,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  /// Styled primary button
  static Widget primaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return Builder(
      builder: (context) => SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                ) 
              : Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            elevation: 4.0,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Styled danger/delete button
  static Widget dangerButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.red),
        label: Text(label, style: const TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: const BorderSide(color: Colors.red),
        ),
      ),
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
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        foregroundColor: textColor ?? Colors.white,
      ),
      child: Text(label),
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
  
  /// Image selection button
  static Widget imageSelectionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9),
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
} 