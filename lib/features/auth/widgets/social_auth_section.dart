import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nbts/features/auth/models/social_auth_provider.dart';

class SocialAuthSection extends StatelessWidget {
  const SocialAuthSection({
    super.key,
    required this.onProviderPressed,
    this.enabled = true,
  });

  final ValueChanged<SocialAuthProvider> onProviderPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: scheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or continue with',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(child: Divider(color: scheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                provider: SocialAuthProvider.google,
                enabled: enabled,
                onPressed: onProviderPressed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                provider: SocialAuthProvider.apple,
                enabled: enabled,
                onPressed: onProviderPressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.provider,
    required this.enabled,
    required this.onPressed,
  });

  final SocialAuthProvider provider;
  final bool enabled;
  final ValueChanged<SocialAuthProvider> onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = enabled ? scheme.onSurface : scheme.onSurfaceVariant;
    final borderColor = enabled
        ? scheme.outline.withValues(alpha: isDark ? 0.55 : 0.75)
        : scheme.outlineVariant.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onPressed(provider) : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: scheme.primary.withValues(alpha: 0.08),
        highlightColor: scheme.primary.withValues(alpha: 0.05),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            color: enabled
                ? scheme.surfaceContainerLowest
                : scheme.surfaceContainerLow.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: scheme.shadow.withValues(
                        alpha: isDark ? 0.22 : 0.07,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: scheme.shadow.withValues(
                        alpha: isDark ? 0.10 : 0.03,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : const [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ProviderMark(provider: provider, enabled: enabled),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    provider.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderMark extends StatelessWidget {
  const _ProviderMark({required this.provider, required this.enabled});

  final SocialAuthProvider provider;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: SvgPicture.asset(
          switch (provider) {
            SocialAuthProvider.google => 'assets/auth/icons8-google-50.svg',
            SocialAuthProvider.apple => 'assets/auth/icons8-apple-inc-50.svg',
          },
          width: 19,
          height: 19,
        ),
      ),
    );
  }
}
