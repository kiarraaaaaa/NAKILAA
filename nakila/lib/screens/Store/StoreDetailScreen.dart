import 'package:nakila/screens/Store/EditStoreScreen.dart';
import 'package:nakila/widgets/ReviewSection.dart';
import 'package:nakila/widgets/StoreBiodata.dart';
import 'package:nakila/widgets/StoreHeader.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nakila/models/StoreModel.dart';

class StoreDetailScreen extends StatefulWidget {
  final StoreModel store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  late StoreModel _store;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUpdatedStore() async {
    if (_store.id.startsWith('sample-')) {
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(_store.id)
        .get();

    if (doc.exists && doc.data() != null && mounted) {
      setState(() {
        _store = StoreModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == _store.owner;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detail Kampus',
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: isOwner
                ? IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditStoreScreen(store: _store),
                        ),
                      );

                      if (result == true) {
                        await fetchUpdatedStore();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data kampus diperbarui'),
                            ),
                          );
                        }
                      }
                    },
                  )
                : const Icon(Icons.school, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          StoreHeader(store: _store),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari prestasi kampus...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[200],
                    child: const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(text: 'Prestasi'),
                        Tab(text: 'Ulasan'),
                        Tab(text: 'Info Kampus'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Builder(
                          builder: (context) {
                            final filteredAchievements = _store.achievements
                                .where((achievement) => achievement
                                    .toLowerCase()
                                    .contains(_searchController.text.toLowerCase()))
                                .toList();
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: filteredAchievements.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Tidak ada prestasi yang cocok.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: filteredAchievements.length,
                                      separatorBuilder: (context, index) => const Divider(),
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          leading: const Icon(Icons.star, color: Colors.blue),
                                          title: Text(filteredAchievements[index]),
                                        );
                                      },
                                    ),
                            );
                          },
                        ),
                        ReviewSection(storeId: _store.id),
                        StoreBiodata(storeId: _store.id, store: _store),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}

