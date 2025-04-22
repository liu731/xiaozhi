import 'package:flutter/material.dart';
import 'package:xiaozhi/common/x_const.dart';
import 'package:xiaozhi/l10n/generated/app_localizations.dart';

class HoldToTalkWidget extends StatefulWidget {
  const HoldToTalkWidget({super.key});

  @override
  State<HoldToTalkWidget> createState() => HoldToTalkWidgetState();
}

class HoldToTalkWidgetState extends State<HoldToTalkWidget>
    with TickerProviderStateMixin {
  bool _isSpeaking = false;

  bool _canCancelTapUp = false;

  void setSpeaking(bool speaking) {
    if (speaking != _isSpeaking) {
      setState(() {
        _isSpeaking = speaking;
      });
    }
  }

  void setCancelTapUp(bool canCancelTapUp) {
    if (canCancelTapUp != _canCancelTapUp) {
      setState(() {
        _canCancelTapUp = canCancelTapUp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    if (!_isSpeaking) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.2), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SizedBox(
            width: mediaQuery.size.width - 48,
            child: TweenAnimationBuilder(
              tween: ColorTween(
                begin: Theme.of(context).colorScheme.primary,
                end:
                    _canCancelTapUp
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primary,
              ),
              duration: const Duration(milliseconds: 100),
              builder:
                  (context, value, child) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: value,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.saySomething,
                          style: TextStyle(
                            color: (_canCancelTapUp
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer
                                    : Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer)
                                .withValues(alpha: 0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.voiceRecognition,
                              style: TextStyle(
                                color: (_canCancelTapUp
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer
                                        : Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer)
                                    .withValues(alpha: 0.2),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Column(
              children: [
                AnimatedContainer(
                  width: _canCancelTapUp ? 60 : 0,
                  height: _canCancelTapUp ? 60 : 0,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  duration: const Duration(milliseconds: 100),
                  child:
                      _canCancelTapUp
                          ? Icon(
                            Icons.close_rounded,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          )
                          : null,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder(
                      tween: ColorTween(
                        begin: Theme.of(context).colorScheme.surfaceContainer,
                        end:
                            _canCancelTapUp
                                ? Theme.of(context).colorScheme.surfaceContainer
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                      duration: const Duration(milliseconds: 100),
                      builder:
                          (context, value, child) => CustomPaint(
                            size: Size(
                              mediaQuery.size.width,
                              XConst.holdToTalkResponseAreaHeight +
                                  mediaQuery.padding.bottom,
                            ),
                            painter: _OvalRectangle(color: value!),
                          ),
                    ),
                    TweenAnimationBuilder(
                      tween: ColorTween(
                        begin: Theme.of(context).colorScheme.surfaceContainer,
                        end:
                            !_canCancelTapUp
                                ? Theme.of(context).colorScheme.surfaceContainer
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                      duration: const Duration(milliseconds: 100),
                      builder:
                          (context, value, child) => Column(
                            children: [
                              Icon(
                                Icons.record_voice_over_rounded,
                                size: 24,
                                color: value,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                !_canCancelTapUp
                                    ? AppLocalizations.of(
                                      context,
                                    )!.swipeUpToCancel
                                    : AppLocalizations.of(
                                      context,
                                    )!.swipeInToResume,
                                style: TextStyle(color: value),
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OvalRectangle extends CustomPainter {
  final Color color;

  _OvalRectangle({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path =
        Path()
          ..moveTo(0, 24)
          ..quadraticBezierTo(size.width / 2, -24, size.width, 24)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
