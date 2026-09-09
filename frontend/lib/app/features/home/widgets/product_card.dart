import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.image,
    required this.category,
    required this.name,
    required this.artisan,
    required this.price,
    required this.isFavorite,
    required this.onFavorite,
    required this.onBuy,
  });

  final String image;
  final String category;
  final String name;
  final String artisan;
  final String price;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onBuy;

  static const Color background = Color(0xFF080D12);
  static const Color card = Color(0xFF0F1820);
  static const Color foreground = Color(0xFFE2F0EF);
  static const Color muted = Color(0xFF7AACAA);
  static const Color primary = Color(0xFF00B8B0);
  static const Color accent = Color(0xFFE8622A);
  static const Color border = Color(0xFF1A2E3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.25,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xFF17252D),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: muted,
                        size: 42,
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: card,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onFavorite,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFavorite ? accent : muted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  name,
                  style: const TextStyle(
                    color: foreground,
                    fontFamily: 'Fraunces',
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'por $artisan',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12.5,
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        price,
                        style: const TextStyle(
                          color: primary,
                          fontFamily: 'Fraunces',
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    FilledButton(
                      onPressed: onBuy,
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: card,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Comprar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}