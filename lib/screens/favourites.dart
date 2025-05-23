import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:margarita/services/api_service.dart';

class FavouritesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favorites;

  const FavouritesScreen({Key? key, required this.favorites}) : super(key: key);

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  late List<Map<String, dynamic>> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = List.from(widget.favorites);
  }

  Future<void> _removeFromFavorites(int index) async {
    final item = _favorites[index];
    final itemName = item['name'] as String;
    if (!await ApiService.isLoggedIn()) {
      setState(() {
        _favorites.removeAt(index);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Eliminado de favoritos')));
      return;
    }

    try {
      final response = await ApiService.delete(
        '/api/favorites/remove/${item['id']}',
      );
      if (response['statusCode'] == 200) {
        setState(() {
          _favorites.clear();
          _favorites.addAll(
            List<Map<String, dynamic>>.from(response['body']['favorites']),
          );
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Eliminado de favoritos')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al eliminar de favoritos: ${response['statusCode']}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error removing from favorites: $e');
      setState(() {
        _favorites.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eliminado de favoritos localmente debido a error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Mis Favoritos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.of(context).pop(_favorites),
        ),
      ),
      body:
          _favorites.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 100, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No tienes favoritos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Añade productos a tus favoritos',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final item = _favorites[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFavoriteItem(item, index),
                  );
                },
              ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;
          Navigator.pop(context, _favorites);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Tienda'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Pedidos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menú'),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> item, int index) {
    const baseUrl = 'https://remoto.digital/';
    String imageUrl =
        item['imageUrl']?.toString() ?? item['image']?.toString() ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
      imageUrl =
          baseUrl +
          imageUrl.substring(1); // Remove leading slash for concatenation
    }
    print('Loading image for ${item['name']}: $imageUrl');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl:
                  imageUrl.isNotEmpty
                      ? imageUrl
                      : '$baseUrl/images/placeholder.jpg',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) {
                print('Image load error for ${item['name']}: $error');
                return const Icon(
                  Icons.fastfood,
                  size: 80,
                  color: Colors.orange,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'] as String,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  item['price'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () => _removeFromFavorites(index),
          ),
        ],
      ),
    );
  }
}
