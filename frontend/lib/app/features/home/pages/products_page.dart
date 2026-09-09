import 'package:flutter/material.dart';

import '../widgets/product_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final Set<int> favorites = {};

  String selectedCategory = 'Todos';

  final List<ProductData> products = const [
    ProductData(
      id: 1,
      artisan: 'Maria das Graças',
      price: 'R\$ 85',
      priceUsd: 'USD 16',
      category: 'Acessórios',
      image:
          'https://images.unsplash.com/photo-1562869929-bda0650edb1f?w=400&h=400&fit=crop&auto=format',
      name: 'Cesta Trançada Sol',
    ),
    ProductData(
      id: 2,
      artisan: 'Rosângela Silva',
      price: 'R\$ 120',
      priceUsd: 'USD 23',
      category: 'Joias',
      image:
          'https://images.unsplash.com/photo-1581475319737-4ae69b8926c7?w=400&h=400&fit=crop&auto=format',
      name: 'Colar Raízes',
    ),
    ProductData(
      id: 3,
      artisan: 'Aparecida Oliveira',
      price: 'R\$ 210',
      priceUsd: 'USD 40',
      category: 'Casa',
      image:
          'https://images.unsplash.com/photo-1552710307-537199cd41c0?w=400&h=400&fit=crop&auto=format',
      name: 'Peça artesanal para casa',
    ),
    ProductData(
      id: 4,
      artisan: 'Fatima Conceição',
      price: 'R\$ 95',
      priceUsd: 'USD 18',
      category: 'Brinquedos',
      image:
          'https://images.unsplash.com/photo-1722957533029-6b62a3826d05?w=400&h=400&fit=crop&auto=format',
      name: 'Boneca Abayomi',
    ),
    ProductData(
      id: 5,
      artisan: 'Nilza Santos',
      price: 'R\$ 160',
      priceUsd: 'USD 30',
      category: 'Casa',
      image:
          'https://images.unsplash.com/photo-1781617783311-243520abc3fc?w=400&h=400&fit=crop&auto=format',
      name: 'Decoração em barro',
    ),
    ProductData(
      id: 6,
      artisan: 'Benedita Lima',
      price: 'R\$ 290',
      priceUsd: 'USD 55',
      category: 'Vestuário',
      image:
          'https://images.unsplash.com/photo-1508589452764-4e017240add7?w=400&h=400&fit=crop&auto=format',
      name: 'Peça bordada',
    ),
  ];

  final categories = const [
    'Todos',
    'Acessórios',
    'Joias',
    'Casa',
    'Vestuário',
    'Brinquedos',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final filteredProducts = selectedCategory == 'Todos'
        ? products
        : products
            .where((product) => product.category == selectedCategory)
            .toList();

    int columns;

    if (width >= 1100) {
      columns = 3;
    } else if (width >= 700) {
      columns = 2;
    } else {
      columns = 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080D12),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _intro(),
            ),

            SliverToBoxAdapter(
              child: _categoryFilters(),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 96),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = filteredProducts[index];

                    return ProductCard(
                      image: product.image,
                      category: product.category,
                      name: product.name,
                      artisan: product.artisan,
                      price: product.price,
                      isFavorite: favorites.contains(product.id),
                      onFavorite: () {
                        setState(() {
                          if (favorites.contains(product.id)) {
                            favorites.remove(product.id);
                          } else {
                            favorites.add(product.id);
                          }
                        });
                      },
                      onBuy: () {
                        _showAddedMessage(product);
                      },
                    );
                  },
                  childCount: filteredProducts.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 22,
                  mainAxisSpacing: 22,
                  mainAxisExtent: 430,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 82, 24, 35),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CATÁLOGO',
                style: TextStyle(
                  color: Color(0xFF00B8B0),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.7,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Peças que carregam histórias.',
                style: TextStyle(
                  color: Color(0xFFE2F0EF),
                  fontSize: 48,
                  height: 1.04,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 720,
                child: Text(
                  'Conheça produtos feitos à mão por artesãs de Heliópolis e apoie histórias de autonomia, cultura e geração de renda.',
                  style: TextStyle(
                    color: Color(0xFF7AACAA),
                    fontSize: 16,
                    height: 1.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final selected = category == selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      selectedColor: const Color(0xFF00B8B0),
                      backgroundColor: const Color(0xFF0F1820),
                      side: const BorderSide(
                        color: Color(0xFF1A2E3A),
                      ),
                      labelStyle: TextStyle(
                        color: selected
                            ? const Color(0xFF080D12)
                            : const Color(0xFFE2F0EF),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddedMessage(ProductData product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} foi adicionado ao carrinho.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00B8B0),
      ),
    );
  }
}

class ProductData {
  const ProductData({
    required this.id,
    required this.artisan,
    required this.price,
    required this.priceUsd,
    required this.category,
    required this.image,
    required this.name,
  });

  final int id;
  final String artisan;
  final String price;
  final String priceUsd;
  final String category;
  final String image;
  final String name;
}