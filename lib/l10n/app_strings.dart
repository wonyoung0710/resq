class AppStrings {
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ja': '日本語',
    'zh': '中文',
    'vi': 'Tiếng Việt',
    'de': 'Deutsch',
  };

  static const Map<String, String> languageFlags = {
    'en': '🇺🇸',
    'ja': '🇯🇵',
    'zh': '🇨🇳',
    'vi': '🇻🇳',
    'de': '🇩🇪',
  };

  static const Map<String, String> defaultStrings = {
    // Settings
    'settings': 'Settings',
    'language': 'LANGUAGE',
    'notifications': 'NOTIFICATIONS',
    'about': 'ABOUT',
    'app_language': 'App language',
    'alert_translation': 'Alert translation',
    'emergency_alerts': 'Emergency alerts',
    'push_notifications': 'Push notifications',
    'alert_sound': 'Alert sound',
    'alarm_on_critical': 'Alarm on critical alerts',
    'region': 'Region',
    'my_alert_area': 'My alert area',
    'app_version': 'App version',
    // Nav
    'nav_home': 'Home',
    'nav_alerts': 'Alerts',
    'nav_embassy': 'Embassy',
    'nav_settings': 'Settings',
    // Home
    'no_active_alerts': 'No active alerts',
    'area_safe': 'Your area is currently safe.\nStay prepared.',
    'all_clear': 'All clear · Cheonan',
    'quick_actions': 'QUICK ACTIONS',
    'call_119': 'Call 119 — Emergency',
    'fire_ambulance': 'Fire, ambulance, rescue',
    'safety_guide': 'Safety guide',
    'safety_guide_sub': 'Earthquake, rain, fire tips',
    'recent_alerts': 'RECENT ALERTS',
    'no_recent_alerts': 'No recent alerts',
    'alert_active': 'Active',
    'alert_resolved': 'Resolved',
    'alert_tap_to_translate': 'Tap to view full translation',
    // QR
    'emergency_info': 'Emergency Info',
    'scanned_from': 'Scanned from SafeKorea',
    'qr_not_setup': 'No Emergency Info Set Up',
    'qr_not_setup_sub': 'Set up your emergency profile so\nrescuers can help you faster.',
    'setup_my_info': 'Set Up My Info',
    'edit_my_info': 'Edit My Info',
    'qr_warning': 'This information is provided for emergency use only. Please contact the embassy if further assistance is needed.',
    'blood_type': 'BLOOD TYPE',
    'nationality': 'NATIONALITY',
    'emergency_contacts': 'EMERGENCY CONTACTS',
    'medical_info': 'MEDICAL INFO',
    'allergies': 'ALLERGIES',
    'conditions': 'CONDITIONS',
    'basic_info': 'BASIC INFO',
    'name': 'NAME',
    'name_hint': 'Full name',
    'age': 'AGE',
    'age_hint': 'Your age',
    'nationality_hint': 'e.g. American',
    'gender': 'GENDER',
    'male': 'Male',
    'female': 'Female',
    'save': 'Save',
    'contact': 'Contact',
    'relationship': 'RELATIONSHIP',
    'relationship_hint': 'e.g. Mother, Father',
    'phone': 'PHONE',
    'phone_hint': '+1-555-0000',
    'add_contact': '+ Add Emergency Contact',
    'allergy_hint': 'e.g. Penicillin, Peanuts',
    'condition_hint': 'e.g. Asthma, Diabetes',
    'add_allergy': '+ Add Allergy',
    'add_condition': '+ Add Condition',
    // Call 119
    'call_title': 'Emergency Call',
    'call_subtitle': 'Korea emergency numbers',
    'call_119_desc': 'Fire · Ambulance · Rescue',
    'tap_to_call': 'Tap to Call 119',
    'other_numbers': 'OTHER EMERGENCY NUMBERS',
    'police_112': 'Police — 112',
    'police_112_sub': 'Crime, accident, security',
    'medical_1339': 'Medical Helpline — 1339',
    'medical_1339_sub': 'Medical advice & guidance',
    'nearby_hospitals': 'Nearby Hospitals',
    'nearby_hospitals_sub': 'Find emergency rooms near you',
    'call_tip_title': '💡 TIP — When calling 119',
    'call_tip_body': 'State your location first, then describe the emergency. Operators speak basic English. Stay calm and follow instructions.',
    // Embassy
    'embassy_search_hint': 'Search country...',
    'embassy_no_results': 'No results found',
    // Alerts Page
    'filter_all':        'All',
    'filter_rain':       'Rain / Typhoon',
    'filter_flood':      'Flood',
    'filter_earthquake': 'Earthquake',
    'filter_fire':       'Fire',
    'filter_snow':       'Snow',
    'filter_landslide':  'Landslide',
    'filter_other':      'Other',
    'alerts_loading':          'Loading alerts...',
    'alerts_connection_error': 'Cannot connect to server.',
    'alerts_empty':            'No alerts found.',
    'retry':                   'Retry',

    // ===== Safety Guide =====
    'guide_earthquake': 'Earthquake',
    'guide_rain': 'Heavy Rain & Flood',
    'guide_fire': 'Fire',
    'Drop & Stay Calm': 'Drop & Stay Calm',
    'When shaking starts, drop down and watch for falling objects':
        'When shaking starts, drop down and watch for falling objects',
    'Cover & Hold On': 'Cover & Hold On',
    'Take cover under a sturdy piece of furniture and hold on until the shaking stops':
        'Take cover under a sturdy piece of furniture and hold on until the shaking stops',
    'Secure an exit': 'Secure an exit',
    'Once shaking stops, open a door and move calmly, protecting your head':
        'Once shaking stops, open a door and move calmly, protecting your head',
    'Evacuate safely': 'Evacuate safely',
    'Use the stairs, not elevators, and head to a safe assembly point':
        'Use the stairs, not elevators, and head to a safe assembly point',
    'If you are outdoors': 'If you are outdoors',
    'Move away from buildings, power lines, and signs to an open area, and protect your head':
        'Move away from buildings, power lines, and signs to an open area, and protect your head',
    'Pack emergency supplies': 'Pack emergency supplies',
    'Gather water, food, and essentials in a bag before water rises':
        'Gather water, food, and essentials in a bag before water rises',
    'Call 119': 'Call 119',
    'Call 119 to report flooding and ask for help if you are in danger':
        'Call 119 to report flooding and ask for help if you are in danger',
    'Move to high ground': 'Move to high ground',
    'Move to higher floors or ground immediately and stay away from submerged cars':
        'Move to higher floors or ground immediately and stay away from submerged cars',
    'Go to a shelter': 'Go to a shelter',
    'Head to a designated shelter and never cross flooded roads or bridges':
        'Head to a designated shelter and never cross flooded roads or bridges',
    'Sound the alarm': 'Sound the alarm',
    'If you see a fire, press the alarm and shout to alert others nearby':
        'If you see a fire, press the alarm and shout to alert others nearby',
    'Call for help': 'Call for help',
    'Call 119 (fire department) and report the location clearly':
        'Call 119 (fire department) and report the location clearly',
    'Stay low, cover your nose': 'Stay low, cover your nose',
    'Cover your nose and mouth with a cloth and stay low to avoid smoke':
        'Cover your nose and mouth with a cloth and stay low to avoid smoke',
    'Use the stairs': 'Use the stairs',
    'NEVER use elevators-take the stairs and evacuate to a safe place outside':
        'NEVER use elevators-take the stairs and evacuate to a safe place outside',
  };
}