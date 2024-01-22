import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _getUserFullName() async {
    String fullName = '';
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      fullName = userDoc['fullName'];
    }

    return fullName;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserFullName(),
      builder: (context, snapshot) {
        String welcomeText = 'Hoşgeldin, ';

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            welcomeText += snapshot.data!;
          } else {
            welcomeText += 'Kullanıcı';
          }
        } else {
          welcomeText += 'Kullanıcı';
        }

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(33.0),
                  child: Text(
                    welcomeText,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Arama",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      ),
                    ),
                  ),
                ),
                _buildCategory(
                    'Popüler Ürünler',
                    FirebaseFirestore.instance
                        .collection('products')
                        .snapshots()),
                _buildCategory(
                    'Popüler Yemekler',
                    FirebaseFirestore.instance
                        .collection('recipes')
                        .snapshots()), // 'recipes' koleksiyonunu varsayıyorum
                _buildCategory(
                    'Popüler Mekanlar',
                    FirebaseFirestore.instance
                        .collection('locations')
                        .snapshots()), // 'locations' koleksiyonunu varsayıyorum
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategory(String title, Stream<QuerySnapshot> stream) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Bir hata oluştu');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              return SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var document = snapshot.data!.docs[index];
                    return _buildListItem(document);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(DocumentSnapshot document) {
    var data = document.data() as Map<String, dynamic>;
    return Container(
      width: 160.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: CachedNetworkImage(
              imageUrl: data['imageUrl'] ?? '',
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 140,
            ),
          ),
          Text(
            data['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            data['description'] ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
