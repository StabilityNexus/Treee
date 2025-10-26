class TreeSpeciesConstants {
  static const List<String> commonTreeSpecies = [
    'Oak',
    'Pine',
    'Spruce',
    'Maple',
    'Birch',
    'Cedar',
    'Fir',
    'Elm',
    'Ash',
    'Beech',
    'Poplar',
    'Willow',
    'Cherry',
    'Walnut',
    'Hickory',
    'Cypress',
    'Redwood',
    'Sequoia',
    'Eucalyptus',
    'Acacia',
    'Mahogany',
    'Teak',
    'Bamboo',
    'Palm',
    'Coconut Palm',
    'Olive',
    'Apple',
    'Orange',
    'Lemon',
    'Mango',
    'Avocado',
    'Fig',
    'Banyan',
    'Neem',
    'Sal',
    'Rosewood',
    'Sandalwood',
    'Chestnut',
    'Sycamore',
    'Magnolia',
    'Dogwood',
    'Juniper',
    'Hemlock',
    'Larch',
    'Yew',
    'Other'
  ];

  static const Map<String, List<String>> speciesByCategory = {
    'Deciduous Trees': [
      'Oak',
      'Maple',
      'Birch',
      'Elm',
      'Ash',
      'Beech',
      'Poplar',
      'Willow',
      'Cherry',
      'Walnut',
      'Hickory',
      'Chestnut',
      'Sycamore',
      'Magnolia',
      'Dogwood'
    ],
    'Coniferous Trees': [
      'Pine',
      'Spruce',
      'Cedar',
      'Fir',
      'Cypress',
      'Redwood',
      'Sequoia',
      'Juniper',
      'Hemlock',
      'Larch',
      'Yew'
    ],
    'Tropical Trees': [
      'Eucalyptus',
      'Acacia',
      'Mahogany',
      'Teak',
      'Bamboo',
      'Palm',
      'Coconut Palm',
      'Banyan',
      'Neem',
      'Sal',
      'Rosewood',
      'Sandalwood'
    ],
    'Fruit Trees': [
      'Apple',
      'Orange',
      'Lemon',
      'Mango',
      'Avocado',
      'Fig',
      'Olive'
    ]
  };

  static List<String> getAllSpecies() {
    return commonTreeSpecies;
  }

  static List<String> getSpeciesByCategory(String category) {
    return speciesByCategory[category] ?? [];
  }

  static List<String> getCategories() {
    return speciesByCategory.keys.toList();
  }
}
