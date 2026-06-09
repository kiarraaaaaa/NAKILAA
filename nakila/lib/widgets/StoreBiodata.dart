import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:nakila/models/StoreModel.dart';

class StoreBiodata extends StatelessWidget {
  final String storeId;
  final StoreModel? store;

  const StoreBiodata({super.key, required this.storeId, this.store});

  Future<Map<String, dynamic>> _fetchStoreAndOwner() async {
    final currentStore = store;
    if (currentStore != null && currentStore.id.startsWith('sample-')) {
      return {
        'name': currentStore.name,
        'description': currentStore.description,
        'address': currentStore.address,
        'email': currentStore.email,
        'phone': currentStore.phone,
        'ownerName': '-',
        'biodata': currentStore.biodata,
      };
    }

    final storeDoc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .get();

    if (!storeDoc.exists || storeDoc.data() == null) {
      if (currentStore != null) {
        return {
          'name': currentStore.name,
          'description': currentStore.description,
          'address': currentStore.address,
          'email': currentStore.email,
          'phone': currentStore.phone,
          'ownerName': '-',
          'biodata': currentStore.biodata,
        };
      }
      return {
        'name': '-',
        'description': '-',
        'address': '-',
        'email': '-',
        'phone': '-',
        'ownerName': '-',
        'biodata': '-',
      };
    }

    final storeData = storeDoc.data() as Map<String, dynamic>;
    final ownerId = (storeData['owner'] ?? '').toString();
    String ownerName = '-';

    if (ownerId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();
      ownerName = userDoc.exists && userDoc.data() != null
          ? (userDoc.data()!['name'] ?? '-')
          : '-';
    }

    return {
      'name': storeData['name'] ?? store?.name ?? '-',
      'description': storeData['description'] ?? store?.description ?? '-',
      'address': storeData['address'] ?? store?.address ?? '-',
      'email': storeData['email'] ?? store?.email ?? '-',
      'phone': storeData['phone'] ?? store?.phone ?? '-',
      'ownerName': ownerName,
      'biodata': storeData['biodata'] ?? store?.biodata ?? '-',
    };
  }

  void _launchEmail(BuildContext context, String email) async {
    if (email.trim().isEmpty || email == '-') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email tidak tersedia")));
      return;
    }

    final url = 'mailto:$email';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka aplikasi email")),
      );
    }
  }

  void _launchMapFromAddress(BuildContext context, String address) async {
    if (address.trim().isEmpty || address == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alamat tidak tersedia")),
      );
      return;
    }

    final encodedAddress = Uri.encodeComponent(address);
    final url =
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka Google Maps")),
      );
    }
  }

  void _launchSMS(BuildContext context, String phoneNumber) async {
    if (phoneNumber.trim().isEmpty || phoneNumber == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nomor HP tidak tersedia")),
      );
      return;
    }

    final url = 'sms:$phoneNumber';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka aplikasi pesan")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStoreAndOwner(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat biodata kampus.'));
        }

        final data = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 4),
              _buildInfoTile("Nama Kampus", data['name'], Icons.school),
              _buildInfoTile(
                "Deskripsi Kampus",
                data['description'],
                Icons.description,
              ),
              _buildInfoTile(
                "Biodata Kampus",
                data['biodata'],
                Icons.info,
              ),
              _buildInfoTile(
                "Alamat",
                data['address'],
                Icons.location_on,
                onTap: () => _launchMapFromAddress(context, data['address']),
              ),
              _buildInfoTile(
                "Email",
                data['email'],
                Icons.email,
                onTap: () => _launchEmail(context, data['email']),
              ),
              _buildInfoTile("Kontak Pengelola", data['ownerName'], Icons.person),
              _buildInfoTile(
                "No HP",
                data['phone'],
                Icons.phone,
                onTap: () => _launchSMS(context, data['phone']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(
    String title,
    dynamic value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          value != null && value.toString().isNotEmpty ? value.toString() : '-',
          style: TextStyle(
            color: onTap != null ? Colors.blue : null,
            decoration: onTap != null ? TextDecoration.underline : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

