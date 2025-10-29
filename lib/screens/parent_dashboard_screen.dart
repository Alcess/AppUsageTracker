import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_link_service.dart';
import '../services/role_service.dart';
import '../services/command_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  bool _isParent = false;
  bool _isLinked = false;
  String? _linkCode;
  bool _loading = true;

  // Track device lock state
  bool _isDeviceLocked = false;

  @override
  void initState() {
    super.initState();
    _checkParentStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh link status when screen comes into focus
    if (mounted) {
      _checkParentStatus();
    }
  }

  Future<void> _checkParentStatus() async {
    final role = await RoleService.getRole();
    final isLinked = await FamilyLinkService.isLinked();
    final linkCode = await FamilyLinkService.getLinkCode();

    setState(() {
      _isParent = role == AppRole.parent; // Fixed: using enum instead of string
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

    if (!_isParent) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'This screen is only available for parents.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildQuickActionsCard(),
            const SizedBox(height: 16),
            _buildUsageStatsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.family_restroom, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Family Link Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _isLinked ? Icons.check_circle : Icons.cancel,
                  color: _isLinked ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLinked ? 'Connected to child device' : 'Not connected',
                  style: TextStyle(
                    color: _isLinked ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Link Code: '),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _linkCode ?? 'Unknown',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Device Control',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Device lock/unlock button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleDeviceLock,
                icon: Icon(
                  _isDeviceLocked ? Icons.lock_open : Icons.lock,
                  color: Colors.white,
                ),
                label: Text(_isDeviceLocked ? 'Unlock Device' : 'Lock Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDeviceLocked ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            if (_isDeviceLocked) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Device is currently locked',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Usage Stats from Firestore',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Real-time usage data from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usage_data')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No usage data available yet.');
                }

                final latestDoc = snapshot.data!.docs.first;
                final data = latestDoc.data() as Map<String, dynamic>;

                final syncedAt = data['syncedAt'] as String?;
                final formattedTime = _formatSyncTime(syncedAt);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last synced: $formattedTime',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (data['events'] != null) ...[
                      const Text(
                        'Recent Activity:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...((data['events'] as List)
                          .take(5)
                          .map(
                            (event) =>
                                _buildEventItem(event as Map<String, dynamic>),
                          )),
                    ] else ...[
                      const Text('No recent activity data.'),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final packageName = event['packageName'] as String? ?? '';
    final appName = _getAppName(packageName);
    final eventType = event['eventType'] as int? ?? 0;
    final timestamp = event['timestamp'] as int? ?? 0;

    String eventDescription;
    IconData eventIcon;
    Color eventColor;

    switch (eventType) {
      case 1: // MOVE_TO_FOREGROUND
        eventDescription = 'Opened';
        eventIcon = Icons.launch;
        eventColor = Colors.green;
        break;
      case 2: // MOVE_TO_BACKGROUND
        eventDescription = 'Closed';
        eventIcon = Icons.close;
        eventColor = Colors.orange;
        break;
      default:
        eventDescription = 'Activity';
        eventIcon = Icons.info;
        eventColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: eventColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: eventColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(eventIcon, color: eventColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$eventDescription • ${_formatTimestamp(timestamp)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAppName(String packageName) {
    const packageToNameMap = {
      // Social Media
      'com.tiktok.android': 'TikTok',
      'com.instagram.android': 'Instagram',
      'com.snapchat.android': 'Snapchat',
      'com.facebook.katana': 'Facebook',
      'com.twitter.android': 'Twitter',
      'com.linkedin.android': 'LinkedIn',
      'com.pinterest': 'Pinterest',
      'com.reddit.frontpage': 'Reddit',
      'com.discord': 'Discord',
      'com.telegram.messenger': 'Telegram',
      'com.whatsapp': 'WhatsApp',
      'com.viber.voip': 'Viber',
      'com.skype.raider': 'Skype',
      'com.zhiliaoapp.musically': 'TikTok',

      // Video & Entertainment
      'com.google.android.youtube': 'YouTube',
      'com.netflix.mediaclient': 'Netflix',
      'com.amazon.avod.thirdpartyclient': 'Prime Video',
      'com.disney.disneyplus': 'Disney+',
      'com.hulu.plus': 'Hulu',
      'com.spotify.music': 'Spotify',
      'com.amazon.mp3': 'Amazon Music',
      'com.apple.android.music': 'Apple Music',
      'com.pandora.android': 'Pandora',
      'deezer.android.app': 'Deezer',
      'com.soundcloud.android': 'SoundCloud',
      'com.twitch.android.app': 'Twitch',

      // Gaming
      'com.roblox.client': 'Roblox',
      'com.ea.game.pvzheroes_row': 'Plants vs Zombies',
      'com.supercell.clashofclans': 'Clash of Clans',
      'com.supercell.clashroyale': 'Clash Royale',
      'com.king.candycrushsaga': 'Candy Crush',
      'com.mojang.minecraftpe': 'Minecraft',
      'com.epicgames.fortnite': 'Fortnite',
      'com.pubg.imobile': 'PUBG Mobile',
      'com.garena.game.codm': 'Call of Duty Mobile',
      'com.miHoYo.GenshinImpact': 'Genshin Impact',
      'com.rovio.angrybirdsdream': 'Angry Birds',
      'com.pokemongo': 'Pokemon GO',

      // Shopping & Food
      'com.amazon.mShop.android.shopping': 'Amazon',
      'com.ebay.mobile': 'eBay',
      'com.alibaba.aliexpresshd': 'AliExpress',
      'com.wish.buying': 'Wish',
      'com.ubercab': 'Uber',
      'com.ubercab.eats': 'Uber Eats',
      'com.grubhub.android': 'Grubhub',
      'com.dd.doordash': 'DoorDash',
      'com.mcdonalds.app': 'McDonalds',
      'com.starbucks.mobilecard': 'Starbucks',

      // Education & Productivity
      'com.duolingo': 'Duolingo',
      'com.khanacademy.android': 'Khan Academy',
      'com.google.android.apps.classroom': 'Google Classroom',
      'us.zoom.videomeetings': 'Zoom',
      'com.microsoft.teams': 'Microsoft Teams',
      'com.google.android.apps.meetings': 'Google Meet',
      'com.microsoft.office.word': 'Microsoft Word',
      'com.microsoft.office.powerpoint': 'PowerPoint',
      'com.microsoft.office.excel': 'Excel',
      'com.google.android.apps.docs': 'Google Docs',
      'com.google.android.apps.sheets': 'Google Sheets',
      'com.google.android.apps.slides': 'Google Slides',
      'com.evernote': 'Evernote',
      'com.notion.id': 'Notion',

      // Google Apps
      'com.google.android.gm': 'Gmail',
      'com.google.android.apps.maps': 'Google Maps',
      'com.google.android.googlequicksearchbox': 'Google Search',
      'com.google.android.apps.photos': 'Google Photos',
      'com.google.android.apps.drive': 'Google Drive',
      'com.google.android.calendar': 'Google Calendar',
      'com.google.android.apps.translate': 'Google Translate',
      'com.google.android.apps.chromecast.app': 'Google Home',
      'com.google.android.play.games': 'Google Play Games',

      // Apple/iOS equivalent Android apps
      'com.apple.android.facetime': 'FaceTime',
      'com.apple.android.imessage': 'iMessage',

      // Browser & Tools
      'com.android.chrome': 'Chrome',
      'org.mozilla.firefox': 'Firefox',
      'com.microsoft.emmx': 'Microsoft Edge',
      'com.opera.browser': 'Opera',
      'com.brave.browser': 'Brave',
      'com.duckduckgo.mobile.android': 'DuckDuckGo',

      // Finance & Banking
      'com.paypal.android.p2pmobile': 'PayPal',
      'com.venmo': 'Venmo',
      'com.coinbase.android': 'Coinbase',
      'com.squareup.cash': 'Cash App',
      'com.chase.sig.android': 'Chase Bank',
      'com.bankofamerica.mobile': 'Bank of America',
      'com.wellsfargo.mobile.android': 'Wells Fargo',

      // News & Reading
      'flipboard.app': 'Flipboard',
      'com.cnn.mobile.android.phone': 'CNN',
      'com.foxnews.android': 'Fox News',
      'com.nytimes.android': 'New York Times',
      'com.washingtonpost.rainbow': 'Washington Post',
      'bbc.mobile.news.ww': 'BBC News',
      'com.medium.reader': 'Medium',

      // Health & Fitness
      'com.fitbit.FitbitMobile': 'Fitbit',
      'com.nike.plusone': 'Nike Training',
      'com.myfitnesspal.android': 'MyFitnessPal',
      'com.headspace.android': 'Headspace',
      'com.calm.android': 'Calm',
      'com.strava': 'Strava',
      'com.peloton.callisto': 'Peloton',

      // Transportation
      'com.lyft.android': 'Lyft',
      'com.waze': 'Waze',
      'com.airbnb.android': 'Airbnb',
      'com.booking': 'Booking.com',
      'com.expedia.bookings': 'Expedia',
      'com.kayak.android': 'Kayak',

      // Android System Apps
      'com.android.settings': 'Settings',
      'com.android.camera2': 'Camera',
      'com.android.gallery3d': 'Gallery',
      'com.android.mms': 'Messages',
      'com.android.contacts': 'Contacts',
      'com.android.dialer': 'Phone',
      'com.android.calculator2': 'Calculator',
      'com.android.clock': 'Clock',
      'com.android.calendar': 'Calendar',
      'com.android.fileexplorer': 'File Manager',
      'com.android.vending': 'Google Play Store',
    };
    return packageToNameMap[packageName] ?? packageName;
  }

  String _formatSyncTime(String? isoString) {
    if (isoString == null) return 'Never';
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
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

  Future<void> _toggleDeviceLock() async {
    try {
      bool success;
      if (_isDeviceLocked) {
        // Unlock the device
        success = await CommandService.unlockDevice();
        if (success) {
          setState(() {
            _isDeviceLocked = false;
          });
          _showMessage('Device unlocked');
        } else {
          _showMessage('Failed to unlock device');
        }
      } else {
        // Lock the device
        success = await CommandService.lockDevice();
        if (success) {
          setState(() {
            _isDeviceLocked = true;
          });
          _showMessage('Device locked');
        } else {
          _showMessage('Failed to lock device');
        }
      }
    } catch (e) {
      _showMessage(
        'Failed to ${_isDeviceLocked ? 'unlock' : 'lock'} device: $e',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
