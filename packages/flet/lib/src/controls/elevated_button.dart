import 'package:flutter/material.dart';

import '../flet_control_backend.dart';
import '../models/control.dart';
import '../utils/buttons.dart';
import '../utils/icons.dart';
import '../utils/launch_url.dart';
import '../utils/others.dart';
import 'create_control.dart';
import 'cupertino_button.dart';
import 'cupertino_dialog_action.dart';
import 'error.dart';
import 'flet_store_mixin.dart';

class ElevatedButtonControl extends StatefulWidget {
  final Control? parent;
  final Control control;
  final List<Control> children;
  final bool parentDisabled;
  final bool? parentAdaptive;
  final FletControlBackend backend;

  const ElevatedButtonControl(
      {super.key,
      this.parent,
      required this.control,
      required this.children,
      required this.parentDisabled,
      required this.parentAdaptive,
      required this.backend});

  @override
  State<ElevatedButtonControl> createState() => _ElevatedButtonControlState();
}

class _ElevatedButtonControlState extends State<ElevatedButtonControl>
    with FletStoreMixin {
  late final FocusNode _focusNode;
  String? _lastFocusValue;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    widget.backend.triggerControlEvent(
        widget.control.id, _focusNode.hasFocus ? "focus" : "blur");
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Button build: ${widget.control.id}");
    bool disabled = widget.control.isDisabled || widget.parentDisabled;

    return withPagePlatform((context, platform) {
      bool? adaptive =
          widget.control.attrBool("adaptive") ?? widget.parentAdaptive;
      if (adaptive == true &&
          (platform == TargetPlatform.iOS ||
              platform == TargetPlatform.macOS)) {
        return widget.control.name == "action" &&
                (widget.parent?.type == "alertdialog" ||
                    widget.parent?.type == "cupertinoalertdialog")
            ? CupertinoDialogActionControl(
                control: widget.control,
                parentDisabled: widget.parentDisabled,
                parentAdaptive: adaptive,
                children: widget.children,
                backend: widget.backend)
            : CupertinoButtonControl(
                control: widget.control,
                parentDisabled: widget.parentDisabled,
                parentAdaptive: adaptive,
                children: widget.children,
                backend: widget.backend);
      }

      bool isFilledButton = widget.control.type == "filledbutton";
      bool isFilledTonalButton = widget.control.type == "filledtonalbutton";
      String text = widget.control.attrString("text", "")!;
      String url = widget.control.attrString("url", "")!;
      IconData? icon = parseIcon(widget.control.attrString("icon"));
      Color? iconColor = widget.control.attrColor("iconColor", context);
      var contentCtrls =
          widget.children.where((c) => c.name == "content" && c.isVisible);
      var clipBehavior =
          parseClip(widget.control.attrString("clipBehavior"), Clip.none)!;
      bool onHover = widget.control.attrBool("onHover", false)!;
      bool onLongPress = widget.control.attrBool("onLongPress", false)!;
      bool autofocus = widget.control.attrBool("autofocus", false)!;

      Function()? onPressed = !disabled
          ? () {
              debugPrint("Button ${widget.control.id} clicked!");
              if (url != "") {
                openWebBrowser(url,
                    webWindowName: widget.control.attrString("urlTarget"));
              }
              widget.backend.triggerControlEvent(widget.control.id, "click");
            }
          : null;

      Function()? onLongPressHandler = onLongPress && !disabled
          ? () {
              debugPrint("Button ${widget.control.id} long pressed!");
              widget.backend
                  .triggerControlEvent(widget.control.id, "long_press");
            }
          : null;

      Function(bool)? onHoverHandler = onHover && !disabled
          ? (state) {
              debugPrint("Button ${widget.control.id} hovered!");
              widget.backend.triggerControlEvent(
                  widget.control.id, "hover", state.toString());
            }
          : null;

      Widget? button;

      var theme = Theme.of(context);

      var style = parseButtonStyle(Theme.of(context), widget.control, "style",
          defaultForegroundColor: theme.colorScheme.primary,
          defaultBackgroundColor: theme.colorScheme.surface,
          defaultOverlayColor: theme.colorScheme.primary.withOpacity(0.08),
          defaultShadowColor: theme.colorScheme.shadow,
          defaultSurfaceTintColor: theme.colorScheme.surfaceTint,
          defaultElevation: 1,
          defaultPadding: const EdgeInsets.symmetric(horizontal: 8),
          defaultBorderSide: BorderSide.none,
          defaultShape: theme.useMaterial3
              ? const StadiumBorder()
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)));

      if (icon != null) {
        if (text == "") {
          return const ErrorControl("Error displaying ElevatedButton",
              description:
                  "\"icon\" must be specified together with \"text\".");
        }
        if (isFilledButton) {
          button = FilledButton.icon(
              style: style,
              autofocus: autofocus,
              focusNode: _focusNode,
              onPressed: onPressed,
              onLongPress: onLongPressHandler,
              onHover: onHoverHandler,
              clipBehavior: clipBehavior,
              icon: Icon(
                icon,
                color: iconColor,
              ),
              label: Text(text));
        } else if (isFilledTonalButton) {
          button = FilledButton.tonalIcon(
              style: style,
              autofocus: autofocus,
              focusNode: _focusNode,
              onPressed: onPressed,
              onLongPress: onLongPressHandler,
              onHover: onHoverHandler,
              clipBehavior: clipBehavior,
              icon: Icon(
                icon,
                color: iconColor,
              ),
              label: Text(text));
        } else {
          button = ElevatedButton.icon(
              style: style,
              autofocus: autofocus,
              focusNode: _focusNode,
              onPressed: onPressed,
              onLongPress: onLongPressHandler,
              onHover: onHoverHandler,
              clipBehavior: clipBehavior,
              icon: Icon(
                icon,
                color: iconColor,
              ),
              label: Text(text));
        }
      } else {
        Widget? child;
        if (contentCtrls.isNotEmpty) {
          child = createControl(widget.control, contentCtrls.first.id, disabled,
              parentAdaptive: adaptive);
        } else {
          child = Text(text);
        }

        if (isFilledButton) {
          button = FilledButton(
              style: style,
              autofocus: autofocus,
              focusNode: _focusNode,
              onPressed: onPressed,
              onLongPress: onLongPressHandler,
              onHover: onHoverHandler,
              clipBehavior: clipBehavior,
              child: child);
        } else if (isFilledTonalButton) {
          button = FilledButton.tonal(
              style: style,
              autofocus: autofocus,
              focusNode: _focusNode,
              onPressed: onPressed,
              onLongPress: onLongPressHandler,
              onHover: onHoverHandler,
              clipBehavior: clipBehavior,
              child: child);
        } else {
          button = ElevatedButton(
              style: style,
              autofocus: autofocus,
              focusNode: _focusNode,
              onPressed: onPressed,
              onLongPress: onLongPressHandler,
              onHover: onHoverHandler,
              clipBehavior: clipBehavior,
              child: child);
        }
      }

      var focusValue = widget.control.attrString("focus");
      if (focusValue != null && focusValue != _lastFocusValue) {
        _lastFocusValue = focusValue;
        _focusNode.requestFocus();
      }
      return constrainedControl(context, button, widget.parent, widget.control);
    });
  }
}
