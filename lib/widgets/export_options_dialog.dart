import 'package:flutter/material.dart';
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/export_service_fixed.dart';

class ExportOptionsDialog extends StatelessWidget {
  final LabSession labSession;
  final List<StudentModel> students;
  final String? selectedExperiment;

  const ExportOptionsDialog({
    Key? key,
    required this.labSession,
    required this.students,
    this.selectedExperiment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final exportService = ExportService();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Options',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildExportOption(
              context,
              icon: Icons.science,
              title: selectedExperiment != null
                  ? 'Export Experiment ${selectedExperiment!}'
                  : 'Export Current Experiment',
              subtitle: 'Export marks for the current experiment only',
              onTap: () async {
                Navigator.pop(context);
                try {
                  if (selectedExperiment != null) {
                    await exportService.exportExperimentMarks(
                      labSession: labSession,
                      experimentNumber: selectedExperiment!,
                      students: students,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Experiment marks exported successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No experiment selected'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              color: Colors.blue,
              enabled: selectedExperiment != null,
            ),
            const Divider(),
            _buildExportOption(
              context,
              icon: Icons.science_outlined,
              title: 'Export All Experiments',
              subtitle: 'Export marks for all experiments',
              onTap: () async {
                Navigator.pop(context);
                try {
                  await exportService.exportAllExperimentMarks(
                    labSession: labSession,
                    students: students,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All experiment marks exported successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              color: Colors.indigo,
            ),
            const Divider(),
            _buildExportOption(
              context,
              icon: Icons.assignment,
              title: 'Export Internal Marks',
              subtitle: 'Export Internal 1 and Internal 2 marks',
              onTap: () async {
                Navigator.pop(context);
                try {
                  await exportService.exportInternalMarks(
                    labSession: labSession,
                    students: students,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Internal marks exported successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              color: Colors.purple,
            ),
            const Divider(),
            _buildExportOption(
              context,
              icon: Icons.assessment,
              title: 'Export M1/M2 Marks',
              subtitle: 'Export only M1 and M2 marks (auto-calculated)',
              onTap: () async {
                Navigator.pop(context);
                try {
                  await exportService.exportM1M2Marks(
                    labSession: labSession,
                    students: students,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('M1/M2 marks exported successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              color: Colors.green,
            ),
            const Divider(),
            _buildExportOption(
              context,
              icon: Icons.grading,
              title: 'Export Final Assessment',
              subtitle: 'Export viva marks and final lab grades',
              onTap: () async {
                Navigator.pop(context);
                try {
                  await exportService.exportFinalLabMarks(
                    labSession: labSession,
                    students: students,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Final assessment exported successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
