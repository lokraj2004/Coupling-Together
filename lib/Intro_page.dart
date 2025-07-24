import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'HomePage.dart';

class IntroPage1 extends StatefulWidget {
  @override
  _IntroPage1State createState() => _IntroPage1State();
}

class _IntroPage1State extends State<IntroPage1> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IntroPage2()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animations/LinkChain.json',
          width: 120, // Adjust to your desired size
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class IntroPage2 extends StatefulWidget {
  @override
  _IntroPage2State createState() => _IntroPage2State();
}

class _IntroPage2State extends State<IntroPage2> with TickerProviderStateMixin {
  bool showText = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        showText = true;
      });

      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image that scales with screen size
            SizedBox(
              width: screenWidth * 0.8, // 80% of screen width
              child: Image.asset(
                'assets/images/Logo.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 40),

            // Animated Text Reveal
            AnimatedOpacity(
              opacity: showText ? 1.0 : 0.0,
              duration: Duration(seconds: 1),
              child: Text(
                "Coupling Together",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}