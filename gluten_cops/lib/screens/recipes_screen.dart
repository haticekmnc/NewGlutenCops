import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gluten_cops/form_screens/addrecipe_screen.dart';
import 'package:gluten_cops/screens/recipedetail_screen.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({Key? key}) : super(key: key);

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Text(
            'Yemek Tarifleri',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: "Arama",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String userPreference = await getUserPreference(context);
                if (userPreference.isNotEmpty) {
                  var recommendedRecipe =
                      await getRecommendedRecipe(userPreference);
                  if (recommendedRecipe != null) {
                    // Önerilen tarifi göster
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(recommendedRecipe['recipeName']),
                          content: Image.network(recommendedRecipe['imageUrl']),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Kapat'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              },
              child: const Text('Bana Tarif Öner'),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('recipes').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Bir hata oluştu');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var document = snapshot.data!.docs[index];
                    var data = document.data() as Map<String, dynamic>;
                    return RecipeCard(
                        data: data,
                        onRate: (rating) => rateRecipe(document.id, rating));
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddRecipe()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<Map<String, dynamic>?> getRecommendedRecipe(
      String userPreference) async {
    var recipesCollection = _firestore.collection('recipes');
    var querySnapshot = await recipesCollection
        .where('tags', arrayContains: userPreference)
        .get();
    var documents = querySnapshot.docs;
    if (documents.isNotEmpty) {
      return documents.first.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<String> getUserPreference(BuildContext context) async {
    String selectedPreference = '';
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? tempSelectedPreference;
        return AlertDialog(
          title: const Text('Tercihlerinizi Seçin'),
          content: DropdownButton<String>(
            items: const <String>[
              'Tavuksuz',
              'Vejetaryen',
              'Vegan',
              'Glutensiz'
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              tempSelectedPreference = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                selectedPreference = tempSelectedPreference ?? '';
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return selectedPreference;
  }

  void rateRecipe(String recipeId, double rating) {
    var user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('recipes')
          .doc(recipeId)
          .collection('ratings')
          .doc(user.uid)
          .set({
        'rating': rating,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}

class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(double) onRate;

  const RecipeCard({Key? key, required this.data, required this.onRate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2.0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(
                recipeName: data['recipeName'],
                recipeDescription: data['recipeDescription'],
                recipeImage: data['imageUrl'],
              ),
            ),
          );
        },
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4.0),
                    bottomLeft: Radius.circular(4.0)),
                child: Image.network(
                  data['imageUrl'] ?? '',
                  height: 120.0,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data['recipeName'] ?? 'Unnamed Recipe',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    RatingBar.builder(
                      initialRating: data['rating'] ?? 0.0,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        onRate(rating);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
