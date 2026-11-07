import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../theme/ph.dart';

class IosPage extends StatelessWidget {
  final String title;
  final bool largeTitle;
  final Widget? trailing;
  final List<Widget> children;
  final Widget? bottomBar;
  final ScrollController? controller;

  const IosPage({
    super.key,
    required this.title,
    required this.children,
    this.largeTitle = false,
    this.trailing,
    this.bottomBar,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final barColor = background.withValues(alpha: 0.86);
    final list = SliverPadding(
      padding: pagePadding(context, bottom: bottomBar == null ? 32 : 16),
      sliver: SliverList.list(children: children),
    );

    if (largeTitle) {
      return Scaffold(
        extendBody: bottomBar != null,
        body: CustomScrollView(
          controller: controller,
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(title),
              trailing: trailing,
              backgroundColor: barColor,
              border: null,
              transitionBetweenRoutes: false,
            ),
            list,
          ],
        ),
        bottomNavigationBar: bottomBar,
      );
    }

    return Scaffold(
      extendBody: bottomBar != null,
      appBar: CupertinoNavigationBar(
        middle: Text(title),
        trailing: trailing,
        backgroundColor: barColor,
        border: Border(
          bottom: BorderSide(color: context.tokens.rule, width: 0),
        ),
        transitionBetweenRoutes: false,
      ),
      body: CustomScrollView(controller: controller, slivers: [list]),
      bottomNavigationBar: bottomBar,
    );
  }
}

class GroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final double top;
  final double dividerIndent;

  const GroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.top = 24,
    this.dividerIndent = 16,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Semantics(
                header: true,
                child: Text(
                  header!,
                  style: textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Material(
            color: tokens.cell,
            borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(indent: dividerIndent, height: 0.5, thickness: 0.5),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(footer!, style: textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class GroupedRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  const GroupedRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (leading != null) ...[
                  ExcludeSemantics(child: leading!),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: textTheme.bodyLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(subtitle!, style: textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (value != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        value!,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(color: muted),
                      ),
                    ),
                  ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: trailing!,
                  )
                else if (onTap != null && chevron)
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Ph.caretRight,
                        size: 17,
                        color: muted.withValues(alpha: 0.6),
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

class DuotoneIcon extends StatelessWidget {
  final PhDuotone icon;
  final double size;
  final Color? color;

  const DuotoneIcon(this.icon, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Icon(
              icon.back,
              size: size,
              color: resolved?.withValues(alpha: 0.2),
            ),
            Icon(icon.front, size: size, color: resolved),
          ],
        ),
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const IconBadge(this.icon, {super.key, this.color, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? colorScheme.primary,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(icon, size: size * 0.6, color: colorScheme.onPrimary),
    );
  }
}

class CheckRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const CheckRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GroupedRow(
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        trailing: Icon(
          Ph.check,
          size: 20,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GroupedRow(
      title: title,
      onTap: () => onChanged(!value),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}

class PressScale extends StatefulWidget {
  final Widget child;

  const PressScale({super.key, required this.child});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? GlassTokens.pressedScale : 1,
        duration: motion(context, GlassTokens.durationFast),
        curve: GlassTokens.spring,
        child: widget.child,
      ),
    );
  }
}

/// Troque a key para animar de novo quando o conteúdo mudar.
class GlassEnter extends StatelessWidget {
  final Widget child;

  const GlassEnter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: motion(context, GlassTokens.durationNormal),
      curve: GlassTokens.spring,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: Transform.scale(scale: 0.95 + 0.05 * t, child: child),
        ),
      ),
    );
  }
}

/// [size] é a fração da tela em que a sheet abre.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double size = 0.55,
  bool startFull = false,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return GlassModalSheet.show<T>(
    context: context,
    halfSize: size,
    initialState: startFull ? GlassSheetState.full : GlassSheetState.half,
    barrierColor: GlassTokens.scrim(dark: dark),
    // O conteúdo das sheets usa InkWell e TextField, que pedem um Material acima.
    builder: (sheetContext) =>
        Material(type: MaterialType.transparency, child: builder(sheetContext)),
  );
}

class BottomActionBar extends StatelessWidget {
  final Widget child;

  const BottomActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final padding = pagePadding(context, bottom: 0);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding.left - 6, 0, padding.right - 6, 4),
        child: GlassContainer(
          shape: const LiquidRoundedSuperellipse(borderRadius: 32),
          padding: const EdgeInsets.all(6),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final double top;

  const SectionTitle(this.title, {super.key, this.top = 28});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

/// Link de texto alinhado à margem; o TextButton padrão fica recuado pelo padding.
class InlineLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const InlineLink(this.label, {super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          alignment: Alignment.centerLeft,
        ),
        child: Text(label),
      ),
    );
  }
}

class ChordName extends StatelessWidget {
  final String chord;
  final double size;
  final Color? color;

  const ChordName(this.chord, {super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      chord,
      style: TextStyle(
        fontFamily: fontChord,
        fontWeight: FontWeight.w600,
        fontSize: size,
        height: 1.1,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class StatusLine extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color? color;
  final TextAlign textAlign;

  const StatusLine({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(child: Icon(icon, size: 18, color: resolved)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: textAlign,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: resolved),
            ),
          ),
        ],
      ),
    );
  }
}

class SheetHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SheetHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (actionLabel != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAction ?? () => Navigator.of(context).pop(),
              child: Text(
                actionLabel ?? 'OK',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
