import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class WeightLossComparisonScreen extends StatelessWidget {
  final VoidCallback onNext;
  final String gender;
  final double? weight;
  final double? bodyFat;
  final double? waistSize;

  // Добавляем параметры для желаемых значений
  final double? targetWeight;
  final double? targetBodyFat;
  final double? targetWaistSize;

  // Список изображений справочника по жиру в теле для женщин (статический)
  static const List<String> _bodyFatReferenceImages = [
    'assets/images/bodyfat_reference_corrected/01_female_10-13_bf.png',
    'assets/images/bodyfat_reference_corrected/02_female_14-17_bf.png',
    'assets/images/bodyfat_reference_corrected/03_female_18-23_bf.png',
    'assets/images/bodyfat_reference_corrected/04_female_24-28_bf.png',
    'assets/images/bodyfat_reference_corrected/08_female_34-37_bf.png',
    'assets/images/bodyfat_reference_corrected/06_female_38-42_bf.png',
    'assets/images/bodyfat_reference_corrected/07_female_43-46_bf.png',
    'assets/images/bodyfat_reference_corrected/09_female_47-50_bf.png',
  ];

  // Список изображений для разных размеров талии (одинаковые и для мужчин и для женщин)
  static const List<String> _waistReferenceImages = [
    'assets/images/bodyfat_reference_corrected/01_waist_40cm.png',
    'assets/images/bodyfat_reference_corrected/02_waist_71cm.png',
    'assets/images/bodyfat_reference_corrected/03_waist_102cm.png',
    'assets/images/bodyfat_reference_corrected/04_waist_133cm.png',
    'assets/images/bodyfat_reference_corrected/05_waist_164cm.png',
  ];

  const WeightLossComparisonScreen({
    Key? key,
    required this.onNext,
    required this.gender,
    this.weight,
    this.bodyFat,
    this.waistSize,
    this.targetWeight,
    this.targetBodyFat,
    this.targetWaistSize,
  }) : super(key: key);

  // Расчет текущих значений
  double get initialWeight => weight ?? (gender == 'Female' ? 65.0 : 82.0);
  double get initialBodyFat => bodyFat ?? (gender == 'Female' ? 35.0 : 24.0);
  double get initialWaistSize =>
      waistSize ?? (gender == 'Female' ? 83.0 : 92.0);

  // Используем введенные пользователем значения или вычисляем, если они не предоставлены
  double get predictedWeight =>
      targetWeight ?? max(initialWeight - 1.0, initialWeight * 0.98);
  double get predictedBodyFat =>
      targetBodyFat ?? max(initialBodyFat - 2.0, initialBodyFat * 0.94);
  double get predictedWaistSize =>
      targetWaistSize ?? max(initialWaistSize - 4.0, initialWaistSize * 0.95);

  // Функция для получения изображения, соответствующего проценту жира
  String _getBodyFatImage(double bodyFat) {
    if (bodyFat < 14) return _bodyFatReferenceImages[0]; // 10-13%
    if (bodyFat < 18) return _bodyFatReferenceImages[1]; // 14-17%
    if (bodyFat < 24) return _bodyFatReferenceImages[2]; // 18-23%
    if (bodyFat < 29) return _bodyFatReferenceImages[3]; // 24-28%
    if (bodyFat < 38) return _bodyFatReferenceImages[4]; // 34-37%
    if (bodyFat < 43) return _bodyFatReferenceImages[5]; // 38-42%
    if (bodyFat < 47) return _bodyFatReferenceImages[6]; // 43-46%
    return _bodyFatReferenceImages[7]; // 47-50%
  }

  // Получить изображение для "после" с меньшим процентом жира
  String _getAfterBodyFatImage(double currentBodyFat) {
    // Определяем индекс текущего изображения
    int currentIndex = 7; // По умолчанию последний индекс (наибольший жир)

    if (currentBodyFat < 14)
      currentIndex = 0;
    else if (currentBodyFat < 18)
      currentIndex = 1;
    else if (currentBodyFat < 24)
      currentIndex = 2;
    else if (currentBodyFat < 29)
      currentIndex = 3;
    else if (currentBodyFat < 38)
      currentIndex = 4;
    else if (currentBodyFat < 43)
      currentIndex = 5;
    else if (currentBodyFat < 47) currentIndex = 6;

    // Берем изображение с меньшим процентом жира
    // (на одну ступень ниже, но не меньше 0)
    int afterIndex = currentIndex > 0 ? currentIndex - 1 : 0;
    return _bodyFatReferenceImages[afterIndex];
  }

  // Функция для получения изображения, соответствующего размеру талии
  String _getWaistImage(double waistSize) {
    if (waistSize < 56) return _waistReferenceImages[0]; // ~40 см
    if (waistSize < 87) return _waistReferenceImages[1]; // ~71 см
    if (waistSize < 118) return _waistReferenceImages[2]; // ~102 см
    if (waistSize < 149) return _waistReferenceImages[3]; // ~133 см
    return _waistReferenceImages[4]; // ~164 см
  }

  // Получить изображение для "после" с меньшим размером талии
  String _getAfterWaistImage(double currentWaistSize) {
    // Определяем индекс текущего изображения
    int currentIndex = 4; // По умолчанию последний индекс (наибольший размер)

    if (currentWaistSize < 56)
      currentIndex = 0;
    else if (currentWaistSize < 87)
      currentIndex = 1;
    else if (currentWaistSize < 118)
      currentIndex = 2;
    else if (currentWaistSize < 149) currentIndex = 3;

    // Берем изображение с меньшим размером талии
    // (на одну ступень ниже, но не меньше 0)
    int afterIndex = currentIndex > 0 ? currentIndex - 1 : 0;
    return _waistReferenceImages[afterIndex];
  }

  @override
  Widget build(BuildContext context) {
    // Получаем размер экрана
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360; // Определяем маленькие экраны

    // Эта переменная будет контролировать, нужно ли показывать дополнительную информацию в отладке
    final bool debugMode = true;

    // Используем жесткие пути для изображений, чтобы точно обеспечить их отображение
    // Изображения для размера талии
    final String waistBeforeImage =
        'assets/images/bodyfat_reference_corrected/03_waist_102cm.png';
    final String waistAfterImage =
        'assets/images/bodyfat_reference_corrected/02_waist_71cm.png';

    // Изображения для процента жира
    final String bodyFatBeforeImage = gender == 'Female'
        ? 'assets/images/bodyfat_reference_corrected/03_female_18-23_bf.png'
        : 'assets/images/bodyfat_reference_corrected/03_waist_102cm.png'; // Временно используем изображение талии для мужчин
    final String bodyFatAfterImage = gender == 'Female'
        ? 'assets/images/bodyfat_reference_corrected/02_female_14-17_bf.png'
        : 'assets/images/bodyfat_reference_corrected/02_waist_71cm.png'; // Временно используем изображение талии для мужчин

    // Изображения для веса (используем те же, что и для талии, как заполнитель)
    final String weightBeforeImage =
        'assets/images/bodyfat_reference_corrected/04_waist_133cm.png';
    final String weightAfterImage =
        'assets/images/bodyfat_reference_corrected/03_waist_102cm.png';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Here is how weight loss can\nchange you in just 7 days',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 22 : 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Comparison card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Body fat comparison
                _buildMetricComparisonRow(
                  title: 'Body Fat',
                  beforeValue: '${initialBodyFat.toStringAsFixed(0)}%',
                  afterValue: '${predictedBodyFat.toStringAsFixed(0)}%',
                  isSmallScreen: isSmallScreen,
                  beforeImage: bodyFatBeforeImage,
                  afterImage: bodyFatAfterImage,
                ),

                SizedBox(height: 16),

                // Waist size comparison
                _buildMetricComparisonRow(
                  title: 'Waist Size',
                  beforeValue: '${initialWaistSize.toStringAsFixed(0)} cm',
                  afterValue: '${predictedWaistSize.toStringAsFixed(0)} cm',
                  isSmallScreen: isSmallScreen,
                  beforeImage: waistBeforeImage,
                  afterImage: waistAfterImage,
                ),

                SizedBox(height: 16),

                // Weight comparison
                _buildMetricComparisonRow(
                  title: 'Weight',
                  beforeValue: '${initialWeight.toStringAsFixed(0)} kg',
                  afterValue: '${predictedWeight.toStringAsFixed(0)} kg',
                  isSmallScreen: isSmallScreen,
                  beforeImage: weightBeforeImage,
                  afterImage: weightAfterImage,
                ),

                SizedBox(height: 20),

                // Note about healthy weight loss
                Text(
                  'Rapid weight loss isn\'t healthy, but 1-1.5kg per\nweek is achievable and lasting',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Next button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Next',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricComparisonRow({
    required String title,
    required String beforeValue,
    required String afterValue,
    bool isSmallScreen = false,
    String? beforeImage,
    String? afterImage,
  }) {
    return Column(
      children: [
        // Заголовок метрики
        Container(
          width: double.infinity,
          alignment: Alignment.center,
          margin: EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Строка со сравнением значений
        SizedBox(
          height: 36,
          child: Row(
            children: [
              // Значение "до"
              Expanded(
                child: ClipPath(
                  clipper: LeftSlantClipper(),
                  child: Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          beforeValue,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Стрелки между значениями
              Container(
                width: isSmallScreen ? 36 : 50,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 0.5 : 1),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.pink[300],
                        size: isSmallScreen ? 8 : 10,
                      ),
                    ),
                  ),
                ),
              ),

              // Значение "после"
              Expanded(
                child: ClipPath(
                  clipper: RightSlantClipper(),
                  child: Container(
                    color: Colors.pink,
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          afterValue,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Изображения, если они предоставлены
        if (beforeImage != null && afterImage != null) ...[
          SizedBox(height: 8),
          Row(
            children: [
              // Изображение "до"
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        beforeImage,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getImageRangeText(beforeImage),
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12),

              // Изображение "после"
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        afterImage,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getImageRangeText(afterImage),
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getImageRangeText(String imagePath) {
    // Для изображений процента жира
    if (imagePath.contains('01_female_10-13_bf')) return '10-13%';
    if (imagePath.contains('02_female_14-17_bf')) return '14-17%';
    if (imagePath.contains('03_female_18-23_bf')) return '18-23%';
    if (imagePath.contains('04_female_24-28_bf')) return '24-28%';
    if (imagePath.contains('08_female_34-37_bf')) return '34-37%';
    if (imagePath.contains('06_female_38-42_bf')) return '38-42%';
    if (imagePath.contains('07_female_43-46_bf')) return '43-46%';
    if (imagePath.contains('09_female_47-50_bf')) return '47-50%';

    // Для изображений размера талии
    if (imagePath.contains('01_waist_40cm')) return '~40 cm';
    if (imagePath.contains('02_waist_71cm')) return '~71 cm';
    if (imagePath.contains('03_waist_102cm')) return '~102 cm';
    if (imagePath.contains('04_waist_133cm')) return '~133 cm';
    if (imagePath.contains('05_waist_164cm')) return '~164 cm';

    return '';
  }
}

// Класс для вырезания наклонного левого края (для правого блока)
class RightSlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(10, 0); // Начинаем с отступа слева вверху
    path.lineTo(size.width, 0); // Верхняя граница
    path.lineTo(size.width, size.height); // Правая граница
    path.lineTo(10, size.height); // Нижняя граница с тем же отступом
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Класс для вырезания наклонного правого края (для левого блока)
class LeftSlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0); // Начинаем с верхнего левого угла
    path.lineTo(size.width - 10, 0); // Верхняя граница с отступом справа
    path.lineTo(
        size.width - 10, size.height); // Правая граница с тем же отступом
    path.lineTo(0, size.height); // Нижняя граница
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
