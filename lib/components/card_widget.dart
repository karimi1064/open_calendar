import 'package:calendar_app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class CardWidget extends StatelessWidget {
  final double elevation;
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double borderRadius;
  final Color color;
  final Color borderColor;
  final double? height;
  final double? width;
  final bool? isBorder;

  const CardWidget({
    Key? key,
    required this.child,
    this.elevation = 0,
    this.margin = const EdgeInsets.all(0),
    this.padding = const EdgeInsets.symmetric(vertical: 10),
    this.borderRadius = 15,
    this.color = AppColors.white,
    this.borderColor = AppColors.indigoLight,
    this.height,
    this.width,
    this.isBorder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      margin: margin,
      color: color,
      shape: RoundedRectangleBorder(
          side: (isBorder != null && isBorder == true)
              ? BorderSide(color: borderColor, width: 1.0)
              : BorderSide.none,
          borderRadius: BorderRadius.circular(borderRadius)),
      clipBehavior: Clip.hardEdge,
      shadowColor: Colors.grey,
      child: (height != null)
          ? (width != null)
              ? Container(
                  alignment: Alignment.center,
                  padding: padding,
                  height: height,
                  width: width,
                  child: child,
                )
              : Container(
                  alignment: Alignment.center,
                  padding: padding,
                  height: height,
                  child: child,
                )
          : Padding(
              padding: padding,
              child: child,
            ),
    );
  }
}
