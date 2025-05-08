import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/survey_provider.dart';

class AgePage extends StatelessWidget {
  final VoidCallback onNext;

  const AgePage({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SurveyProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'What is your age?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Age',
                ),
                onChanged: (value) {
                  provider.updateAge(int.tryParse(value));
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: provider.state.age != null ? onNext : null,
                child: Text('Next'),
              ),
            ],
          ),
        );
      },
    );
  }
} 