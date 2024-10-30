import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:piri_qiblah/piri_qiblah.dart';

/// ----------------------------------------------------------------------------

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

/// ----------------------------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Piri Qiblah')),
        body: SafeArea(
          child: SizedBox.expand(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('Piri Qiblah With Custom Assets'),
                  PiriQiblah(
                    defaultWidgetPermissionDeniedMessage: 'Konum izni bekleniyor',
                    useDefaultAssets: false,
                    customBackgroundCompass: SvgPicture.asset('assets/compass.svg'),
                    customNeedle: SvgPicture.asset('assets/test_needle.svg'),
                    compassSize: 300,
                    angleTextStyle: TextStyle(),
                    customSpaceBetweenCompassAndAngleText: 40,
                  ),
                  const SizedBox(height: 30),
                  Divider(),
                  const SizedBox(height: 30),
                  const Text('Piri Qiblah With Default Assets'),
                  const PiriQiblah(
                    useDefaultAssets: true,
                    defaultNeedleColor: Colors.green,
                    defaultWidgetPermissionDeniedMessage: 'Konum izni bekleniyor',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
