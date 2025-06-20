import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/duplicate_finder_bloc.dart';
import '../blocs/duplicate_finder_state.dart';
import '../services/file_service.dart';

class ScanSummary extends StatelessWidget {
  final FileService _fileService = FileService();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuplicateFinderBloc, DuplicateFinderState>(
      builder: (context, state) {
        if (state is DuplicateFinderCompleted) {
          final totalDuplicates = state.duplicates.length;
          final totalFiles = state.duplicates.fold<int>(
            0, (sum, duplicate) => sum + duplicate.count,
          );
          final totalSize = state.duplicates.fold<int>(
            0, (sum, duplicate) => sum + (duplicate.size * duplicate.count),
          );
          final wastedSpace = state.duplicates.fold<int>(
            0, (sum, duplicate) => sum + (duplicate.size * (duplicate.count - 1)),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Duplicate Groups',
                      value: totalDuplicates.toString(),
                      icon: Icons.content_copy,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Files',
                      value: totalFiles.toString(),
                      icon: Icons.description,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Size',
                      value: _fileService.formatFileSize(totalSize),
                      icon: Icons.storage,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Wasted Space',
                      value: _fileService.formatFileSize(wastedSpace),
                      icon: Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}