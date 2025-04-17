// Dota Hero

// ignore_for_file: file_names

class DotaHero {
  final int id;
  final String name;
  final String localizedName;
  final String primaryAttr;
  final String attackType;
  final List<String> roles;

  DotaHero({
    required this.id,
    required this.name,
    required this.localizedName,
    required this.primaryAttr,
    required this.attackType,
    required this.roles,
  });

  factory DotaHero.fromJson(Map<String, dynamic> json) {
    return DotaHero(
      id: json['id'],
      name: json['name'],
      localizedName: json['localized_name'],
      primaryAttr: json['primary_attr'],
      attackType: json['attack_type'],
      roles: List<String>.from(json['roles']),
    );
  }

  // Map of exceptions for hero names
  static final Map<String, String> nameExceptions = {
    'io': 'wisp',
    'windranger': 'windrunner',
    'centaur_warrunner': 'centaur',
    'clockwerk': 'rattletrap',
    'doom': 'doom_bringer',
    'lifestealer': 'life_stealer',
    'magnus': 'magnataur',
    "nature's_prophet": 'furion',
    'shadow_fiend': 'nevermore',
    'necrophos': 'necrolyte',
    'outworld_destroyer': 'obsidian_destroyer',
    'queen_of_pain': 'queenofpain',
    'treant_protector': 'treant',
    'zeus': 'zuus',
    'wraith_king': 'skeleton_king',
    'timbersaw': 'shredder',
    'underlord': 'abyssal_underlord',
    'vengeful_spirit': 'vengefulspirit',
  };

  // Map of exceptions for custom URLs
  static final Map<String, String> urlExceptions = {
    'dawnbreaker': 'https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/dawnbreaker.png',
    // Add more custom URLs here
  };

  // Computed property to retrieve the hero's image URL
  String get imageUrl {
    String formattedName = localizedName.toLowerCase().replaceAll(' ', '_').replaceAll('-', '');

    // Check for custom URL first
    if (urlExceptions.containsKey(formattedName)) {
      return urlExceptions[formattedName]!;
    }

    // Apply name exceptions if needed
    if (nameExceptions.containsKey(formattedName)) {
      formattedName = nameExceptions[formattedName]!;
    }

    // Default URL
    return 'https://cdn.dota2.com/apps/dota2/images/heroes/${formattedName}_full.png';
  }
}
