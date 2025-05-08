import 'package:flutter/material.dart';
import '../models/exercise.dart';

class AddExerciseBottomSheet extends StatefulWidget {
  final List<Exercise> allExercises;
  final Function(List<Exercise>) onExercisesAdded;

  const AddExerciseBottomSheet({
    Key? key,
    required this.allExercises,
    required this.onExercisesAdded,
  }) : super(key: key);

  @override
  _AddExerciseBottomSheetState createState() => _AddExerciseBottomSheetState();
}

class _AddExerciseBottomSheetState extends State<AddExerciseBottomSheet> {
  List<Exercise> _filteredExercises = [];
  Set<Exercise> _selectedExercises = {};
  TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  
  final List<String> _categories = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Full Body',
  ];

  @override
  void initState() {
    super.initState();
    _filteredExercises = List.from(widget.allExercises);
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterExercises);
    _searchController.dispose();
    super.dispose();
  }

  void _filterExercises() {
    final searchQuery = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredExercises = widget.allExercises.where((exercise) {
        // Проверяем соответствие поисковому запросу
        final matchesSearch = searchQuery.isEmpty || 
            exercise.name.toLowerCase().contains(searchQuery);
            
        // Проверяем соответствие выбранной категории
        final matchesCategory = _selectedCategory == 'All' || 
            exercise.muscleGroup.toLowerCase().contains(_selectedCategory.toLowerCase());
            
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterExercises();
  }

  void _toggleExerciseSelection(Exercise exercise) {
    setState(() {
      if (_selectedExercises.contains(exercise)) {
        _selectedExercises.remove(exercise);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF252527),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Exercises',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.blue,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF2C2C2E),
                hintText: 'Search exercises...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Category chips
          Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((category) {
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _selectCategory(category);
                      }
                    },
                    backgroundColor: Colors.grey[900],
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                final isSelected = _selectedExercises.contains(exercise);
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF3A3A3C) : Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _getExerciseEmoji(exercise.equipment),
                          style: TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    title: Text(
                      exercise.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${exercise.muscleGroup} • ${exercise.equipment}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        : SizedBox(width: 24),
                    onTap: () => _toggleExerciseSelection(exercise),
                  ),
                );
              },
            ),
          ),
          
          // Bottom action bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF252527),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedExercises.length} exercises selected',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectedExercises.isEmpty
                      ? null
                      : () {
                          widget.onExercisesAdded(_selectedExercises.toList());
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getExerciseEmoji(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'dumbbells':
        return '🏋️';
      case 'bench':
        return '🛏️';
      case 'none':
        return '🦵';
      default:
        return '💪';
    }
  }
} 