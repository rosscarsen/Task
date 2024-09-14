import 'package:flutter/cupertino.dart';

iosDialog({
  required BuildContext context,
  required Widget content,
  required Widget titleWidget,
  String? cancelText,
  required String confirmText,
  void Function()? candel,
  required void Function() confirm,
}) {
  return showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: titleWidget,
        content: content,
        actions: [
          if (cancelText != null)
            CupertinoDialogAction(
              child: Text(cancelText),
              onPressed: () => candel ?? Navigator.pop(context),
            ),
          CupertinoDialogAction(
            onPressed: confirm,
            child: Text(confirmText),
          )
        ],
      );
    },
  );
}
