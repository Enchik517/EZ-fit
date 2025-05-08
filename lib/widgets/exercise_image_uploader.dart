import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/exercise.dart';
import '../services/exercise_image_service.dart';
import '../widgets/exercise_image.dart';

class ExerciseImageUploader extends StatefulWidget {
  final Exercise exercise;
  final Function(String imageUrl) onImageUploaded;
  final double height;
  final double width;

  const ExerciseImageUploader({
    Key? key,
    required this.exercise,
    required this.onImageUploaded,
    this.height = 200,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  State<ExerciseImageUploader> createState() => _ExerciseImageUploaderState();
}

class _ExerciseImageUploaderState extends State<ExerciseImageUploader> {
  bool _isUploading = false;
  final _imagePicker = ImagePicker();

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      // Получаем байты изображения
      final imageBytes = await pickedFile.readAsBytes();

      // Получаем расширение файла
      final extension = pickedFile.name.split('.').last.toLowerCase();

      // Загружаем изображение
      final imageUrl = await ExerciseImageService.uploadExerciseImage(
        widget.exercise.id,
        imageBytes,
        extension,
      );

      if (imageUrl != null) {
        // Обновляем URL изображения в базе данных
        await ExerciseImageService.updateExerciseImageUrl(
          widget.exercise.id,
          imageUrl,
        );

        // Вызываем колбэк с новым URL
        widget.onImageUploaded(imageUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки изображения: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Изображение упражнения
        Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isUploading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                  ),
                )
              : ExerciseImage(
                  exercise: widget.exercise,
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                ),
        ),

        // Кнопка для загрузки изображения
        Positioned(
          right: 12,
          bottom: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: _isUploading
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => _buildImageSourceSelection(),
                      );
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSourceSelection() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Сделать фото'),
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Выбрать из галереи'),
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }
}
