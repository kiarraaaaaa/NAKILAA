import 'dart:convert';
import 'package:nakila/screens/AdditionalFeaturesScreen/AboutAppScreen.dart';
import 'package:nakila/screens/AdditionalFeaturesScreen/ProfileDetailScreens.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nakila/screens/Store/FavoriteStoreScreen.dart';
import 'package:flutter/material.dart';
import 'package:nakila/models/ProductModel.dart';
import 'package:nakila/models/StoreModel.dart';
import 'package:nakila/screens/Store/AllStoreScreen.dart';
import 'package:nakila/screens/Store/StoreDetailScreen.dart';
import 'package:nakila/services/location_service.dart';
import 'package:nakila/services/auth_service.dart';
import 'package:nakila/widgets/StoreCard.dart';
import 'package:nakila/AddPostScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _address = "Memuat lokasi...";
  bool _isAdmin = false;
  bool _isProfileLoading = true;
  String? _currentUserUid;
  String _profileImageUrl = "";
  List<ProductModel> _products = [];
  List<StoreModel> _stores = [];
  final int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";
  List<String> favoriteStoreIds = [];
  bool _isStoreLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _checkAdminStatus();
    _loadCurrentUserUid();
    _fetchStores();
    _fetchAllProducts();
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
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
              builder: (context) => FavoriteStoreScreen(
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutAppScreen()),
        );
        break;
      default:
        break;
    }
  }

  void _loadCurrentUserUid() {
    final uid = AuthService.currentUserUid;
    setState(() {
      _currentUserUid = uid;
    });
    if (uid != null) {
      _loadProfileImage(uid);
      _loadFavoriteStores(uid);
    }
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
      debugPrint("Gagal memuat favorit kampus: $e");
    }
  }

  void _loadProfileImage(String uid) async {
    setState(() {
      _isProfileLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && data['photoBase64'] != null) {
        setState(() {
          _profileImageUrl = data['photoBase64'];
        });
      }
    } catch (e) {
      debugPrint("Error loading profile image: $e");
    } finally {
      setState(() {
        _isProfileLoading = false;
      });
    }
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
    setState(() {
      _isStoreLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('stores').get();
      final fetchedStores = snapshot.docs
          .map((doc) => StoreModel.fromMap(doc.data(), doc.id))
          .toList();
      final useSample = fetchedStores.isEmpty ||
          (!_hasCampusStore(fetchedStores) && fetchedStores.every(_isFlowerStore));
      setState(() {
        _stores = useSample ? StoreModel.sampleStores() : fetchedStores;
      });
    } catch (e) {
      debugPrint("Gagal memuat kampus: $e");
      setState(() {
        _stores = StoreModel.sampleStores();
      });
    } finally {
      setState(() {
        _isStoreLoading = false;
      });
    }
  }

  Future<void> _fetchAllProducts() async {
    final storeSnapshots = await FirebaseFirestore.instance.collection('stores').get();
    List<ProductModel> loadedProducts = [];

    for (var storeDoc in storeSnapshots.docs) {
      final productsSnapshot = await storeDoc.reference.collection('products').get();
      for (var productDoc in productsSnapshot.docs) {
        final data = productDoc.data();
        final product = ProductModel.fromMap(productDoc.id, data);
        loadedProducts.add(product);
      }
    }

    setState(() {
      _products = loadedProducts;
    });
  }

  Future<void> _loadLocation() async {
    try {
      String result = await LocationService.getCurrentAddress();
      setState(() {
        _address = result;
      });
    } catch (e) {
      setState(() {
        _address = "Gagal memuat lokasi";
      });
    }
  }

  static Future<void> toggleFavoriteCampus(String userId, String storeId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final snapshot = await userRef.get();
    final data = snapshot.data();

    final List favorites = data?['favoriteStores'] ?? [];

    if (favorites.contains(storeId)) {
      favorites.remove(storeId);
    } else {
      favorites.add(storeId);
    }

    await userRef.update({'favoriteStores': favorites});
  }

  Future<void> _checkAdminStatus() async {
    bool result = await AuthService.checkIfAdmin();
    setState(() {
      _isAdmin = result;
    });
  }

  void _addNewCampus() async {
    if (_isAdmin) {
      final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddPostScreen()));
      if (result == true) {
        _fetchStores();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hanya admin yang bisa menambahkan kampus!"),
        ),
      );
    }
  }

  Future<void> _deleteCampus(String storeId) async {
    try {
      await FirebaseFirestore.instance.collection('stores').doc(storeId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kampus berhasil dihapus.")));
      _fetchStores();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus kampus: $e")));
    }
  }

  ImageProvider<Object> _getProfileImageProvider(String imageData) {
    try {
      if (imageData.startsWith("data:image") || imageData.length > 100) {
        final base64Str = imageData.contains(',') ? imageData.split(',').last : imageData;
        return MemoryImage(base64Decode(base64Str));
      }
    } catch (e) {
      debugPrint("Gagal decode base64: $e");
    }
    return const AssetImage("assets/Additional/Profile.png");
  }

  @override
  Widget build(BuildContext context) {
    final filteredStores = _stores.where(
      (store) => store.name.toLowerCase().contains(_searchKeyword.toLowerCase()),
    ).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: _addNewCampus,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Kampus"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorit Kampus"),
          BottomNavigationBarItem(icon: Icon(Icons.contact_mail), label: "Kontak"),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 200,
                          child: Text(
                            _address,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileDetailScreen()),
                        );
                        if (result == true && _currentUserUid != null) {
                          _loadProfileImage(_currentUserUid!);
                        }
                      },
                      child: _isProfileLoading
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _getProfileImageProvider(_profileImageUrl),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Temukan Kampus Terbaik Dunia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Jelajahi universitas ternama seperti Oxford, Stanford, dan kampus internasional lainnya.',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchKeyword = value.toLowerCase();
                            });
                          },
                          decoration: const InputDecoration(
                            icon: Icon(Icons.search, color: Colors.blue),
                            border: InputBorder.none,
                            hintText: "Cari kampus terbaik...",
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Kampus Pilihan",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AllStoresScreen()),
                              );
                            },
                            child: const Text(
                              "Lihat Semua",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _isStoreLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _stores.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      "Belum ada kampus ditambahkan.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              : filteredStores.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                          "Kampus tidak ditemukan.",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.only(top: 8),
                                      itemCount: filteredStores.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        mainAxisExtent: 210,
                                      ),
                                      itemBuilder: (context, index) {
                                        final store = filteredStores[index];
                                        final isFavorite = favoriteStoreIds.contains(store.id);
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => StoreDetailScreen(store: store),
                                              ),
                                            );
                                          },
                                          child: StoreCard(
                                            store: store,
                                            currentUserUid: _currentUserUid,
                                            isFavorite: isFavorite,
                                            onToggleFavorite: () {
                                              setState(() {
                                                if (isFavorite) {
                                                  favoriteStoreIds.remove(store.id);
                                                } else {
                                                  favoriteStoreIds.add(store.id);
                                                }
                                              });
                                              if (_currentUserUid != null) {
                                                toggleFavoriteCampus(_currentUserUid!, store.id);
                                              }
                                            },
                                            onDelete: () => _deleteCampus(store.id),
                                          ),
                                        );
                                      },
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

