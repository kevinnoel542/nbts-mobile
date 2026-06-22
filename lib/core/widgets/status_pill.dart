import 'package:flutter/material.dart';
import 'package:nbts/core/theme/app_tokens.dart';

enum StatusKind { neutral, success, warning, danger }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.kind = StatusKind.neutral,
  });

  final String label;
  final IconData? icon;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (kind) {
      StatusKind.success => (
        AppStatus.success,
        AppStatus.success.withValues(alpha: 0.10),
      ),
      StatusKind.warning => (
        AppStatus.warning,
        AppStatus.warning.withValues(alpha: 0.10),
      ),
      StatusKind.danger => (
        scheme.primary,
        scheme.primary.withValues(alpha: 0.10),
      ),
      StatusKind.neutral => (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHigh,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
