import 'package:installed_apps/installed_apps.dart';

/// Centralized app name mapping utility
/// Uses hybrid approach: hard-coded for common apps, installed_apps package for others
class AppNameMapper {
  // Hard-coded mappings for the most common apps (for performance and reliability)
  static const Map<String, String> _commonAppsMap = {
    // Social Media
    'com.tiktok.android': 'TikTok',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.instagram.android': 'Instagram',
    'com.snapchat.android': 'Snapchat',
    'com.facebook.katana': 'Facebook',
    'com.facebook.orca': 'Messenger',
    'com.facebook.lite': 'Facebook Lite',
    'com.twitter.android': 'Twitter',
    'com.linkedin.android': 'LinkedIn',
    'com.pinterest': 'Pinterest',
    'com.reddit.frontpage': 'Reddit',
    'com.discord': 'Discord',
    'com.telegram.messenger': 'Telegram',
    'org.telegram.messenger': 'Telegram',
    'com.whatsapp': 'WhatsApp',
    'com.whatsapp.w4b': 'WhatsApp Business',
    'com.viber.voip': 'Viber',
    'com.skype.raider': 'Skype',
    'com.vkontakte.android': 'VKontakte',

    // Video & Entertainment
    'com.google.android.youtube': 'YouTube',
    'com.google.android.youtube.tv': 'YouTube TV',
    'com.netflix.mediaclient': 'Netflix',
    'com.amazon.avod.thirdpartyclient': 'Prime Video',
    'com.disney.disneyplus': 'Disney+',
    'com.hulu.plus': 'Hulu',
    'com.hbo.hbonow': 'HBO Max',
    'com.spotify.music': 'Spotify',
    'com.amazon.mp3': 'Amazon Music',
    'com.apple.android.music': 'Apple Music',
    'com.pandora.android': 'Pandora',
    'deezer.android.app': 'Deezer',
    'com.soundcloud.android': 'SoundCloud',
    'com.twitch.android.app': 'Twitch',
    'com.vimeo.android.videoapp': 'Vimeo',

    // Gaming
    'com.roblox.client': 'Roblox',
    'com.ea.game.pvzheroes_row': 'Plants vs Zombies',
    'com.supercell.clashofclans': 'Clash of Clans',
    'com.supercell.clashroyale': 'Clash Royale',
    'com.supercell.hayday': 'Hay Day',
    'com.supercell.boombeach': 'Boom Beach',
    'com.king.candycrushsaga': 'Candy Crush Saga',
    'com.king.candycrushsodasaga': 'Candy Crush Soda',
    'com.mojang.minecraftpe': 'Minecraft',
    'com.epicgames.fortnite': 'Fortnite',
    'com.pubg.imobile': 'PUBG Mobile',
    'com.garena.game.codm': 'Call of Duty Mobile',
    'com.miHoYo.GenshinImpact': 'Genshin Impact',
    'com.rovio.angrybirdsdream': 'Angry Birds',
    'com.nianticlabs.pokemongo': 'Pokemon GO',
    'com.innersloth.spacemafia': 'Among Us',
    'com.riotgames.league.wildrift': 'League of Legends: Wild Rift',

    // Shopping & Food
    'com.amazon.mShop.android.shopping': 'Amazon',
    'com.ebay.mobile': 'eBay',
    'com.alibaba.aliexpresshd': 'AliExpress',
    'com.wish.buying': 'Wish',
    'com.etsy.android': 'Etsy',
    'com.ubercab': 'Uber',
    'com.ubercab.eats': 'Uber Eats',
    'com.grubhub.android': 'Grubhub',
    'com.dd.doordash': 'DoorDash',
    'com.postmates.android': 'Postmates',
    'com.mcdonalds.app': 'McDonalds',
    'com.starbucks.mobilecard': 'Starbucks',
    'com.dominos.android': 'Dominos Pizza',

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
    'com.microsoft.office.outlook': 'Outlook',
    'com.microsoft.office.onenote': 'OneNote',
    'com.google.android.apps.docs': 'Google Docs',
    'com.google.android.apps.docs.editors.docs': 'Google Docs',
    'com.google.android.apps.docs.editors.sheets': 'Google Sheets',
    'com.google.android.apps.docs.editors.slides': 'Google Slides',
    'com.evernote': 'Evernote',
    'com.notion.id': 'Notion',
    'com.todoist': 'Todoist',
    'com.any.do': 'Any.do',

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
    'com.google.android.keep': 'Google Keep',
    'com.google.android.apps.authenticator2': 'Google Authenticator',
    'com.google.android.apps.fitness': 'Google Fit',

    // Browser & Tools
    'com.android.chrome': 'Chrome',
    'org.mozilla.firefox': 'Firefox',
    'com.microsoft.emmx': 'Microsoft Edge',
    'com.opera.browser': 'Opera',
    'com.brave.browser': 'Brave',
    'com.duckduckgo.mobile.android': 'DuckDuckGo',
    'com.opera.mini.native': 'Opera Mini',
    'com.UCMobile.intl': 'UC Browser',

    // Finance & Banking
    'com.paypal.android.p2pmobile': 'PayPal',
    'com.venmo': 'Venmo',
    'com.coinbase.android': 'Coinbase',
    'com.squareup.cash': 'Cash App',
    'com.chase.sig.android': 'Chase Bank',
    'com.bankofamerica.mobile': 'Bank of America',
    'com.wellsfargo.mobile.android': 'Wells Fargo',
    'com.usbank.mobilebanking': 'US Bank',
    'com.citi.citimobile': 'Citi Mobile',

    // News & Reading
    'flipboard.app': 'Flipboard',
    'com.cnn.mobile.android.phone': 'CNN',
    'com.foxnews.android': 'Fox News',
    'com.nytimes.android': 'New York Times',
    'com.washingtonpost.rainbow': 'Washington Post',
    'bbc.mobile.news.ww': 'BBC News',
    'com.medium.reader': 'Medium',
    'com.google.android.apps.magazines': 'Google News',

    // Health & Fitness
    'com.fitbit.FitbitMobile': 'Fitbit',
    'com.nike.plusone': 'Nike Training',
    'com.nike.snkrs': 'Nike SNKRS',
    'com.myfitnesspal.android': 'MyFitnessPal',
    'com.headspace.android': 'Headspace',
    'com.calm.android': 'Calm',
    'com.strava': 'Strava',
    'com.peloton.callisto': 'Peloton',
    'com.samsung.android.app.health': 'Samsung Health',

    // Transportation
    'com.lyft.android': 'Lyft',
    'com.waze': 'Waze',
    'com.airbnb.android': 'Airbnb',
    'com.booking': 'Booking.com',
    'com.expedia.bookings': 'Expedia',
    'com.kayak.android': 'Kayak',
    'com.tripadvisor.tripadvisor': 'TripAdvisor',

    // Photography
    'com.adobe.photoshop.express': 'Photoshop Express',
    'com.adobe.lrmobile': 'Lightroom',
    'com.vsco.cam': 'VSCO',
    'com.canva.editor': 'Canva',
    'com.picsart.studio': 'PicsArt',

    // Dating & Social
    'com.tinder': 'Tinder',
    'com.bumble.app': 'Bumble',
    'com.match.android.matchmobile': 'Match',
    'com.pof.android': 'Plenty of Fish',
    'com.okcupid.okcupid': 'OkCupid',

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
    'com.google.android.packageinstaller': 'Package Installer',
    'com.android.systemui': 'System UI',

    // Samsung Apps
    'com.samsung.android.messaging': 'Samsung Messages',
    'com.samsung.android.gallery3d': 'Samsung Gallery',
    'com.samsung.android.contacts': 'Samsung Contacts',
    'com.samsung.android.dialer': 'Samsung Phone',
    'com.samsung.android.calendar': 'Samsung Calendar',
    'com.samsung.android.app.notes': 'Samsung Notes',

    // Apple/iOS equivalent Android apps
    'com.apple.android.facetime': 'FaceTime',
    'com.apple.android.imessage': 'iMessage',
  };

