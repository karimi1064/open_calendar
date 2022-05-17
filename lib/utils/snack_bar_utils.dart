import 'package:calendar_app/utils/app_colors.dart';
import 'package:calendar_app/utils/app_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:fluttertoast/fluttertoast.dart' as toast;

class SnackBarUtils {
  static void showBasicsFlash(
      {required BuildContext context,
      required String? message,
      String actionText = '',
      bool isError = true,
      bool isAction = false,
      Function? onPressAction,
      Duration? duration = const Duration(seconds: 4),
      flashStyle = FlashBehavior.floating,
      FlashPosition flashPosition = FlashPosition.bottom}) {
    showFlash(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flash(
          controller: controller,
          behavior: FlashBehavior.floating,
          position: flashPosition,
          borderRadius: BorderRadius.circular(20.0),
          backgroundColor: AppColors.lightGrey,
          forwardAnimationCurve: Curves.decelerate,
          reverseAnimationCurve: Curves.bounceIn,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: FlashBar(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            content: Text(
              message ?? (isError ? 'error'.tr() : ''),
              style: AppStyles.smallText14Style
                  .copyWith(color: isError ? AppColors.red : AppColors.green),
              textAlign: isAction ? TextAlign.start : TextAlign.center,
            ),
            primaryAction: isAction
                ? TextButton(
                    onPressed: () => onPressAction!(),
                    child: Text(actionText),
                  )
                : const SizedBox(),
          ),
        );
      },
    );
  }

  static void showToast(
      {required String message,
      toast.ToastGravity gravity = toast.ToastGravity.CENTER,
      toast.Toast toastLength = toast.Toast.LENGTH_SHORT,
      Color backgroundColor = AppColors.lightRed}) {
    toast.Fluttertoast.showToast(
        msg: message, // message
        toastLength: toastLength, // length
        gravity: gravity, // location
        backgroundColor: backgroundColor);
  }
}
