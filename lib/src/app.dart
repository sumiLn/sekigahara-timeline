part of 'sekigahara.dart';

class SekigaharaTimelineApp extends StatelessWidget {
  const SekigaharaTimelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '関ヶ原戦役タイムマップ',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Sans JP',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A1F1F),
          brightness: Brightness.dark,
        ),
      ),
      home: const SekigaharaMapPage(),
    );
  }
}
