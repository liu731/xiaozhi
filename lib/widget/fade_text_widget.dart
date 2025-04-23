import 'package:flutter/material.dart';

class FadeTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const FadeTextWidget({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<FadeTextWidget> createState() => _FadeTextWidgetState();
}

class _FadeTextWidgetState extends State<FadeTextWidget> {
  String _currentText = '';
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _currentText = widget.text;
  }

  @override
  void didUpdateWidget(covariant FadeTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _triggerTextChange(widget.text);
    }
  }

  void _triggerTextChange(String newText) async {
    setState(() => _opacity = 0.0);
    await Future.delayed(widget.duration);
    setState(() {
      _currentText = newText;
      _opacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.duration,
      child: Text(_currentText, style: widget.style),
    );
  }
}
