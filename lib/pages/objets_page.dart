import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../l10n.dart';

class ObjetsPage extends StatefulWidget {
  const ObjetsPage({super.key});

  @override
  State<ObjetsPage> createState() => _ObjetsPageState();
}

class _ObjetsPageState extends State<ObjetsPage> {
  // 'tous' | 'perdu' | 'trouve'
  String _filtre = 'tous';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppL10n.of(context).pageObjects)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SignalerObjetPage())),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Signaler", style: TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        // ── Filtres ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            _FilterChip(
              label: 'Tous',
              icon: Icons.list,
              selected: _filtre == 'tous',
              color: AppTheme.primary,
              onTap: () => setState(() => _filtre = 'tous'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Perdus',
              icon: Icons.help_outline,
              selected: _filtre == 'perdu',
              color: Colors.red,
              onTap: () => setState(() => _filtre = 'perdu'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Trouvés',
              icon: Icons.check_circle_outline,
              selected: _filtre == 'trouve',
              color: Colors.green,
              onTap: () => setState(() => _filtre = 'trouve'),
            ),
          ]),
        ),
        // ── Liste ────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('objets')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data?.docs ?? [];
              final docs = _filtre == 'tous'
                  ? allDocs
                  : allDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['type'] ?? '') == _filtre;
                    }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _filtre == 'perdu'
                            ? "Aucun objet perdu signalé"
                            : _filtre == 'trouve'
                                ? "Aucun objet trouvé signalé"
                                : "Aucun objet signalé",
                        style: const TextStyle(
                            fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Appuyez sur + pour signaler un objet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data =
                      docs[index].data() as Map<String, dynamic>;
                  final type = data['type'] ?? 'perdu';
                  final description = data['description'] ?? '';
                  final lieu = data['lieu'] ?? '';
                  final photoUrl = data['photoUrl'] as String?;
                  final date = (data['date'] as Timestamp?)?.toDate();
                  final dateStr = date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : '';
                  final isPerdu = type == 'perdu';
                  final typeColor =
                      isPerdu ? Colors.red : Colors.green;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailObjetPage(
                              data: data, photoUrl: photoUrl),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (photoUrl != null)
                            SizedBox(
                              height: 160,
                              width: double.infinity,
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    Container(
                                  height: 160,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(
                                        alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isPerdu
                                        ? Icons.help_outline
                                        : Icons.check_circle_outline,
                                    color: typeColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                        decoration: BoxDecoration(
                                          color: typeColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isPerdu ? 'Perdu' : 'Trouvé',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      if (lieu.isNotEmpty)
                                        Text("📍 $lieu",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      if (dateStr.isNotEmpty)
                                        Text("📅 $dateStr",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 15, color: selected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              )),
        ]),
      ),
    );
  }
}

// ===== PAGE DÉTAIL =====
class DetailObjetPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? photoUrl;
  const DetailObjetPage({super.key, required this.data, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? 'perdu';
    final description = data['description'] ?? '';
    final lieu = data['lieu'] ?? '';
    final contact = data['contact'] ?? '';
    final date = (data['date'] as Timestamp?)?.toDate();
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(type == 'perdu' ? 'Objet perdu' : 'Objet trouvé'),
      ),
      body: ListView(
        children: [
          if (photoUrl != null)
            SizedBox(
              height: 260,
              width: double.infinity,
              child: Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 260,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image,
                      size: 64, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: type == 'perdu' ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type == 'perdu' ? '❓ Objet perdu' : '✅ Objet trouvé',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Description",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textSub)),
                const SizedBox(height: 6),
                Text(description,
                    style: const TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(height: 20),
                if (lieu.isNotEmpty) ...[
                  const Text("Lieu",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textSub)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(lieu, style: const TextStyle(fontSize: 15)),
                  ]),
                  const SizedBox(height: 20),
                ],
                if (dateStr.isNotEmpty) ...[
                  const Text("Date",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textSub)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.calendar_today,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(dateStr, style: const TextStyle(fontSize: 15)),
                  ]),
                  const SizedBox(height: 20),
                ],
                if (contact.isNotEmpty) ...[
                  const Text("Contact",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textSub)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.phone,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(contact, style: const TextStyle(fontSize: 15)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== PAGE SIGNALEMENT =====
class SignalerObjetPage extends StatefulWidget {
  const SignalerObjetPage({super.key});

  @override
  State<SignalerObjetPage> createState() => _SignalerObjetPageState();
}

class _SignalerObjetPageState extends State<SignalerObjetPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  String _type = 'perdu';
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  bool _loading = false;
  File? _photo;

  final List<String> _lieux = [
    'Mairie',
    'Arrêt Bus Ligne 1',
    'Arrêt Bus Ligne 5',
    'Arrêt Bus Ligne 8',
    'Salle omnisports',
    'Parc de la Mairie',
    'Arena Loire',
    'Médiathèque',
    'Autre',
  ];
  String _lieuSelectionne = 'Mairie';

  Future<void> _choisirPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
              title: const Text("Prendre une photo"),
              onTap: () {
                Navigator.pop(context);
                _choisirPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.primary),
              title: const Text("Choisir dans la galerie"),
              onTap: () {
                Navigator.pop(context);
                _choisirPhoto(ImageSource.gallery);
              },
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Supprimer la photo",
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photo = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadPhoto() async {
    if (_photo == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('objets')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(_photo!);
    return await ref.getDownloadURL();
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final photoUrl = await _uploadPhoto();
      await FirebaseFirestore.instance.collection('objets').add({
        'type': _type,
        'description': _descController.text.trim(),
        'lieu': _lieuSelectionne,
        'contact': _contactController.text.trim(),
        'date': Timestamp.now(),
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Objet signalé avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur — réessayez"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppL10n.of(context).pageObjects)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type
            const Text("Type",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'perdu'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _type == 'perdu'
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        border: Border.all(
                          color:
                              _type == 'perdu' ? Colors.red : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        Icon(Icons.help_outline,
                            color: _type == 'perdu'
                                ? Colors.red
                                : Colors.grey,
                            size: 32),
                        const SizedBox(height: 8),
                        Text("J'ai perdu",
                            style: TextStyle(
                                color: _type == 'perdu'
                                    ? Colors.red
                                    : Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'trouve'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _type == 'trouve'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        border: Border.all(
                          color: _type == 'trouve'
                              ? Colors.green
                              : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        Icon(Icons.check_circle_outline,
                            color: _type == 'trouve'
                                ? Colors.green
                                : Colors.grey,
                            size: 32),
                        const SizedBox(height: 8),
                        Text("J'ai trouvé",
                            style: TextStyle(
                                color: _type == 'trouve'
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Photo
            const Text("Photo (optionnelle)",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                height: _photo != null ? 200 : 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey.shade300, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photo != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_photo!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _showPhotoOptions,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 36,
                              color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text("Ajouter une photo",
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Description
            const Text("Description",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Ex: Sac à dos noir avec des livres...",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? "Décrivez l'objet" : null,
            ),

            const SizedBox(height: 20),

            // Lieu
            const Text("Lieu",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _lieuSelectionne,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on),
              ),
              items: _lieux
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => _lieuSelectionne = v!),
            ),

            const SizedBox(height: 20),

            // Contact
            const Text("Contact (optionnel)",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contactController,
              decoration: InputDecoration(
                hintText: "Téléphone ou email",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _loading ? null : _soumettre,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Soumettre",
                      style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
