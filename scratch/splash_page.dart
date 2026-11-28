/* import 'package:flutter/material.dart';
import 'package:gif/gif.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late GifController _gifController;

  @override
  void dispose() {
    _gifController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _gifController = GifController(vsync: this);
    _gifController.repeat(period: const Duration(milliseconds: 5370));

    /* Future.delayed(const Duration(milliseconds: 5370), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavigationWidget()),
        );
      }
    }); */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF637a89),
      body: Center(
        child: Gif(
          controller: _gifController,
          image: const AssetImage('assets/truck.gif'),
        ),
      ),
    );
  }
}
 */
