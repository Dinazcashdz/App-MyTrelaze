import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n.dart';

bool? _isOpen(Map r) {
  final now = DateTime.now();
  final h = now.hour + now.minute / 60.0;
  final wd = now.weekday; // 1=lun … 7=dim
  final nom = r['nom'] as String;

  bool between(double from, double to) => h >= from && h < to;

  switch (nom) {
    case 'McDonald\'s Trélazé':
      return between(11, 21.75);
    case 'SD Kebab':
    case 'Mr Burger':
      if (wd == 1 || wd == 3 || wd == 4) {
        return between(11.83, 14.42) || between(18, 22.5);
      } else if (wd == 5 || wd == 6) {
        return between(11.83, 16) || between(18, 23);
      } else {
        return between(17, 23);
      }
    case 'MG Tacos':
      if (wd <= 5) return between(11.5, 14) || between(18, 23);
      return between(18, 23);
    case 'Capital Tacos':
      if (wd == 7) return between(11.5, 23);
      return between(11.5, 14.5) || between(18, 23);
    case 'Le Swigny':
      if (wd == 6 || wd == 7) return between(11.5, 14.5) || between(19, 22.5);
      if (wd == 1) return null; // fermé lundi
      return between(11.5, 14.5) || between(19, 22.5);
    default:
      return null;
  }
}

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});
  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  Set<String> _favoris = {};

  @override
  void initState() {
    super.initState();
    _loadFavoris();
  }

  Future<void> _loadFavoris() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('resto_favoris') ?? [];
    if (mounted) setState(() => _favoris = list.toSet());
  }

  Future<void> _toggleFavori(String nom) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoris.contains(nom)) {
        _favoris.remove(nom);
      } else {
        _favoris.add(nom);
      }
    });
    await prefs.setStringList('resto_favoris', _favoris.toList());
  }

  static const _restaurants = <Map<String, Object>>[
    {
      'nom': 'SD Kebab',
      'type': 'Kebab • Tacos • Restauration rapide',
      'adresse': '19 Rue Jean Jaurès, Trélazé',
      'tel': '',
      'horaires': 'Lun/Mer/Jeu : 11h50–14h25 / 18h–22h30\nVen–Sam : 11h50–16h / 18h–23h\nDim : 17h–23h',
      'note': '4.5',
      'emoji': '🥙',
      'color': Color(0xFF388E3C),
      'menuUrl': '',
      'tags': ['Sur place', 'À emporter', 'Uber Eats'],
    },
    {
      'nom': 'Mr Burger',
      'type': 'Burgers • Fast food • Américain',
      'adresse': '19 Rue Jean Jaurès, Trélazé',
      'tel': '',
      'horaires': 'Lun/Mer/Jeu : 11h45–14h30 / 18h–22h30\nVen–Sam : 11h45–15h / 18h–23h\nDim : 17h–23h',
      'note': '4.4',
      'emoji': '🍔',
      'color': Color(0xFFD32F2F),
      'menuUrl': '',
      'tags': ['Sur place', 'À emporter', 'Uber Eats'],
    },
    {
      'nom': 'MG Tacos',
      'type': 'Tacos • Pizza • Restauration rapide',
      'adresse': '110 Rue Louis Pasteur, Trélazé',
      'tel': '0761329620',
      'horaires': 'Lun–Ven : 11h30–14h / 18h–23h\nSam–Dim : 18h–23h',
      'note': '4.6',
      'emoji': '🌮',
      'color': Color(0xFFE8A020),
      'menuUrl': '',
      'tags': ['Sur place', 'À emporter', 'Uber Eats'],
    },
    {
      'nom': 'McDonald\'s Trélazé',
      'type': 'Burgers • Fast food • Américain',
      'adresse': 'ZA de la Foucaudière, Rue de Bellinière, Trélazé',
      'tel': '0241681960',
      'horaires': 'Tous les jours : 11h–21h45',
      'note': '4.2',
      'emoji': '🍟',
      'color': Color(0xFFFFC107),
      'menuUrl': 'https://www.mcdonalds.fr/nos-produits',
      'tags': ['Sur place', 'À emporter', 'Uber Eats'],
    },
    {
      'nom': 'Pizza Tempo',
      'type': 'Pizzeria italienne',
      'adresse': '136 Rue Jean Jaurès, Trélazé',
      'tel': '',
      'horaires': '',
      'note': '4.7',
      'emoji': '🍕',
      'color': Color(0xFFE8401C),
      'menuUrl': '',
      'tags': ['Sur place', 'À emporter', 'Uber Eats'],
    },
    {
      'nom': 'Capital Tacos',
      'type': 'Tacos • Burgers • Restauration rapide',
      'adresse': 'Trélazé',
      'tel': '',
      'horaires': 'Lun–Sam : 11h30–14h30 / 18h–23h\nDim : 11h30–23h',
      'note': '4.3',
      'emoji': '🌯',
      'color': Color(0xFF1565C0),
      'menuUrl': '',
      'tags': ['Sur place', 'À emporter', 'Livraison'],
    },
    {
      'nom': 'Le Swigny',
      'type': 'Restaurant • Brasserie française',
      'adresse': 'Trélazé',
      'tel': '',
      'horaires': 'Mar–Ven : 11h30–14h30 / 19h–22h30\nSam–Dim : 11h30–14h30 / 19h–22h30\nFermé le lundi',
      'note': '4.4',
      'emoji': '🍽️',
      'color': Color(0xFF6D4C41),
      'menuUrl': '',
      'tags': ['Sur place', 'Réservation conseillée'],
    },
    {
      'nom': 'La Criée Trélazé',
      'type': 'Poissonnerie • Restauration rapide',
      'adresse': 'Trélazé',
      'tel': '',
      'horaires': '',
      'note': '4.1',
      'emoji': '🐟',
      'color': Color(0xFF0277BD),
      'menuUrl': '',
      'tags': ['Sur place', 'À emporter'],
    },
    {
      'nom': 'Le Picotin',
      'type': 'Café • Restauration • Bar',
      'adresse': 'Trélazé',
      'tel': '',
      'horaires': '',
      'note': '4.2',
      'emoji': '🍺',
      'color': Color(0xFF558B2F),
      'menuUrl': '',
      'tags': ['Sur place', 'Terrasse'],
    },
    {
      'nom': 'La Cafet du Village',
      'type': 'Smash Burger • Pâtisseries • Café',
      'adresse': '24 Rue des Perreyeux, Trélazé',
      'tel': '0241058450',
      'horaires': 'Lun–Mar : 11h30–minuit\nMer–Ven : 11h30–00h10\nSam–Dim : 18h–minuit',
      'note': '4.5',
      'emoji': '☕',
      'color': Color(0xFF795548),
      'menuUrl': 'https://www.lacafetduvillage.fr',
      'tags': ['Sur place', 'À emporter', 'Uber Eats'],
    },
  ];

  Widget _buildCard(Map r) {
    final nom = r['nom'] as String;
    final color = r['color'] as Color;
    final tags = r['tags'] as List;
    final isFavori = _favoris.contains(nom);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailRestaurantPage(restaurant: Map<String, dynamic>.from(r)))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Emoji
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(r['emoji'] as String, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  if ((r['note'] as String).isNotEmpty)
                    Row(children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(r['note'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  const SizedBox(width: 4),
                  Builder(builder: (ctx) {
                    final open = _isOpen(r);
                    if (open == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: (open ? Colors.green : Colors.red).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(open ? 'Ouvert' : 'Fermé',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: open ? Colors.green.shade700 : Colors.red.shade700)),
                    );
                  }),
                ]),
                const SizedBox(height: 3),
                Text(r['type'] as String, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on, size: 13, color: Colors.grey),
                  const SizedBox(width: 3),
                  Flexible(child: Text(r['adresse'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 6, children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(tag as String, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                )).toList()),
              ]),
            ),
            // Bouton favori
            GestureDetector(
              onTap: () => _toggleFavori(nom),
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  isFavori ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFavori ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoris = _restaurants.where((r) => _favoris.contains(r['nom'])).toList();
    final autres = _restaurants.where((r) => !_favoris.contains(r['nom'])).toList();

    return Scaffold(
      appBar: AppBar(title: Text(AppL10n.of(context).pageRestaurants)),
      body: ListView(
        children: [
          // Bandeau
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, Color(0xFF0A2729)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Où se restaurer à Trélazé ?",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
              const SizedBox(height: 6),
              Text("${_restaurants.length} établissements près de chez vous",
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Section favoris
              if (favoris.isNotEmpty) ...[
                const Row(children: [
                  Icon(Icons.favorite, size: 16, color: Colors.red),
                  SizedBox(width: 6),
                  Text("Mes favoris", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
                const SizedBox(height: 10),
                ...favoris.map(_buildCard),
                const Divider(height: 28),
                const Row(children: [
                  Text("Tous les restaurants", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
                const SizedBox(height: 10),
              ],
              ...autres.map(_buildCard),
            ]),
          ),
        ],
      ),
    );
  }
}

// ===== PAGE DÉTAIL =====
class DetailRestaurantPage extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  const DetailRestaurantPage({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final color = restaurant['color'] as Color;
    final tags = restaurant['tags'] as List;
    final tel = restaurant['tel'] as String;

    return Scaffold(
      appBar: AppBar(title: Text(restaurant['nom'] as String)),
      body: ListView(
        children: [
          // En-tête coloré
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    restaurant['emoji'] as String,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  restaurant['nom'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant['type'] as String,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags
                Wrap(
                  spacing: 8,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        tag as String,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Adresse
                _InfoRow(
                  icon: Icons.location_on,
                  label: "Adresse",
                  value: restaurant['adresse'] as String,
                  color: color,
                ),

                const Divider(height: 28),

                // Horaires
                _InfoRow(
                  icon: Icons.access_time,
                  label: "Horaires",
                  value: restaurant['horaires'] as String,
                  color: color,
                ),

                const Divider(height: 28),

                // Téléphone
                _InfoRow(
                  icon: Icons.phone,
                  label: "Téléphone",
                  value: _formatTel(tel),
                  color: color,
                ),

                const SizedBox(height: 28),

                // Bouton appeler
                if (tel.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:$tel')),
                    icon: const Icon(Icons.call),
                    label: const Text("Appeler", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                // Bouton voir le menu
                Builder(builder: (ctx) {
                  final menuUrl = restaurant['menuUrl'] as String? ?? '';
                  if (menuUrl.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(menuUrl)),
                        icon: Icon(Icons.menu_book, color: color),
                        label: Text("Voir le menu", style: TextStyle(fontSize: 16, color: color)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTel(String tel) {
    if (tel.length == 10) {
      return '${tel.substring(0, 2)} ${tel.substring(2, 4)} ${tel.substring(4, 6)} ${tel.substring(6, 8)} ${tel.substring(8, 10)}';
    }
    return tel;
  }
}


class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSub,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 15, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
