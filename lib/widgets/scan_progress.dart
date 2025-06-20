import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/duplicate_finder_bloc.dart';
import '../blocs/duplicate_finder_state.dart';

class ScanProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuplicateFinderBloc, DuplicateFinderState>(
      builder: (context, state) {
        if (state is DuplicateFinderScanning) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scanning in Progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              LinearProgressIndicator(),
              SizedBox(height: 16),
              Text(
                state.progress,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (state.fileCount > 0) ...[
                SizedBox(height: 8),
                Text(
                  'Files found: ${state.fileCount}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}