import 'package:flutter/material.dart';

class StepCountSelector extends StatelessWidget {
  const StepCountSelector({
    super.key,
    required this.stepCount,
    required this.onChange,
  });

  final int stepCount;
  final Function(int) onChange;

  handleLess() {
    onChange(stepCount - 1);
  }

  handleMore() {
    onChange(stepCount + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Steps'),
        IconButton(icon: Icon(Icons.arrow_back), onPressed: handleLess),
        Text(
          stepCount.toString(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(icon: Icon(Icons.arrow_forward), onPressed: handleMore),
      ],
    );
  }
}
