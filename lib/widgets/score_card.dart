import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final int score;
  final String status;
  final Color color;
  final VoidCallback onPressed;

  const ScoreCard({
    super.key,
    required this.score,
    required this.status,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            "Financial Health Score",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.white12,
                    valueColor:
                        AlwaysStoppedAnimation(color),
                  ),
                ),

                Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      "$score",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const Text(
                      "/100",
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Chip(
            backgroundColor:
                color.withValues(alpha: 0.15),
            side: BorderSide(color: color),
            label: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(
                Icons.calculate,
              ),
              label: const Text(
                "Recalculate Score",
              ),
            ),
          ),
        ],
      ),
    );
  }
}