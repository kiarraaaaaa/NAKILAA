import 'package:flutter/material.dart';
import 'package:nakila/screens/Store/AllStoreScreen.dart';
import 'package:nakila/screens/Store/FavoriteStoreScreen.dart';
import 'package:nakila/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nakila/models/StoreModel.dart';
import 'package:nakila/screens/HomeScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  bool _isLoading = true;
  int _selectedIndex = 3;
  String? _currentUserUid;
  List<String> favoriteStoreIds = [];
  List<StoreModel> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserUidAndData();
  }

  String _formatPhoneDisplay(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('+62')) {
      clean = '0${clean.substring(3)}';
    } else if (clean.startsWith('62')) {
      clean = '0${clean.substring(2)}';
    }

    List<String> parts = [];
    for (int i = 0; i < clean.length; i += 4) {
      int end = (i + 4 < clean.length) ? i + 4 : clean.length;
      parts.add(clean.substring(i, end));
    }

    return parts.join('-');
  }

  Future<void> _loadCurrentUserUidAndData() async {
    final uid = AuthService.currentUserUid;
    if (uid != null) {
      setState(() {
        _currentUserUid = uid;
      });
      await Future.wait([_loadFavoriteStores(uid), _fetchStores()]);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadFavoriteStores(String uid) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (data != null && data.containsKey('favoriteStores')) {
        setState(() {
          favoriteStoreIds = List<String>.from(data['favoriteStores']);
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat toko favorit: $e");
    }
  }

  Future<void> _fetchStores() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('stores').get();
    setState(() {
      _stores =
          snapshot.docs
              .map((doc) => StoreModel.fromMap(doc.data(), doc.id))
              .toList();
    });
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllStoresScreen()),
        );
        break;
      case 2:
        if (_currentUserUid != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FavoriteStoreScreen(
                    favoriteStoreIds: favoriteStoreIds,
                    allStores: _stores,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data pengguna belum dimuat.")),
          );
        }
        break;
      case 3:
        break;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget buildContactCard({
    required String name,
    required String phone,
    required String instagram,
    required String facebook,
    required String email,
    required String address,
    required String imagePath,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap:
                            () => _launchURL(
                              'https://wa.me/${phone.replaceAll('+', '').replaceAll(' ', '')}',
                            ),
                        child: Text(
                          "📞 WhatsApp: ${_formatPhoneDisplay(phone)}",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),
                      _buildContactLink(
                        label: "📷 Instagram: @$instagram",
                        url: 'https://instagram.com/$instagram',
                      ),
                      _buildContactLink(
                        label: "📘 Facebook: $facebook",
                        url: 'https://facebook.com/$facebook',
                      ),
                      _buildContactLink(
                        label: "✉️ Email: $email",
                        url: 'mailto:$email',
                      ),
                      _buildContactLink(
                        label: "📍 $address",
                        url:
                            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(imagePath),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: () => _launchURL(url),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.grey[800]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: Colors.blue),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactLink({required String label, required String url}) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: const TextStyle(color: Colors.blue, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.contact_page_outlined, color: Colors.white),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2.0, 2.0),
                blurRadius: 3.0,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.contact_support_rounded, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_sharp),
            label: "Store",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite Store",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_mail),
            label: "Kontak",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(height: 5),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text(
                                '- NAKILA -',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Aplikasi ini dibuat untuk membantu Anda menemukan berbagai kampus terbaik di sekitar Anda. Dengan antarmuka yang sederhana dan fitur-fitur yang lengkap, Anda bisa mencari, menambahkan favorit, dan mengeksplor berbagai kampus terbaik dengan mudah.',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Jika ada yang ingin ditanyakan bisa hubungi kontak person dibawah ini !',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              const Center(
                                child: Text(
                                  'Kontak Person',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              buildContactCard(
                                name: "Person 1 - Benecia Kiarra",
                                phone: "+62 81299137573",
                                instagram: "bnc.kra_",
                                facebook: "bnc.kra_",
                                email: "kiarra1409@gmail.com",
                                address: "Jl Bukit kecil no 1520",
                                imagePath: "assets/User/kiarra.jpg",
                              ),
                              buildContactCard(
                                name: "Person 2 - Nabila Salwa Zahrani",
                                phone: "+62 822-9820-3736",
                                instagram: "nabilaaasz__",
                                facebook: "nabila.salwazahrani",
                                email: "nabilasalwazahrani_2226240133@mhs.mdp.ac.id",
                                address: "Jl. Gersik, Kota Palembang",
                                imagePath: "assets/User/nabila.jpeg",
                              ),
                              buildContactCard(
                                name: "Person 3 - Sandy Bela H",
                                phone: "+62 85267226767",
                                instagram: "bellahrms_ ",
                                facebook: "bellahrms_ ",
                                email:
                                    "sandybelahartati_2226240153@mhs.mdp.ac.id",
                                address: "Pusri Sako",
                                imagePath: "assets/User/bella.jpeg",
                              ),

                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Dikembangkan oleh Tim NAKILA.\n© 2025 Nakila Inc.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

