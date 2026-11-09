import 'dart:math';
import 'dart:ui';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: BattleGame()));
}

const double W = 3000;
const Offset zoneC = Offset(1500, 1500);

class Weapon {
  final String name;
  final double rate, spread, speed, range;
  final int dmg, pellets, mag;
  const Weapon(this.name, this.rate, this.dmg, this.pellets, this.spread,
      this.speed, this.range, this.mag);
}

const weapons = [
  Weapon('مسدس', 0.35, 18, 1, 0.03, 700, 500, 12),
  Weapon('رشاش', 0.09, 9, 1, 0.10, 800, 550, 30),
  Weapon('شوتقن', 0.75, 10, 6, 0.28, 650, 320, 6),
  Weapon('قناص', 1.1, 80, 1, 0.0, 1000, 1100, 5),
];

class Unit {
  Offset pos;
  double hp = 100, angle = 0, cd = 0, ai = 0, strafe = 1;
  int weapon;
  bool bot;
  List<int> ammo = [9999, 0, 0, 0];
  Offset wander = Offset.zero;
  Unit(this.pos, this.bot, [this.weapon = 0]);
}

class Bullet {
  Offset pos, vel;
  double life;
  bool mine;
  int dmg;
  Bullet(this.pos, this.vel, this.life, this.mine, this.dmg);
}

class Pickup {
  Offset pos;
  int type; // 1-3 سلاح، 4 علاج
  bool taken = false;
  Pickup(this.pos, this.type);
}

class Car {
  Offset pos;
  double angle = 0, speed = 0, hp = 200;
  Car(this.pos);
}

class BattleGame extends FlameGame with DragCallbacks, TapCallbacks {
  final rnd = Random();
  late Unit player;
  List<Unit> bots = [];
  List<Bullet> bullets = [];
  List<Pickup> pickups = [];
  List<Rect> walls = [], buildings = [];
  List<Offset> trees = [];
  List<Car> cars = [];
  Car? driving;
  int? moveId, aimId;
  Offset moveC = Offset.zero, moveP = Offset.zero;
  Offset aimC = Offset.zero, aimP = Offset.zero;
  double zoneR = 2100, time = 0, flash = 0;
  int kills = 0;
  bool over = false, won = false;

  @override
  Color backgroundColor() => const Color(0xFF1B2A1B);

  @override
  Future<void> onLoad() async {
    reset();
  }

  Offset rndPos() => Offset(150 + rnd.nextDouble() * (W - 300),
      150 + rnd.nextDouble() * (W - 300));

  int rndWeapon() {
    final r = rnd.nextDouble();
    return r < 0.45 ? 1 : (r < 0.8 ? 2 : 3);
  }

  void reset() {
    bots = [];
    bullets = [];
    pickups = [];
    walls = [];
    buildings = [];
    trees = [];
    cars = [];
    driving = null;
    moveId = null;
    aimId = null;
    zoneR = 2100;
    time = 0;
    flash = 0;
    kills = 0;
    over = false;
    won = false;
    player = Unit(zoneC, false);

    for (int i = 0; i < 40; i++) {
      final w = 150 + rnd.nextDouble() * 120;
      final h = 130 + rnd.nextDouble() * 100;
      final x = 100 + rnd.nextDouble() * (W - 200 - w);
      final y = 100 + rnd.nextDouble() * (W - 200 - h);
      final r = Rect.fromLTWH(x, y, w, h);
      if ((r.center - zoneC).distance < 350) continue;
      if (buildings.any((b) => b.inflate(70).overlaps(r))) continue;
      buildings.add(r);
      const t = 16.0;
      const gap = 64.0;
      walls.add(Rect.fromLTWH(x, y, w, t));
      walls.add(Rect.fromLTWH(x, y, t, h));
      walls.add(Rect.fromLTWH(x + w - t, y, t, h));
      final dx = x + (w - gap) / 2;
      walls.add(Rect.fromLTWH(x, y + h - t, dx - x, t));
      walls.add(Rect.fromLTWH(dx + gap, y + h - t, x + w - (dx + gap), t));
      for (int k = 0; k < 2; k++) {
        final p = Offset(x + 40 + rnd.nextDouble() * (w - 80),
            y + 40 + rnd.nextDouble() * (h - 90));
        pickups.add(Pickup(p, rnd.nextDouble() < 0.7 ? rndWeapon() : 4));
      }
    }
    for (int i = 0; i < 180; i++) {
      final p = rndPos();
      if ((p - zoneC).distance < 200) continue;
      if (buildings.any((b) => b.inflate(40).contains(p))) continue;
      trees.add(p);
    }
    for (int i = 0; i < 50; i++) {
      final p = rndPos();
      if (buildings.any((b) => b.inflate(30).contains(p))) continue;
      pickups.add(Pickup(p, rnd.nextDouble() < 0.6 ? rndWeapon() : 4));
    }
    for (int i = 0; i < 9; i++) {
      final p = rndPos();
      if (buildings.any((b) => b.inflate(60).contains(p))) continue;
      cars.add(Car(p)..angle = rnd.nextDouble() * 2 * pi);
    }
    cars.add(Car(zoneC + const Offset(120, 60)));
    for (int i = 0; i < 14; i++) {
      Offset p = rndPos();
      while ((p - zoneC).distance < 600) {
        p = rndPos();
      }
      final b = Unit(pushOut(p, 16), true, rnd.nextInt(3));
      b.strafe = rnd.nextBool() ? 1 : -1;
      bots.add(b);
    }
  }

