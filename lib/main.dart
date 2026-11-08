import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const PUBGGameApp());
}

class PUBGGameApp extends StatelessWidget {
  const PUBGGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battlegrounds Mobile Offline',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.amber,
      ),
      home: const GameHomeScreen(),
    );
  }
}

class GameHomeScreen extends StatefulWidget {
  const GameHomeScreen({Key? key}) : super(key: key);

  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen> {
  int playerHealth = 100;
  int playerHelmet = 0;
  int playerArmor = 0;
  String currentWeapon = "فارغ (بدون سلاح)";
  int ammoCount = 0;
  int alivePlayers = 100;
  int kills = 0;
  bool isGrounded = false;
  String gameLog = "تعليمات:\n1. اضغط على الهبوط بالمظلة للنزول في الخريطة.\n2. اجمع الأسلحة والدروع.\n3. ابدأ الاشتباك وكن الباقي حياً!";

  void _landPlane() {
    setState(() {
      isGrounded = true;
      playerHealth = 100;
      alivePlayers = 99;
      kills = 0;
      currentWeapon = "مقاق (Pan)";
      ammoCount = 0;
      gameLog = "🪂 هبطت بنجاح في خريطة Erangel (منطقة Pochinki). العدو قريب، ابحث عن العتاد بسرعة!";
    });
  }

  void _lootWeapon() {
    if (!isGrounded) {
      _showToast("يجب الهبوط من الطائرة أولاً!");
      return;
    }
    List<String> weapons = ["أسطوري AWM (منظار 8x)", "سلاح M416 (كامل الملحقات)", "قناص Kar98k", "رشاش UMP45"];
    List<int> ammos = [15, 90, 25, 60];
    int idx = Random().nextInt(weapons.length);

    setState(() {
      currentWeapon = weapons[idx];
      ammoCount = ammos[idx];
      gameLog = "🎒 لوت ناجح! عثرت على: $currentWeapon مع ذخيرة: $ammoCount طلقة.";
    });
  }

  void _lootArmor() {
    if (!isGrounded) {
      _showToast("هبط أولاً للخريطة!");
      return;
    }
    setState(() {
      playerHelmet = Random().nextInt(3) + 1;
      playerArmor = Random().nextInt(3) + 1;
      gameLog = "🛡️ رائع! تم تجهيز درع مستوى $playerArmor وخوذة مستوى $playerHelmet بنجاح.";
    });
  }

  void _fightEnemy() {
    if (!isGrounded) {
      _showToast("أنت لم تهبط بعد!");
      return;
    }
    if (playerHealth <= 0) {
      setState(() {
        gameLog = "💀 أنت ميت! اضغط على 'الهبوط بالمظلة' لبدء جيم جديد.";
      });
      return;
    }

    int event = Random().nextInt(3);
    setState(() {
      if (event == 0) {
        kills += 1;
        alivePlayers -= Random().nextInt(5) + 1;
        if (alivePlayers < 1) alivePlayers = 1;
        gameLog = "🔥 اشتباك ناري مباشر! استخدمت $currentWeapon وقمت بالتصفية بنجاح.";
      } else if (event == 1) {
        int damage = (Random().nextInt(40) / (playerArmor == 0 ? 1 : playerArmor)).round();
        playerHealth -= damage;
        if (playerHealth < 0) playerHealth = 0;
        gameLog = "⚠️ تعرضت لإطلاق نار من قناص مخفي! نقصت صحتك بمقدار $damage%.";
      } else {
        gameLog = "🟢 أنت داخل المنطقة الآمنة (Safe Zone). استمر في التقدم!";
      }

      if (playerHealth == 0) {
        gameLog = "💀 تم تصفيتك في المعركة (Eliminated). حاول مرة أخرى!";
      } else if (alivePlayers == 1 && isGrounded) {
        gameLog = "🏆 WINNER WINNER CHICKEN DINNER! 🎉 فزت بالمرتبة الأولى وبقيت وحيداً على قيد الحياة!";
      }
    });
  }

  void _useMedKit() {
    setState(() {
      if (playerHealth >= 100) {
        gameLog = "💚 صحتك ممتلئة بالكامل (100%).";
      } else {
        playerHealth = 100;
        gameLog = "💉 استخدمت الإسعافات الأولية ومشروب الطاقة. عادت صحتك 100%!";
      }
    });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PUBG Mobile Offline/Online'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F1F1F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط الحالة HUD
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Text(
                "❤️ الصحة: $playerHealth%  |  🛡️ درع/خوذة: Lv.$playerArmor/Lv.$playerHelmet\n"
                "🔫 السلاح: $currentWeapon ($ammoCount)\n"
                "👥 الباقون: $alivePlayers  |  🎯 القتلى: $kills",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),

            // الأزرار التكتيكية للعبة
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), padding: const EdgeInsets.all(12)),
              onPressed: _landPlane,
              icon: const Icon(Icons.flight, color: Colors.white),
              label: const Text('🪂 الهبوط بالمظلة في الخريطة', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: const EdgeInsets.all(12)),
              onPressed: _lootWeapon,
              icon: const Icon(Icons.security, color: Colors.white),
              label: const Text('🎒 لوت الأسلحة والذخيرة', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF388E3C), padding: const EdgeInsets.all(12)),
              onPressed: _lootArmor,
              icon: const Icon(Icons.shield, color: Colors.white),
              label: const Text('🛡️ لوت الدروع والخوذ', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), padding: const EdgeInsets.all(12)),
              onPressed: _fightEnemy,
              icon: const Icon(Icons.flash_on, color: Colors.white),
              label: const Text('⚔️ دخول منطقة الاشتباك وقتال الأعداء', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), padding: const EdgeInsets.all(12)),
              onPressed: _useMedKit,
              icon: const Icon(Icons.local_hospital, color: Colors.white),
              label: const Text('💉 استخدام الإسعافات الأولية (MedKit)', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
            const SizedBox(height: 25),

            // صندوق السجل والأحداث
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                gameLog,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
