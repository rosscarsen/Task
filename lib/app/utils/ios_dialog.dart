import 'package:flutter/cupertino.dart';

Future iosDialog({
  required BuildContext context,
  required Widget content,
  required Widget titleWidget,
  String? cancelText,
  required String confirmText,
  void Function()? cancel,
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
            CupertinoDialogAction(child: Text(cancelText), onPressed: () => cancel ?? Navigator.pop(context)),
          CupertinoDialogAction(onPressed: confirm, child: Text(confirmText)),
        ],
      );
    },
  );
}