  Offset pushOut(Offset p, double r) {
    for (final w in walls) {
      final cx = p.dx.clamp(w.left, w.right).toDouble();
      final cy = p.dy.clamp(w.top, w.bottom).toDouble();
      final d = p - Offset(cx, cy);
      final dist = d.distance;
      if (dist < r) {
        if (dist == 0) {
          p = Offset(p.dx, w.top - r);
        } else {
          p = Offset(cx, cy) + d / dist * r;
        }
      }
    }
    for (final t in trees) {
      final d = p - t;
      final dist = d.distance;
      if (dist < r + 14 && dist > 0) p = t + d / dist * (r + 14);
    }
    return Offset(p.dx.clamp(r, W - r).toDouble(),
        p.dy.clamp(r, W - r).toDouble());
  }

  // ---------- اللمس ----------
  @override
  void onDragStart(DragStartEvent e) {
    super.onDragStart(e);
    final p = e.canvasPosition.toOffset();
    if (p.dx < size.x / 2) {
      if (moveId == null) {
        moveId = e.pointerId;
        moveC = p;
        moveP = p;
      }
    } else if (aimId == null) {
      aimId = e.pointerId;
      aimC = p;
      aimP = p;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent e) {
    super.onDragUpdate(e);
    final p = e.canvasEndPosition.toOffset();
    if (e.pointerId == moveId) {
      moveP = p;
    } else if (e.pointerId == aimId) {
      aimP = p;
    }
  }

  @override
  void onDragEnd(DragEndEvent e) {
    super.onDragEnd(e);
    if (e.pointerId == moveId) moveId = null;
    if (e.pointerId == aimId) aimId = null;
  }

  @override
  void onDragCancel(DragCancelEvent e) {
    super.onDragCancel(e);
    if (e.pointerId == moveId) moveId = null;
    if (e.pointerId == aimId) aimId = null;
  }

  Offset get carBtn => Offset(size.x - 60, size.y - 260);

  bool get nearCar =>
      cars.any((c) => (c.pos - player.pos).distance < 90);

  @override
  void onTapDown(TapDownEvent e) {
    super.onTapDown(e);
    if (over) {
      reset();
      return;
    }
    final p = e.canvasPosition.toOffset();
    if ((p - carBtn).distance < 45 && (driving != null || nearCar)) {
      toggleCar();
    }
  }

  void toggleCar() {
    if (driving != null) {
      final c = driving!;
      player.pos = pushOut(c.pos + const Offset(0, 50), 16);
      c.speed = 0;
      driving = null;
    } else {
      Car? best;
      double bd = 90;
      for (final c in cars) {
        final d = (c.pos - player.pos).distance;
        if (d < bd) {
          bd = d;
          best = c;
        }
      }
      driving = best;
    }
  }

  Offset stickDir(int? id, Offset c, Offset p) {
    if (id == null) return Offset.zero;
    final d = p - c;
    final l = d.distance;
    if (l < 10) return Offset.zero;
    return d / l * min(1.0, l / 50);
  }

  // ---------- القتال ----------
  void shoot(Unit u) {
    if (u.cd > 0) return;
    final w = weapons[u.weapon];
    if (!u.bot && u.ammo[u.weapon] <= 0) {
      u.weapon = 0;
      return;
    }
    u.cd = w.rate * (u.bot ? 2.2 : 1);
    if (!u.bot) u.ammo[u.weapon]--;
    for (int i = 0; i < w.pellets; i++) {
      final a = u.angle +
          (rnd.nextDouble() - 0.5) * 2 * w.spread * (u.bot ? 2.5 : 1);
      bullets.add(Bullet(
          u.pos + Offset.fromDirection(u.angle, 22),
          Offset.fromDirection(a, w.speed),
          w.range / w.speed,
          !u.bot,
          u.bot ? (w.dmg * 0.5).round() : w.dmg));
    }
  }

  void hurt(Unit b, double dmg) {
    if (b.hp <= 0) return;
    b.hp -= dmg;
    if (b.hp <= 0) {
      kills++;
      pickups.add(Pickup(b.pos, b.weapon > 0 ? b.weapon : 4));
    }
  }

  // ---------- التحديث ----------
  @override
  void update(double dt) {
    super.update(dt);
    if (over) return;
    dt = min(dt, 0.05);
    time += dt;
    flash = max(0.0, flash - dt);
    if (time > 15) zoneR = max(220.0, zoneR - 16 * dt);

    final mv = stickDir(moveId, moveC, moveP);
    final aim = stickDir(aimId, aimC, aimP);
    player.cd -= dt;

    if (driving == null) {
      player.pos = pushOut(player.pos + mv * 190 * dt, 16);
      if (aim.distance > 0.2) {
        player.angle = aim.direction;
        shoot(player);
      } else if (mv.distance > 0.1) {
        player.angle = mv.direction;
      }
      for (final p in pickups) {
        if ((p.pos - player.pos).distance < 30) {
          if (p.type == 4) {
            if (player.hp >= 100) continue;
            player.hp = min(100.0, player.hp + 40);
          } else {
            player.weapon = p.type;
            player.ammo[p.type] += weapons[p.type].mag * 3;
          }
          p.taken = true;
        }
      }
      pickups.removeWhere((p) => p.taken);
    } else {
      final c = driving!;
      if (mv.distance > 0.2) {
        final diff =
            atan2(sin(mv.direction - c.angle), cos(mv.direction - c.angle));
        c.angle += diff.clamp(-2.8 * dt, 2.8 * dt).toDouble();
        c.speed = min(430.0, c.speed + 300 * dt);
      } else {
        c.speed = max(0.0, c.speed - 250 * dt);
      }
      final tryPos = c.pos + Offset.fromDirection(c.angle, c.speed * dt);
      c.pos = pushOut(tryPos, 26);
      if ((c.pos - tryPos).distance > 1) c.speed *= 0.6;
      player.pos = c.pos;
      player.angle = c.angle;
      if (c.speed > 150) {
        for (final b in bots) {
          if ((b.pos - c.pos).distance < 42) hurt(b, 120);
        }
      }
    }

    // البوتات
    for (final b in bots) {
      b.cd -= dt;
      final toP = player.pos - b.pos;
      final d = toP.distance;
      Offset dir = Offset.zero;
      final toZ = zoneC - b.pos;
      if (toZ.distance > zoneR - 80) {
        dir = toZ / toZ.distance;
      } else if (d < 700) {
        b.angle = toP.direction;
        if (d > 280) {
          dir = toP / d;
        } else if (d < 160) {
          dir = -toP / d;
        } else {
          dir = Offset.fromDirection(toP.direction + pi / 2 * b.strafe, 1);
        }
        if (d < 600) shoot(b);
      } else {
        b.ai -= dt;
        if (b.ai <= 0) {
          b.ai = 2 + rnd.nextDouble() * 3;
          b.wander = Offset.fromDirection(rnd.nextDouble() * 2 * pi, 1);
        }
        dir = b.wander;
        b.angle = dir.direction;
      }
      b.pos = pushOut(b.pos + dir * 95 * dt, 16);
      if ((b.pos - zoneC).distance > zoneR) hurt(b, 4 * dt);
    }
    bots.removeWhere((b) => b.hp <= 0);

    // الرصاص
    for (final b in bullets) {
      b.pos += b.vel * dt;
      b.life -= dt;
      if (b.life <= 0) continue;
      if (walls.any((w) => w.contains(b.pos)) ||
          trees.any((t) => (t - b.pos).distance < 14)) {
        b.life = 0;
        continue;
      }
      if (b.mine) {
        for (final u in bots) {
          if (u.hp > 0 && (u.pos - b.pos).distance < 18) {
            hurt(u, b.dmg.toDouble());
            b.life = 0;
            break;
          }
        }
      } else if (driving != null) {
        if ((driving!.pos - b.pos).distance < 30) {
          driving!.hp -= b.dmg;
          b.life = 0;
        }
      } else if ((player.pos - b.pos).distance < 18) {
        player.hp -= b.dmg;
        flash = 0.25;
        b.life = 0;
      }
    }
    bullets.removeWhere((b) => b.life <= 0);

    // انفجار السيارة
    if (driving != null && driving!.hp <= 0) {
      cars.remove(driving);
      driving = null;
      player.hp -= 40;
      flash = 0.4;
    }

    // ضرر المنطقة
    if ((player.pos - zoneC).distance > zoneR) {
      player.hp -= 5 * dt;
      flash = max(flash, 0.1);
    }

    if (player.hp <= 0) {
      over = true;
      won = false;
    } else if (bots.isEmpty) {
      over = true;
      won = true;
    }
  }

  // ---------- الرسم ----------
  void drawTxt(Canvas c, String s, Offset o,
      {double fs = 14, Color col = Colors.white, bool center = false}) {
    final tp = TextPainter(
        text: TextSpan(
            text: s,
            style: TextStyle(
                color: col, fontSize: fs, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.rtl)
      ..layout();
    tp.paint(c, center ? o - Offset(tp.width / 2, tp.height / 2) : o);
  }

  void drawUnit(Canvas c, Unit u, Color col) {
    c.save();
    c.translate(u.pos.dx, u.pos.dy);
    c.rotate(u.angle);
    c.drawRect(Rect.fromLTWH(8, -3, 20, 6), Paint()..color = Colors.black87);
    c.drawCircle(Offset.zero, 16, Paint()..color = col);
    c.drawCircle(
        Offset.zero,
        16,
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    c.restore();
  }

  void drawStick(Canvas c, int? id, Offset cen, Offset p, Offset idle) {
    final base = Paint()..color = const Color(0x33FFFFFF);
    if (id == null) {
      c.drawCircle(idle, 45, base);
      return;
    }
    final d = p - cen;
    final l = d.distance;
    final k = l > 55 ? d / l * 55 : d;
    c.drawCircle(cen, 55, base);
    c.drawCircle(cen + k, 24, Paint()..color = const Color(0x99FFFFFF));
  }

  @override
  void render(Canvas c) {
    super.render(c);
    final sw = size.x, sh = size.y;
    Offset cam = player.pos - Offset(sw / 2, sh / 2);
    cam = Offset(cam.dx.clamp(0.0, max(0.0, W - sw)).toDouble(),
        cam.dy.clamp(0.0, max(0.0, W - sh)).toDouble());
    final view = Rect.fromLTWH(cam.dx, cam.dy, sw, sh).inflate(120);

    c.save();
    c.translate(-cam.dx, -cam.dy);
    c.drawRect(Rect.fromLTWH(0, 0, W, W),
        Paint()..color = const Color(0xFF4C8C3F));
    final lp = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 2;
    for (double x = (cam.dx / 150).floor() * 150.0;
        x < cam.dx + sw + 150;
        x += 150) {
      c.drawLine(Offset(x, cam.dy), Offset(x, cam.dy + sh), lp);
    }
    for (double y = (cam.dy / 150).floor() * 150.0;
        y < cam.dy + sh + 150;
        y += 150) {
      c.drawLine(Offset(cam.dx, y), Offset(cam.dx + sw, y), lp);
    }

    for (final b in buildings) {
      if (view.overlaps(b)) {
        c.drawRect(b, Paint()..color = const Color(0xFFCDB68A));
      }
    }
    for (final wl in walls) {
      if (view.overlaps(wl)) {
        c.drawRect(wl, Paint()..color = const Color(0xFF5A4636));
      }
    }
    final pickCols = <Color>[
      Colors.white,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.greenAccent
    ];
    for (final p in pickups) {
      if (!view.contains(p.pos)) continue;
      c.drawCircle(p.pos, 13, Paint()..color = pickCols[p.type]);
      c.drawCircle(
          p.pos,
          13,
          Paint()
            ..color = Colors.black87
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      drawTxt(c, p.type == 4 ? '+' : weapons[p.type].name,
          p.pos + const Offset(0, -26),
          fs: 12, center: true);
    }
    for (final car in cars) {
      if (!view.contains(car.pos)) continue;
      final isMine = identical(car, driving);
      c.save();
      c.translate(car.pos.dx, car.pos.dy);
      c.rotate(car.angle);
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 64, height: 34),
              const Radius.circular(8)),
          Paint()..color = isMine ? Colors.amber : Colors.redAccent);
      c.drawRect(Rect.fromLTWH(6, -13, 14, 26),
          Paint()..color = const Color(0xFF223355));
      c.restore();
    }
    for (final b in bots) {
      if (!view.contains(b.pos)) continue;
      drawUnit(c, b, Colors.redAccent);
      c.drawRect(Rect.fromLTWH(b.pos.dx - 18, b.pos.dy - 28, 36, 5),
          Paint()..color = Colors.black54);
      c.drawRect(
          Rect.fromLTWH(b.pos.dx - 18, b.pos.dy - 28, 36 * b.hp / 100, 5),
          Paint()..color = Colors.greenAccent);
    }
    if (driving == null) drawUnit(c, player, Colors.lightBlueAccent);
    for (final b in bullets) {
      c.drawLine(
          b.pos,
          b.pos - b.vel * 0.02,
          Paint()
            ..color = b.mine ? Colors.yellow : Colors.orangeAccent
            ..strokeWidth = 3);
    }
    for (final t in trees) {
      if (!view.contains(t)) continue;
      c.drawCircle(t, 38, Paint()..color = const Color(0xFF1F5E27));
      c.drawCircle(t, 26, Paint()..color = const Color(0xFF2E7D32));
      c.drawCircle(t, 14, Paint()..color = const Color(0xFF5D4037));
    }
    final zone = Path();
    zone.fillType = PathFillType.evenOdd;
    zone.addRect(Rect.fromLTWH(-2000, -2000, W + 4000, W + 4000));
    zone.addOval(Rect.fromCircle(center: zoneC, radius: zoneR));
    c.drawPath(zone, Paint()..color = const Color(0x55FF1744));
    c.drawCircle(
        zoneC,
        zoneR,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    c.restore();

    if (flash > 0) {
      c.drawRect(Rect.fromLTWH(0, 0, sw, sh),
          Paint()..color = Color.fromRGBO(255, 0, 0, min(0.4, flash * 1.5)));
    }

    // الواجهة
    drawStick(c, moveId, moveC, moveP, Offset(110, sh - 110));
    drawStick(c, aimId, aimC, aimP, Offset(sw - 110, sh - 110));

    c.drawRect(Rect.fromLTWH(12, 12, 160, 16), Paint()..color = Colors.black54);
    c.drawRect(
        Rect.fromLTWH(12, 12, 160 * max(0.0, player.hp) / 100, 16),
        Paint()
          ..color = player.hp > 30 ? Colors.greenAccent : Colors.redAccent);
    if (driving != null) {
      drawTxt(c, 'السيارة: ${max(0.0, driving!.hp).round()}',
          const Offset(12, 34),
          fs: 13);
    }
    drawTxt(c, 'الأحياء: ${bots.length + 1}   القتلى: $kills',
        Offset(sw / 2, 20),
        fs: 15, center: true);
    if (time < 15) {