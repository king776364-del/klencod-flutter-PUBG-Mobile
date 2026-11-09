import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: BattleGame()));
}

class BattleGame extends FlameGame with DragCallbacks {
  late Player player;
  Vector2 stickCenter = Vector2.zero();
  Vector2 direction = Vector2.zero();
  bool dragging = false;

  @override
  Future<void> onLoad() async {
    player = Player()..position = size / 2;
    add(player);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    dragging = true;
    stickCenter = event.canvasPosition.clone();
    direction = Vector2.zero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final delta = event.canvasEndPosition - stickCenter;
    direction = delta.length > 10 ? delta.normalized() : Vector2.zero();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    dragging = false;
    direction = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    player.position += direction * 200 * dt;
    player.position.clamp(Vector2.zero(), size);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (dragging) {
      final p = Paint()..color = const Color(0x55FFFFFF);
      canvas.drawCircle(stickCenter.toOffset(), 50, p);
      canvas.drawCircle(
          (stickCenter + direction * 30).toOffset(), 22, Paint()..color = const Color(0xAAFFFFFF));
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF3B6B3A);
}

class Player extends PositionComponent {
  Player() : super(size: Vector2.all(40), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(const Offset(20, 20), 20, Paint()..color = Colors.orange);
  }
}