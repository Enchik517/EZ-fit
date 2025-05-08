import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressGraphScreen extends StatelessWidget {
  final Function() onContinue;
  final String userName;
  final bool isMale;

  const ProgressGraphScreen({
    Key? key,
    required this.onContinue,
    required this.userName,
    required this.isMale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            
            // Divider
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Text(
                'Here is how weight loss can\nchange you in just 7 days',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),

            // Progress comparison card
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Body Fat
                      _buildComparisonRow(
                        label: 'Body Fat',
                        beforeValue: '35%',
                        afterValue: '33%',
                        beforeImageAsset: 'assets/images/before_body_fat.png',
                        afterImageAsset: 'assets/images/after_body_fat.png',
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Waist Size
                      _buildComparisonRow(
                        label: 'Waist Size',
                        beforeValue: '83 cm',
                        afterValue: '79 cm',
                        beforeImageAsset: 'assets/images/before_waist.png',
                        afterImageAsset: 'assets/images/after_waist.png',
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Weight
                      _buildComparisonRow(
                        label: 'Weight',
                        beforeValue: '65 kg',
                        afterValue: '64 kg',
                        beforeImageAsset: 'assets/images/before_weight.png',
                        afterImageAsset: 'assets/images/after_weight.png',
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Disclaimer text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          'Rapid weight loss isn\'t healthy, but 1-1.5kg per week is achievable and lasting',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Next button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build each comparison row
  Widget _buildComparisonRow({
    required String label,
    required String beforeValue,
    required String afterValue,
    required String beforeImageAsset,
    required String afterImageAsset,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        
        // Before and after comparison
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Before image with label
            Expanded(
              child: Column(
                children: [
                  // Placeholder for before image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 0.8,
                      child: Container(
                        color: Colors.grey[300],
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // In a real app, use Image.asset(beforeImageAsset)
                            // For now, using a placeholder
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.black87,
                            ),
                            
                            // Value label
                            Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                beforeValue,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Color(0xFFFF4081),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            // After image with label
            Expanded(
              child: Column(
                children: [
                  // Placeholder for after image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 0.8,
                      child: Container(
                        color: Colors.grey[300],
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // In a real app, use Image.asset(afterImageAsset)
                            // For now, using a placeholder
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.black87,
                            ),
                            
                            // Value label
                            Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                afterValue,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
} 