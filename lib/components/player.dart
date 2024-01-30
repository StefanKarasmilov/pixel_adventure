import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/player_hitbox.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState { idle, running, jumping, falling }

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler {
  String character;

  Player({this.character = 'Ninja Frog', position}) : super(position: position);

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  final double stepTime = 0.05;

  final double _gravity = 9.8;
  final double _jumpForce = kIsWeb ? 400 : 280;
  final double _terminalVelocity = 300;
  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  List<CollisionBlock> collisionBlocks = [];
  PlayerHitbox playerHitbox = PlayerHitbox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    // debugMode = true;

    add(RectangleHitbox(
      position: Vector2(playerHitbox.offsetX, playerHitbox.offsetY),
      size: Vector2(playerHitbox.width, playerHitbox.height),
    ));
    return super.onLoad();
  }

  // Called every frame (dt = delta time)
  @override
  void update(double dt) {
    _updatePlayerState();
    _updatePlayerMovement(dt);
    _checkHorizontalCollisions();
    _applyGravity(dt);
    _checkVerticalCollisions();
    super.update(dt);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);

    return super.onKeyEvent(event, keysPressed);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation("Idle", 11);
    runningAnimation = _spriteAnimation("Run", 12);
    jumpingAnimation = _spriteAnimation("Jump", 1);
    fallingAnimation = _spriteAnimation("Fall", 1);

    // List of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
    };

    // Set current animation
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      gameRef.images.fromCache('Main Characters/$character/$state (32x32).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    // Check if moving, set running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    // check if falling
    if (velocity.y > 0) playerState = PlayerState.falling;

    // checks if jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) _playerJump(dt);

    // if (velocity.y > _gravity) isOnGround = false; //optional

    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          // going right
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - playerHitbox.offsetX - playerHitbox.width;
            break;
          }

          // going left
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + playerHitbox.width +
                playerHitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          // only check if going down
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - playerHitbox.height - playerHitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          // going down
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - playerHitbox.height - playerHitbox.offsetY;
            isOnGround = true;
            break;
          }

          // going up
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - playerHitbox.offsetY;
          }
        }
      }
    }
  }
}
