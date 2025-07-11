import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/text_styles.dart';
import '../../widgets/dots_pagination.dart';
import '../../state_management/splash_state.dart';
import '../../../app/routes.dart';

class Splashscreen extends StatelessWidget {
  const Splashscreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Consumer<SplashState>(
        builder: (context, state, child) {
          return Column(
            children: [
              Container(
                width: screenWidth,
                height: screenHeight * 0.7,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkenPageWithAlpha(100),
                      blurRadius: 10,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/splashscreen/principal.jpg',
                        width: screenWidth,
                        height: screenHeight * 0.7,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        color: AppColors.darkenPageWithAlpha(141),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: screenHeight * 0.25,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.largePadding,
                    vertical: AppSizes.mediumPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: state.pageController,
                          itemCount: state.viewmodel.totalDesc,
                          onPageChanged: (index) {
                            state.currentIndex = index;
                          },
                          itemBuilder: (context, index) {
                            return SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSizes.mediumPadding),
                                child: Text(
                                  state.viewmodel.desc[index].description,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyText1,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Column(
                          children: [
                            DotsPagination(
                              itemCount: state.viewmodel.totalDesc,
                              currentIndex: state.currentIndex,
                            ),
                            const SizedBox(height: AppSizes.mediumPadding),
                            ElevatedButton(
                              onPressed: state.currentIndex <
                                      state.viewmodel.totalDesc - 1
                                  ? state.nextPage
                                  : () {
                                      Navigator.of(context)
                                          .pushNamed(//temporaire fotsiny
                                              AppRoutes.authview);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarygreen,
                                foregroundColor: Colors.white,
                                elevation: 5,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.largePadding,
                                  vertical: AppSizes.mediumPadding,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                state.currentIndex <
                                        state.viewmodel.totalDesc - 1
                                    ? 'Next'
                                    : 'Get Started',
                                style: AppTextStyles.bodyText4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
