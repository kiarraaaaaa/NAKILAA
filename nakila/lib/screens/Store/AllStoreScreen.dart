import 'package:nakila/screens/HomeScreen.dart';
import 'package:nakila/screens/Store/EditStoreScreen.dart';
import 'package:nakila/screens/Store/FavoriteStoreScreen.dart';
import 'package:nakila/screens/Store/StoreDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nakila/models/StoreModel.dart';
import 'package:nakila/widgets/StoreCard.dart';
import 'package:nakila/services/auth_service.dart';

import '../AdditionalFeaturesScreen/AboutAppScreen.dart' show AboutAppScreen;

class AllStoresScreen extends StatefulWidget {
  const AllStoresScreen({super.key});

  @override
  State<AllStoresScreen> createState() => _AllStoreScreenState();
}

class _AllStoreScreenState extends State<AllStoresScreen>
    with SingleTickerProviderStateMixin {
  List<StoreModel> _stores = [];
  Set<String> _favoriteStoreIds = {};
  String? _currentUserUid;
  late AnimationController _animationController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUserUid = AuthService.currentUserUid;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchStores();
    _fetchFavoriteStores();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isFlowerStore(StoreModel store) {
    final lower = '${store.name} ${store.description} ${store.address}'.toLowerCase();
    const flowerTerms = [
      'flower',
      'flowers',
      'florist',
      'bloom',
      'bouquet',
      'petal',
      'garden',
      'shop',
    ];
    return flowerTerms.any(lower.contains);
  }

  bool _hasCampusStore(List<StoreModel> stores) {
    final lower = stores
        .map((store) => '${store.name} ${store.description} ${store.address}'.toLowerCase())
        .join(' ');
    const campusTerms = ['oxford', 'harvard', 'stanford', 'university', 'kampus', 'campus'];
    return campusTerms.any(lower.contains);
  }

  Future<void> _fetchStores() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('stores').get();
    final fetchedStores = snapshot.docs
        .map((doc) => StoreModel.fromMap(doc.data(), doc.id))
        .toList();
    final useSample = fetchedStores.isEmpty ||
        (!_hasCampusStore(fetchedStores) && fetchedStores.every(_isFlowerStore));
    setState(() {
      _stores = useSample ? StoreModel.sampleStores() : fetchedStores;
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _fetchFavoriteStores() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserUid)
            .get();

    final List<dynamic> favoriteIds = userDoc.data()?['favoriteStoreIds'] ?? [];
    setState(() {
      _favoriteStoreIds = favoriteIds.cast<String>().toSet();
    });
  }

  Future<void> _toggleFavorite(String storeId) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserUid);
    final isFavorite = _favoriteStoreIds.contains(storeId);

    await userRef.update({
      'favoriteStoreIds':
          isFavorite
              ? FieldValue.arrayRemove([storeId])
              : FieldValue.arrayUnion([storeId]),
    });

    setState(() {
      if (isFavorite) {
        _favoriteStoreIds.remove(storeId);
      } else {
        _favoriteStoreIds.add(storeId);
      }
    });
  }

  Future<void> _deleteStore(String storeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kampus berhasil dihapus.")));
      _fetchStores();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menghapus kampus: $e")));
    }
  }

  void _showStoreSelectionDialog() {
    final adminStores =
        _stores.where((store) => store.owner == _currentUserUid).toList();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pilih Kampus untuk Diedit"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: adminStores.length,
              itemBuilder: (context, index) {
                final store = adminStores[index];
                return ListTile(
                  leading: const Icon(Icons.school),
                  title: Text(store.name),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditStoreScreen(store: store),
                      ),
                    );
                    _fetchStores();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.school_outlined, color: Colors.white),
        ),
        title: const Text(
          'Kampus Terbaik',
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
            child: Icon(Icons.school_outlined, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffE3F2FD), Color(0xffFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.indigo),
                    SizedBox(height: 16),
                    Text(
                      "Memuat data kampus...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Tunggu sebentar atau coba lagi nanti.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    itemCount: _stores.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          mainAxisExtent: 210,
                        ),
                    itemBuilder: (context, index) {
                      final store = _stores[index];
                      final isFavorite = _favoriteStoreIds.contains(store.id);
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.1 * index,
                            1.0,
                            curve: Curves.easeIn,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StoreDetailScreen(store: store),
                              ),
                            );
                          },
                          child: StoreCard(
                            store: store,
                            currentUserUid: _currentUserUid,
                            onDelete: () => _deleteStore(store.id),
                            isFavorite: isFavorite,
                            onToggleFavorite: () => _toggleFavorite(store.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) async {
          switch (index) {
            case 0:
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
              break;
            case 1:
              break;
            case 2:
              if (_currentUserUid != null) {
                final userDoc =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUserUid)
                        .get();
                final List<dynamic> favoriteIds =
                    userDoc.data()?['favoriteStoreIds'] ?? [];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FavoriteStoreScreen(
                          favoriteStoreIds: favoriteIds.cast<String>(),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "Kampus",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorit Kampus",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_mail),
            label: "Kontak",
          ),
        ],
      ),
    );
  }
}

