import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gluten_cops/form_screens/addproduct_screen.dart';
import 'package:gluten_cops/screens/favorite_screen.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int selectedButton = 0;
  final Stream<QuerySnapshot> _allProductsStream =
      FirebaseFirestore.instance.collection('products').snapshots();
  TextEditingController _searchController = TextEditingController();
  Set<String> favoriteProductIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 50.0, left: 10.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text("Ürünler",
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Ara'),
            ),
            const SizedBox(height: 20.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton('Tümü', 0, Colors.pink),
                  SizedBox(width: 10),
                  _buildButton('Glutenli', 1, Colors.red),
                  SizedBox(width: 10),
                  _buildButton('Glutensiz', 2, Colors.green),
                  SizedBox(width: 10),
                  _buildButton(
                      'Favoriler',
                      3,
                      Colors.blue,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  FavoritesScreen(favoriteProductIds)))),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _allProductsStream,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError)
                    return Text('Bir şeyler yanlış gitti: ${snapshot.error}');
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const CircularProgressIndicator();
                  List<DocumentSnapshot> products = snapshot.data!.docs;
                  List<DocumentSnapshot> filteredProducts =
                      _filterProducts(products);
                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) =>
                        _buildProductListTile(filteredProducts[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AddProduct())),
        child: const Icon(Icons.add),
        backgroundColor: Colors.pink,
      ),
    );
  }

  List<DocumentSnapshot> _filterProducts(List<DocumentSnapshot> products) {
    String filter = '';
    if (selectedButton == 1)
      filter = 'Glutenli';
    else if (selectedButton == 2) filter = 'Glutensiz';
    return products.where((product) {
      final productName = product['productName']?.toLowerCase() ?? '';
      final productStatus = product['glutenStatus']?.toLowerCase() ?? '';
      final searchText = _searchController.text.toLowerCase();
      if (_searchController.text.isNotEmpty &&
          !productName.contains(searchText)) return false;
      if (selectedButton != 0 && !productStatus.contains(filter.toLowerCase()))
        return false;
      return true;
    }).toList();
  }

  Widget _buildProductListTile(DocumentSnapshot product) {
    Map<String, dynamic> productData = product.data() as Map<String, dynamic>;
    String productId = product.id;
    bool isFavorite = favoriteProductIds.contains(productId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 5.0,
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: productData['imageUrl'] ?? '',
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  height: 150, // Yükseklik artırıldı
                  fit: BoxFit
                      .fill, // Resmin tamamını dolduracak şekilde ayarlandı
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(productData['productName'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(productData['glutenStatus'] ?? ''),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isFavorite)
                            favoriteProductIds.remove(productId);
                          else
                            favoriteProductIds.add(productId);
                        });
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

  void _showProductDetailPopup(
      BuildContext context, Map<String, dynamic> productData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(productData['productName']),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Ürün Açıklaması: ${productData['description']}'),
                Text('Fiyat: ${productData['price']}'),
                // Diğer ürün detayları buraya eklenebilir
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton(String name, int index, Color color,
      [VoidCallback? onPressed]) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          primary: selectedButton == index ? color : Colors.grey,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0))),
      onPressed: onPressed ?? () => setState(() => selectedButton = index),
      child: Text(name, style: const TextStyle(color: Colors.white)),
    );
  }
}
