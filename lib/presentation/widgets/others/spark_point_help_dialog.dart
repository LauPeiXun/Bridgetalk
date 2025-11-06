import 'package:flutter/material.dart';

void showSparkPointHelpBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.65,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21.0, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.48,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        final level = index + 1;
                        final imagePath = 'assets/images/fire/fire$index.png';

                        final levelPoints = [
                          20,
                          50,
                          100,
                          150,
                          200,
                          250,
                          300,
                          350,
                          400,
                        ];

                        String getLevelRange(int index) {
                          if (index == 0) {
                            return '0 - ${levelPoints[0]} points';
                          } else if (index == 8) {
                            return '351 - ∞ points';
                          } else if (index < levelPoints.length) {
                            return '${levelPoints[index - 1] + 1} - ${levelPoints[index]} points';
                          } else {
                            return '> ${levelPoints.last} points';
                          }
                        }

                        return FittedBox(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(imagePath, height: 80, width: 80),
                              const SizedBox(height: 8),
                              Text(
                                'Level $level',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                getLevelRange(index),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Connect with your family and start growing stronger together through chats, engaging games, and emotional support.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Spark Elf is symbolized by fire levels – the more you interact, the higher your Spark grows, representing emotional bonding.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "How you can earn Spark Points:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "• Daily Chat +5 Spark Point",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "• Per Game +1 Spark Point",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
