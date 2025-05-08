import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaywallScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback? onRestore;
  
  const PaywallScreen({
    Key? key,
    required this.onContinue,
    this.onRestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 50),
                  
                  // Заголовок
                  Text(
                    'PAYWALL #1',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Опции подписки
                  _buildSubscriptionOption(
                    title: '1 Month',
                    price: '\$9.99',
                    description: 'Billed monthly',
                    isPopular: false,
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildSubscriptionOption(
                    title: '3 Months',
                    price: '\$19.99',
                    description: 'Billed every 3 months',
                    isPopular: true,
                    badge: 'POPULAR',
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildSubscriptionOption(
                    title: '12 Months',
                    price: '\$59.99',
                    description: 'Billed annually',
                    isPopular: false,
                    badge: 'BEST VALUE',
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Преимущества 
                  _buildFeature('Custom Workout Plan'),
                  _buildFeature('Diet Recommendations'),
                  _buildFeature('Progress Tracking'),
                  _buildFeature('Workout Analytics'),
                  _buildFeature('Coach Support'),
                  
                  SizedBox(height: 30),
                  
                  // Кнопка продолжить
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'CONTINUE',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Восстановить покупки
                  TextButton(
                    onPressed: onRestore,
                    child: Text(
                      'Restore Purchases',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Условия и политика
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy. This subscription will automatically renew unless canceled at least 24 hours before the end of the current period.',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionOption({
    required String title,
    required String price,
    required String description,
    required bool isPopular,
    String? badge,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isPopular ? Colors.blue.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isPopular 
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Radio(
                  value: title,
                  groupValue: isPopular ? title : null,
                  onChanged: (value) {},
                  activeColor: Colors.blue,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        price,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
} 