import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const ActionGameApp());
}

class ActionGameApp extends StatelessWidget {
  const ActionGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battlegrounds 2D Action',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const GamePlayScreen(),
    );
  }
}

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({Key? key}) : super(key: key);

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  // إحصائيات اللاعب والمعركة
  int playerHealth = 100;
  int score = 0;
  double playerX = 150.0; // موقع اللاعب الأفقي
  String currentWeapon = "سلاح M416";
  bool isFiring = false;
  String enemyStatus = "عدو يتقدم نحو المنطقة!";
  Timer? gameLoopTimer;

  @override
  void initState() {
    super.initState();
    startGameLoop();
  }

  // حلقة اللعبة لتحديث الحركة والأعداء تلقائياً
  void startGameLoop() {
    gameLoopTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) return;
      setState(() {
        // حركة عشوائية للأعداء واختبار المواجهة
        int event = Random().nextInt(4);
        if (event == 0) {
          enemyStatus = "⚠️ تحذير: قناص يطلق النار في الاتجاه المعاكس!";
          playerHealth -= 5;
        } else if (event == 1) {
          enemyStatus = "🎯 تم رصد عدو في المدى القريب! أطلق النار بسرعة!";
        } else {
          enemyStatus = "🟢 المنطقة آمنة مؤقتاً، استمر بالتقدم.";
        }

        if (playerHealth <= 0) {
          playerHealth = 0;
          enemyStatus = "💀 تمت تصفيتك في المعركة! اضغط إعادة لتشغيل جيم جديد.";
        }
      });
    });
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    super.dispose();
  }

  void movePlayer(String direction) {
    setState(() {
      if (direction == "left") {
        playerX = max(20.0, playerX - 40.0);
      } else {
        playerX = min(320.0, playerX + 40.0);
      }
    });
  }

  void fireWeapon() {
    setState(() {
      isFiring = true;
      score += 10; // زيادة النقاط عند إطلاق النار والقضاء على الأعداء
      enemyStatus = "🔥 طلقات نارية مكثفة من " + currentWeapon + "! تم اصابة العدو بنجاح.";
    });
    // إلغاء وميض إطلاق النار بعد جزء من الثانية
    Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => isFiring = false);
    });
  }

  void resetGame() {
    setState(() {
      playerHealth = 100;
      score = 0;
      playerX = 150.0;
      enemyStatus = "🪂 هبطت مجدداً في الخريطة. ابدأ الحركة والقتال!";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PUBG 2D Battle Action'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          // شريط الحالة العلوي
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("❤️ الصحة: $playerHealth%", style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                Text("🏆 النقاط (القتلى): $score", style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                Text("🔫 $currentWeapon", style: const TextStyle(color: Colors.blueAccent, fontSize: 13)),
              ],
            ),
          ),

          // ساحة المعركة المرئية (الميدان الذي تتحرك فيه الشخصية)
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF090D16),
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600'),
                  fit: BoxFit.cover,
                  opacity: 0.25,
                ),
              ),
              child: Stack(
                children: [
                  // رسالة الحالة والأحداث في منتصف الميدان
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        enemyStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ),

                  // تأثير إطلاق النار (رصاصة أو وميض)
                  if (isFiring)
                    Positioned(
                      bottom: 120,
                      left: playerX + 15,
                      child: Container(
                        width: 10,
                        height: 40,
                        color: Colors.amberAccent,
                      ),
                    ),

                  // شخصية البطل المقاتل التي تتحرك في الميدان
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 150),
                    bottom: 40,
                    left: playerX,
                    child: Column(
                      children: [
                        const Text("🔫", style: TextStyle(fontSize: 24)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)
                            ],
                          ),
                          child: const Text(
                            "👤 بطل المعركة",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // أعداء متحرضون في الأفق
                  Positioned(
                    top: 100,
                    right: 60,
                    child: Column(
                      children: const [
                        Text("🦹‍♂️", style: TextStyle(fontSize: 28)),
                        Text("عدو", style: TextStyle(color: Colors.red, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // لوحة التحكم والتحرك (أزرار الحركة يمين/يسار وإطلاق النار)
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // زر التحرك لليسار
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  onPressed: () => movePlayer("left"),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text('يسار', style: TextStyle(color: Colors.white)),
                ),

                // زر إطلاق النار
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  onPressed: playerHealth > 0 ? fireWeapon : resetGame,
                  icon: Icon(playerHealth > 0 ? Icons.local_fire_department : Icons.refresh, color: Colors.white),
                  label: Text(playerHealth > 0 ? 'إطلاق نار 🎯' : 'إعادة الجيم 🔄', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),

                // زر التحرك لليمين
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  onPressed: () => movePlayer("right"),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text('يمين', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
