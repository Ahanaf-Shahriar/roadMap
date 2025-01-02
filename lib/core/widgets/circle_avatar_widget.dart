import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AvatarUrlType {
  network,
  assets,
  svg,
  name,
}

class CircleAvatarWidget extends StatelessWidget {

  final AvatarUrlType avatarUrlType;

  final String source;

  final double width;

  final double? containerWidth;

  final double height;

  final Color? color;

  final Color? background;

  final EdgeInsets? padding;

  final EdgeInsets? margin;

  final double? fontSize;

  const CircleAvatarWidget.network({
    super.key,
    required this.source,
    this.width = 50.0,
    this.height = 50.0,
    this.containerWidth,
    this.color,
    this.background,
    this.padding,
    this.margin,
  }) : avatarUrlType = AvatarUrlType.network, fontSize = null;

  const CircleAvatarWidget.assets({
    super.key,
    required this.source,
    this.width = 50.0,
    this.height = 50.0,
    this.containerWidth,
    this.color,
    this.background,
    this.padding,
    this.margin,
  }) : avatarUrlType = AvatarUrlType.assets, fontSize = null;

  const CircleAvatarWidget.name({
    super.key,
    required this.source,
    this.width = 50.0,
    this.height = 50.0,
    this.containerWidth,
    this.color,
    this.background,
    this.padding,
    this.margin,
    this.fontSize,
  }) : avatarUrlType = AvatarUrlType.name;

  const CircleAvatarWidget.svg({
    super.key,
    required this.source,
    this.width = 50.0,
    this.height = 50.0,
    this.containerWidth,
    this.color,
    this.background,
    this.padding,
    this.margin,
  }) : avatarUrlType = AvatarUrlType.svg, fontSize = null;

  @override
  Widget build(BuildContext context) => Container(
    width: containerWidth,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: avatarUrlType == AvatarUrlType.name
          ? Colors.grey.shade100
          : background,
    ),
    padding: avatarUrlType == AvatarUrlType.name
        ? const EdgeInsets.all(12.0)
        : padding,
    margin: margin,
    clipBehavior: Clip.antiAliasWithSaveLayer,
    child: _getImage(),
  );

  Widget _getImage(){
    switch(avatarUrlType) {
      case AvatarUrlType.assets:
        return Image.asset(
          source,
          fit: BoxFit.fitHeight,
          width: width,
          height: height,
        );
      case AvatarUrlType.svg:
        return SvgPicture.asset(
          source,
          fit: BoxFit.cover,
          width: width,
          height: height,
          color: color,
        );
      case AvatarUrlType.name:
        return Text(
          source.length <= 1 ? source : source.substring(0,1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        );
      default:
        return Image.network(
          source,
          fit: BoxFit.fitWidth,
        );
    }
  }
}