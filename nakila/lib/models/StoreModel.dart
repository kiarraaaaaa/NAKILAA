import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String address;
  final String description;
  final String phone;
  final String email;
  final String imageBase64;
  final String imageUrl;
  final String owner;
  final double? rating;
  final List<String> achievements;
  final String biodata;

  StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.phone,
    required this.email,
    required this.imageBase64,
    required this.imageUrl,
    required this.owner,
    required this.rating,
    required this.achievements,
    required this.biodata,
  });

  factory StoreModel.fromMap(Map<String, dynamic> data, String docId) {
    return StoreModel(
      id: docId,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      owner: data['owner'] ?? '',
      rating:
          (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      achievements: List<String>.from(data['achievements'] ?? []),
      biodata: data['biodata'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'description': description,
      'phone': phone,
      'email': email,
      'imageBase64': imageBase64,
      'imageUrl': imageUrl,
      'owner': owner,
      'rating': rating ?? 0.0,
      'achievements': achievements,
      'biodata': biodata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static List<StoreModel> sampleStores() {
    return [
      StoreModel(
        id: 'sample-oxford',
        name: 'Oxford University',
        address: 'Oxford, United Kingdom',
        description: 'Universitas tertua di dunia berbahasa Inggris dengan reputasi akademik luar biasa.',
        phone: '+44 1865 270000',
        email: 'info@ox.ac.uk',
        imageBase64: '',
        imageUrl: 'assets/Additional/Oxford.jpg',
        owner: '',
        rating: 4.9,
        achievements: [
          '30 pemenang Nobel Prize',
          '27 Perdana Menteri Inggris',
          'Didirikan sejak 1096 sebagai universitas riset top dunia',
        ],
        biodata: 'Oxford University adalah universitas riset terkemuka di dunia, terletak di Oxford, Inggris. Dikenal dengan tradisi akademiknya yang kaya dan kontribusi besar dalam bidang sains, humaniora, dan seni.',
      ),
      StoreModel(
        id: 'sample-stanford',
        name: 'Stanford University',
        address: 'Stanford, California, USA',
        description: 'Pusat inovasi teknologi dan penelitian terdepan di dunia.',
        phone: '+1 650-723-2300',
        email: 'admissions@stanford.edu',
        imageBase64: '',
        imageUrl: 'assets/Additional/Stanford.jpg',
        owner: '',
        rating: 4.8,
        achievements: [
          'Pendiri Google dan Yahoo berasal dari kampus ini',
          '30 pemenang Nobel Prize',
          'Pusat inovasi teknologi di Silicon Valley',
        ],
        biodata: 'Stanford University adalah universitas riset swasta di Stanford, California. Didukung pada 1885 oleh Leland Stanford, universitas ini telah menghasilkan banyak inovator terkemuka dan kontribusi besar dalam teknologi dan sains.',
      ),
      StoreModel(
        id: 'sample-harvard',
        name: 'Harvard University',
        address: 'Cambridge, Massachusetts, USA',
        description: 'Universitas Ivy League tertua dengan sejarah panjang dalam pendidikan tinggi.',
        phone: '+1 617-495-1000',
        email: 'contact@harvard.edu',
        imageBase64: '',
        imageUrl: 'assets/Additional/Harvard.jpg',
        owner: '',
        rating: 4.9,
        achievements: [
          '8 Presiden Amerika Serikat berasal dari universitas ini',
          '160 pemenang Nobel Prize',
          'Universitas swasta tertua di AS sejak 1636',
        ],
        biodata: 'Harvard University adalah universitas riset swasta di Cambridge, Massachusetts. Didukung pada 1636, Harvard adalah universitas tertua di Amerika Serikat dan dikenal dengan program akademiknya yang komprehensif serta alumni yang berpengaruh di berbagai bidang.',
      ),
    ];
  }
}
