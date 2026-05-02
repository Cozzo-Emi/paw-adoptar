import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = context.read<ApiClient>();
      final queryParams = <String, String>{};
      if (_statusFilter != null) queryParams['status'] = _statusFilter!;

      final response = await apiClient.dio.get(
        '/moderation/reports',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final list = response.data as List<dynamic>;
      setState(() {
        _reports = list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateReport(String reportId, String newStatus) async {
    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.dio.put('/moderation/reports/$reportId', data: {
        'status': newStatus,
        'resolution_notes': 'Moderado a $newStatus',
      });
      _loadReports();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${e.toString()}')),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'reviewing':
        return 'Revisando';
      case 'resolved':
        return 'Resuelto';
      case 'dismissed':
        return 'Descartado';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewing':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'fraud':
        return 'Fraude';
      case 'abuse':
        return 'Abuso';
      case 'fake_listing':
        return 'Publicación falsa';
      case 'inappropriate':
        return 'Contenido inapropiado';
      case 'other':
        return 'Otro';
      default:
        return reason;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Moderación'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              _statusFilter = v == 'all' ? null : v;
              _loadReports();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('Todos')),
              const PopupMenuItem(value: 'pending', child: Text('Pendientes')),
              const PopupMenuItem(value: 'reviewing', child: Text('Revisando')),
              const PopupMenuItem(value: 'resolved', child: Text('Resueltos')),
              const PopupMenuItem(value: 'dismissed', child: Text('Descartados')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay reportes', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final r = _reports[index];
                      return _ReportCard(
                        reason: _reasonLabel(r['reason'] as String),
                        description: r['description'] as String,
                        status: r['status'] as String,
                        statusLabel: _statusLabel(r['status'] as String),
                        statusColor: _statusColor(r['status'] as String),
                        createdAt: r['created_at'] as String,
                        reportId: r['id'] as String,
                        onResolve: () => _updateReport(r['id'] as String, 'resolved'),
                        onDismiss: () => _updateReport(r['id'] as String, 'dismissed'),
                        onReview: () => _updateReport(r['id'] as String, 'reviewing'),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String reason;
  final String description;
  final String status;
  final String statusLabel;
  final Color statusColor;
  final String createdAt;
  final String reportId;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;
  final VoidCallback onReview;

  const _ReportCard({
    required this.reason,
    required this.description,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.createdAt,
    required this.reportId,
    required this.onResolve,
    required this.onDismiss,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(createdAt);
    final formatted = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reason,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(formatted, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            if (status == 'pending' || status == 'reviewing') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'pending')
                    OutlinedButton(
                      onPressed: onReview,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                      child: const Text('Revisar'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Descartar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onResolve,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Resolver'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