  /// Get user-friendly app name using hybrid approach
  /// 1. Check hard-coded common apps first (fast)
  /// 2. Try installed_apps package for uncommon apps
  /// 3. Fallback to package name if all else fails
  static Future<String> getAppName(String packageName) async {
    // First, check if it's a common app (hard-coded for performance)
    if (_commonAppsMap.containsKey(packageName)) {
      return _commonAppsMap[packageName]!;
    }

    // For uncommon apps, try to get the real name using installed_apps package
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      final app = apps.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => throw Exception('App not found'),
      );

      // If we got a valid app with a name that's different from package name, use it
      if (app.name.isNotEmpty && app.name != packageName) {
        return app.name;
      }
    } catch (e) {
      // If installed_apps fails, continue to fallback
    }

    // Fallback to package name
    return packageName;
  }

  /// Synchronous version that only checks hard-coded mappings
  /// Use this when you need immediate results without async calls
  static String getAppNameSync(String packageName) {
    return _commonAppsMap[packageName] ?? packageName;
  }

  /// Check if a package name has a hard-coded mapping
  static bool hasHardcodedMapping(String packageName) {
    return _commonAppsMap.containsKey(packageName);
  }

  /// Get all hard-coded package names
  static Iterable<String> get mappedPackages => _commonAppsMap.keys;

  /// Get all hard-coded app names
  static Iterable<String> get appNames => _commonAppsMap.values;

  /// Get the total count of hard-coded app mappings
  static int get mappingCount => _commonAppsMap.length;
}
