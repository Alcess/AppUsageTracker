import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_link_service.dart';
import '../services/role_service.dart';

class ChildUsageViewScreen extends StatefulWidget {
  const ChildUsageViewScreen({super.key});

  @override
  State<ChildUsageViewScreen> createState() => _ChildUsageViewScreenState();
}

class _ChildUsageViewScreenState extends State<ChildUsageViewScreen> {
  bool _isParent = false;
  bool _isLinked = false;
  String? _linkCode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkParentStatus();
  }

  Future<void> _checkParentStatus() async {
    final role = await RoleService.getRole();
    final isLinked = await FamilyLinkService.isLinked();
    final linkCode = await FamilyLinkService.getLinkCode();

    setState(() {
      _isParent = role == AppRole.parent;
      _isLinked = isLinked;
      _linkCode = linkCode;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isParent || !_isLinked || _linkCode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Child Usage')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.family_restroom, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Not Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Link to a child device in Settings to view their app usage',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child App Usage'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('links')
            .doc(_linkCode)
            .collection('usage_data')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Usage Data Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Usage data will appear here once your child uses their device',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final events = data['events'] as List<dynamic>? ?? [];
              final syncedAt = data['syncedAt'] as String?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const Icon(Icons.schedule, color: Colors.blue),
                  title: Text(
                    'Usage Session',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    syncedAt != null
                        ? 'Synced: ${_formatDateTime(syncedAt)}'
                        : 'Recent usage',
                  ),
                  children: [
                    if (events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No app events in this session'),
                      )
                    else
                      ...events.map((event) => _buildEventTile(event)).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventTile(dynamic event) {
    final packageName = event['packageName'] as String? ?? '';
    final appName = event['appName'] as String? ?? packageName;
    final eventType = event['eventType'] as int? ?? 0;
    final timestamp = event['timestamp'] as int? ?? 0;

    IconData eventIcon;
    String eventDescription;
    Color eventColor;

    switch (eventType) {
      case 1: // App opened
        eventIcon = Icons.play_arrow;
        eventDescription = 'Opened';
        eventColor = Colors.green;
        break;
      case 2: // App closed
        eventIcon = Icons.stop;
        eventDescription = 'Closed';
        eventColor = Colors.red;
        break;
      default:
        eventIcon = Icons.info;
        eventDescription = 'Activity';
        eventColor = Colors.blue;
    }

    return ListTile(
      dense: true,
      leading: Icon(eventIcon, color: eventColor, size: 20),
      title: Text(
        appName.isNotEmpty ? appName : packageName,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '$eventDescription • ${_formatTimestamp(timestamp)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: eventColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          eventDescription,
          style: TextStyle(
            color: eventColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  String _formatTimestamp(int timestamp) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }
}
