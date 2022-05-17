import 'package:calendar_app/utils/app_colors.dart';
import 'package:calendar_app/utils/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AppRoundedButton extends StatefulWidget {
  final bool isLoading;
  final bool withOpacity;
  final bool isBorder;
  final Color color;
  final Color textColor;
  final String text;
  final VoidCallback? onPressed;
  final double radius;
  final TextStyle? textStyle;

  const AppRoundedButton(
      {Key? key,
      required this.text,
      this.onPressed,
      this.color = AppColors.darkBlue,
      this.textColor = AppColors.white,
      this.isLoading = false,
      this.withOpacity = false,
      this.isBorder = false,
      this.radius = 30,
      this.textStyle})
      : super(key: key);

  @override
  _AppRoundedButtonState createState() => _AppRoundedButtonState();
}

class _AppRoundedButtonState extends State<AppRoundedButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        style: ButtonStyle(
          elevation: MaterialStateProperty.all(0),
          backgroundColor: MaterialStateProperty.all((widget.withOpacity)
              ? widget.color.withOpacity(0.3)
              : widget.color),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.radius),
              side: BorderSide(
                  color: widget.isBorder ? widget.textColor : widget.color),
            ),
          ),
        ),
        onPressed: () => widget.onPressed?.call(),
        child: widget.isLoading
            ? const Center(
                child: SpinKitThreeBounce(
                  color: AppColors.white,
                  size: 25,
                ),
              )
            : Text(
                widget.text,
                style: widget.textStyle?.copyWith(color: widget.textColor) ??
                    AppStyles.smallText16Style.copyWith(color: widget.textColor),
              ),
      ),
    );
  }
}
