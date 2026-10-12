import 'package:flutter/material.dart';

import 'menzil_theme.dart';

/// Closes the keyboard with a tap outside a text box and shows a small
/// "Bitti" bar above it (owner, 2026-10-12: the iOS number pad has no key
/// to close it, so the boxes under it could not be reached).
class KeyboardDoneBar extends StatelessWidget {
  final Widget child;
  const KeyboardDoneBar({super.key, required this.child});

  static void close() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final c = MenzilColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: close,
      child: Stack(
        children: [
          child,
          if (inset > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: inset,
              child: Material(
                key: const Key('keyboard-done-bar'),
                color: c.surface,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: close,
                      child: const Text('Bitti'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
