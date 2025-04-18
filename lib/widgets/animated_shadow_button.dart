import 'package:control_style/control_style.dart';
import 'package:flutter/material.dart';

class AnimatedShadowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String buttonText;

  const AnimatedShadowButton({
    required this.onPressed,
    required this.buttonText,
    super.key,
  });

  @override
  State<AnimatedShadowButton> createState() => _AnimatedShadowButtonState();
}

class _AnimatedShadowButtonState extends State<AnimatedShadowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Tween<double> tween;
  late Animation<double> animation;

  @override
  void initState() {
    controller =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);
    tween = Tween<double>(begin: 0, end: 359);
    animation = controller.drive(tween);

    controller.forward();
    controller.repeat();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  @override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return TextButton(
  onPressed: widget.onPressed,
  style: TextButton.styleFrom(
    fixedSize: const Size(300, 50),
    backgroundColor: Colors.black.withOpacity(0.7),
    overlayColor: const Color.fromARGB(255, 45, 45, 45), // Lighter version of background
    shape: DecoratedOutlinedBorder(
      shadow: [
        GradientShadow(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: _generateGradientColors(animation.value),
            stops: _generateGradientStops(),
          ),
          offset: const Offset(-4, 4),
          blurRadius: 12,
          spreadRadius: 2,
        )
      ],
      child: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  child: Text(
    widget.buttonText,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w300,
      color: Colors.white,
    ),
  ),
);
      },
    ),
  );
}


  List<Color> _generateGradientColors(double offset) {
    List<Color> colors = [];
    const int divisions = 10;
    for (int i = 0; i < divisions; i++) {
      double hue = (360 / divisions) * i;
      hue += offset;
      if (hue > 360) {
        hue -= 360;
      }
      final Color color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
      colors.add(color);
    }
    colors.add(colors[0]);
    return colors;
  }

  List<double> _generateGradientStops() {
    const int divisions = 10;
    List<double> stops = [];
    for (int i = 0; i <= divisions; i++) {
      stops.add(i / divisions);
    }
    return stops;
  }
}