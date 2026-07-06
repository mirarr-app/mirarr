import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

class TvFocusModeManager {
  // Start with no rings, assuming the app is on mobile (false)
  static final ValueNotifier<bool> isTvFocusMode = ValueNotifier<bool>(false);
  static bool _isInitialized = false;
  static bool isTvDevice = false;
  static final FocusNode bottomBarFocusNode = FocusNode();

  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        isTvDevice = androidInfo.systemFeatures.contains('android.software.leanback');
      } catch (e) {
        // Fallback or log error
      }
    }

    // Listen globally to all physical and simulated key events (D-pad/keyboard/remotes)
    HardwareKeyboard.instance.addHandler((KeyEvent event) {
      if (!isTvFocusMode.value) {
        isTvFocusMode.value = true;
      }
      return false; // Do not consume the event, let the focus system handle it
    });
  }

  // Turn off focus mode immediately on any touch down gesture
  static void onPointerDown() {
    if (isTvFocusMode.value) {
      isTvFocusMode.value = false;
    }
  }

  // Request focus on the first focusable tab item inside the bottom bar
  static void focusBottomBar() {
    bottomBarFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final children = bottomBarFocusNode.descendants;
      for (final child in children) {
        if (child.canRequestFocus) {
          child.requestFocus();
          break;
        }
      }
    });
  }
}

class TvFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool autoFocus;
  final double borderRadius;

  const TvFocusWrapper({
    Key? key,
    required this.child,
    required this.onTap,
    this.focusNode,
    this.autoFocus = false,
    this.borderRadius = 20.0,
  }) : super(key: key);

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  late bool _tvFocusMode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _tvFocusMode = TvFocusModeManager.isTvFocusMode.value;
    TvFocusModeManager.isTvFocusMode.addListener(_onTvFocusModeChange);
  }

  @override
  void dispose() {
    TvFocusModeManager.isTvFocusMode.removeListener(_onTvFocusModeChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onTvFocusModeChange() {
    if (mounted) {
      setState(() {
        _tvFocusMode = TvFocusModeManager.isTvFocusMode.value;
      });
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      // Only scroll into view if focused and TV focus mode is currently active
      if (_focusNode.hasFocus && TvFocusModeManager.isTvFocusMode.value) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show focus rings and animations when D-pad/keyboard navigation mode is active
    final bool showHighlight = _isFocused && _tvFocusMode;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autoFocus,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: showHighlight ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: showHighlight
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: showHighlight
                    ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius - 3.0 > 0 ? widget.borderRadius - 3.0 : 0),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
