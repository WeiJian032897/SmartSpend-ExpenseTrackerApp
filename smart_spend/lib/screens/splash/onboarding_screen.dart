import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../auth/auth_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  final List<OnboardingData> onboardingData = [
    OnboardingData(
      title: 'Your Finance in One Place',
      subtitle: 'Get the big picture on all your money.',
      icon: Icons.dashboard,
    ),
    OnboardingData(
      title: 'Track your Spending',
      subtitle: 'Track and analyse spending habits while promoting the idea of managing personal finances more carefully and efficiently.',
      icon: Icons.analytics,
    ),
    OnboardingData(
      title: 'Budget your Money',
      subtitle: 'Build healthy financial habits. Control unnecessary expenses.',
      icon: Icons.savings,
    ),
    OnboardingData(
      title: 'Follow your plan and dreams',
      subtitle: 'Build your financial life. Make the right financial decision. See only what is important for you.',
      icon: Icons.trending_up,
    ),
    OnboardingData(
      title: 'Manage your Financial Health',
      subtitle: 'Receive detailed monthly financial health reports by automatically analysing your spending.',
      icon: Icons.health_and_safety,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            onboardingData[index].icon,
                            size: 80,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          onboardingData[index].title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          onboardingData[index].subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: onboardingData.length,
                    effect: const WormEffect(
                      dotColor: Colors.grey,
                      activeDotColor: AppColors.primaryBlue,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (currentPage == onboardingData.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (currentPage == onboardingData.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: CustomButton(
                        text: "Let's Start",
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthWrapper()),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}