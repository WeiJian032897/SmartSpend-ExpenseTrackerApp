import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'dart:math' as math;

class FinancialHealthGauge extends StatefulWidget {
  final double score;

  const FinancialHealthGauge({super.key, required this.score});

  @override
  State<FinancialHealthGauge> createState() => _FinancialHealthGaugeState();
}

class _FinancialHealthGaugeState extends State<FinancialHealthGauge>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getScoreColor(widget.score).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                ),
              ),
              
              // Outer ring - background
              CustomPaint(
                size: const Size(240, 240),
                painter: GaugeBackgroundPainter(),
              ),
              
              // Progress ring - animated
              CustomPaint(
                size: const Size(240, 240),
                painter: GaugeProgressPainter(
                  progress: _scoreAnimation.value / 100,
                  color: _getScoreColor(widget.score),
                ),
              ),
              
              // Inner gradient circle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getScoreColor(widget.score).withOpacity(0.1),
                      _getScoreColor(widget.score).withOpacity(0.05),
                    ],
                  ),
                ),
              ),
              
              // Score display
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _scoreAnimation.value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: _getScoreColor(widget.score),
                        height: 1.0,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            color: _getScoreColor(widget.score).withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getScoreColor(widget.score).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getScoreLabel(widget.score),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(widget.score),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getScoreIcon(widget.score),
                          size: 16,
                          color: _getScoreColor(widget.score),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Financial Health',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Score range indicators
              ..._buildScoreIndicators(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildScoreIndicators() {
    final indicators = [
      {'angle': -120.0, 'label': 'Poor', 'color': Colors.red},
      {'angle': -60.0, 'label': 'Fair', 'color': AppColors.orange},
      {'angle': 0.0, 'label': 'Good', 'color': AppColors.yellow},
      {'angle': 60.0, 'label': 'Great', 'color': AppColors.green},
      {'angle': 120.0, 'label': 'Excellent', 'color': AppColors.primaryBlue},
    ];

    return indicators.map((indicator) {
      final angle = indicator['angle'] as double;
      final radian = (angle * math.pi) / 180;
      final radius = 125.0; // Moved further out for better visibility
      final x = radius * math.cos(radian);
      final y = radius * math.sin(radian);

      return Positioned(
        left: 140 + x - 30, // Increased width for better centering
        top: 140 + y - 12,  // Increased height for better centering
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (indicator['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (indicator['color'] as Color).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            indicator['label'] as String,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87, // Changed to dark color for better visibility
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.primaryBlue;
    if (score >= 60) return AppColors.green;
    if (score >= 40) return AppColors.yellow;
    if (score >= 20) return AppColors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Great';
    if (score >= 40) return 'Good';
    if (score >= 20) return 'Fair';
    return 'Poor';
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.trending_up;
    if (score >= 60) return Icons.thumb_up;
    if (score >= 40) return Icons.trending_flat;
    if (score >= 20) return Icons.trending_down;
    return Icons.warning;
  }
}

class GaugeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75, // Start angle
      math.pi * 1.5, // Sweep angle (270 degrees)
      false,
      backgroundPaint,
    );

    // Gradient segments for visual appeal
    final colors = [Colors.red, AppColors.orange, AppColors.yellow, AppColors.green, AppColors.primaryBlue];
    final segmentAngle = (math.pi * 1.5) / colors.length;
    
    for (int i = 0; i < colors.length; i++) {
      final segmentPaint = Paint()
        ..color = colors[i].withOpacity(0.3)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 15),
        -math.pi * 0.75 + (segmentAngle * i),
        segmentAngle * 0.8, // Small gap between segments
        false,
        segmentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GaugeProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  GaugeProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Progress arc with gradient
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.6),
          color,
          color.withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * 1.5 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glowing effect at the end of progress
    if (progress > 0) {
      final endAngle = -math.pi * 0.75 + sweepAngle;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);

      final glowPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endX, endY), 12, glowPaint);
      
      final innerGlowPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endX, endY), 6, innerGlowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is GaugeProgressPainter && 
           (oldDelegate.progress != progress || oldDelegate.color != color);
  }
}