// ==========================================================================
// Dual Counter-Rotating Spinners & Progress Stepper Loading View Widget
// ==========================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class LoadingView extends StatefulWidget {
  final String title;
  final String subtitle;
  final String activeStepKey; // 'pdf', 'gemini', 'assemble'

  const LoadingView({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.activeStepKey,
  }) : super(key: key);

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // Continuous rotation controller for spinners
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Bouncing controller for center CPU icon
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Loader Visual: Concentric Spinners
            SizedBox(
              width: 120.0,
              height: 120.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Clockwise Spinner
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 100.0,
                      height: 100.0,
                      child: CircularProgressIndicator(
                        value: 0.25,
                        strokeWidth: 3.5,
                        color: AeroTheme.primaryIndigo,
                        backgroundColor: Colors.white.withOpacity(0.01),
                      ),
                    ),
                  ),

                  // Inner Counter-Clockwise Spinner
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_rotationController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 76.0,
                      height: 76.0,
                      child: CircularProgressIndicator(
                        value: 0.25,
                        strokeWidth: 3.5,
                        color: AeroTheme.correctEmerald,
                        backgroundColor: Colors.white.withOpacity(0.01),
                      ),
                    ),
                  ),

                  // Bouncing CPU Icon in Center
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: child,
                      );
                    },
                    child: const Icon(
                      LucideIcons.cpu,
                      color: AeroTheme.primaryIndigo,
                      size: 26.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),

            // Dynamic Title & Status Description
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18.0),
            ),
            const SizedBox(height: 8.0),
            Container(
              constraints: const BoxConstraints(maxWidth: 320.0),
              child: Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AeroTheme.textSecondary, fontSize: 13.0, height: 1.4),
              ),
            ),
            const SizedBox(height: 48.0),

            // Stepper progress indicator bar
            Container(
              constraints: const BoxConstraints(maxWidth: 400.0),
              child: Row(
                children: [
                  _buildStep('pdf', 'Parse PDF'),
                  _buildStepperLine('pdf', 'gemini'),
                  _buildStep('gemini', 'Generation'),
                  _buildStepperLine('gemini', 'assemble'),
                  _buildStep('assemble', 'Assemble'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget builder for active step dots
  Widget _buildStep(String stepKey, String title) {
    bool isDone = false;
    bool isActive = false;

    if (widget.activeStepKey == 'pdf') {
      isActive = stepKey == 'pdf';
    } else if (widget.activeStepKey == 'gemini') {
      isDone = stepKey == 'pdf';
      isActive = stepKey == 'gemini';
    } else if (widget.activeStepKey == 'assemble') {
      isDone = stepKey == 'pdf' || stepKey == 'gemini';
      isActive = stepKey == 'assemble';
    }

    Color dotColor = Colors.transparent;
    Color borderColor = AeroTheme.borderSideColor;
    Color titleColor = AeroTheme.textMuted;
    Widget dotChild = const SizedBox();

    if (isDone) {
      dotColor = AeroTheme.correctEmerald;
      borderColor = AeroTheme.correctEmerald;
      titleColor = AeroTheme.correctEmerald;
      dotChild = const Icon(LucideIcons.check, color: Colors.white, size: 10.0);
    } else if (isActive) {
      dotColor = AeroTheme.primaryIndigoBg;
      borderColor = AeroTheme.primaryIndigo;
      titleColor = AeroTheme.textPrimary;
      dotChild = Container(
        width: 6.0,
        height: 6.0,
        decoration: const BoxDecoration(
          color: AeroTheme.primaryIndigo,
          shape: BoxShape.circle,
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24.0,
            height: 24.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2.0),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AeroTheme.primaryIndigo.withOpacity(0.15),
                        blurRadius: 8.0,
                      )
                    ]
                  : [],
            ),
            child: dotChild,
          ),
          const SizedBox(height: 6.0),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget builder for dotted line connectors
  Widget _buildStepperLine(String fromStep, String toStep) {
    bool isDone = false;

    if (widget.activeStepKey == 'gemini') {
      isDone = fromStep == 'pdf';
    } else if (widget.activeStepKey == 'assemble') {
      isDone = fromStep == 'pdf' || fromStep == 'gemini';
    }

    return Container(
      width: 32.0,
      height: 2.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      color: isDone ? AeroTheme.correctEmerald : AeroTheme.borderSideColor,
    );
  }
}
// Humility checklist: all custom spinners designed
class HumilityIsGood {
  static const String between = "between";
}
