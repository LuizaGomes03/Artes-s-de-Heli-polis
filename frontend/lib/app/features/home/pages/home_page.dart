import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const cream = Color(0xFFFFF8EF);
  static const ink = Color(0xFF173E45);
  static const teal = Color(0xFF277E82);
  static const coral = Color(0xFFE9684B);
  static const mustard = Color(0xFFF2B63D);
  static const wine = Color(0xFF9C3153);
  static const leaf = Color(0xFF638B65);
  static const paleTeal = Color(0xFFD5E7DF);

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: cream,
      appBar: _header(context, desktop),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _hero(desktop),
            _collection(desktop),
            _storyAndImpact(desktop),
            _footer(desktop),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _header(BuildContext context, bool desktop) {
    return AppBar(
      toolbarHeight: 76,
      backgroundColor: cream,
      surfaceTintColor: cream,
      elevation: 0,
      titleSpacing: 0,
      title: _ContentWidth(
        child: Row(
          children: [
            Image.asset(
              'assets/image/logo-removebg-preview.png',
              width: desktop ? 158 : 126,
              height: 62,
              fit: BoxFit.contain,
            ),
            if (desktop) ...[
              _nav('Início', active: true),
              _nav('Loja'),
              _nav('As artesãs'),
              _nav('O projeto'),
              const SizedBox(width: 12),
            ],
            _bag(),
            if (!desktop)
              IconButton(
                onPressed: () => _openMenu(context),
                icon: const Icon(Icons.menu_rounded, color: ink),
                tooltip: 'Abrir menu',
              ),
          ],
        ),
      ),
    );
  }

  Widget _nav(String label, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(foregroundColor: active ? coral : ink),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _bag() {
    return IconButton(
      onPressed: () {},
      tooltip: 'Sacola',
      icon: Badge(
        smallSize: 8,
        backgroundColor: coral,
        child: const Icon(Icons.shopping_bag_outlined, color: ink),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: paleTeal,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 14),
              for (final item in ['Início', 'Loja', 'As artesãs', 'O projeto'])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
                  trailing: const Icon(Icons.arrow_forward_rounded, color: coral),
                  onTap: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(bool desktop) {
    return Container(
      color: teal,
      child: _ContentWidth(
        child: SizedBox(
          height: desktop ? 522 : 610,
          child: desktop
              ? Row(
                  children: [
                    Expanded(flex: 10, child: _heroCopy(desktop)),
                    Expanded(flex: 9, child: _heroPhoto()),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [_heroPhoto(), _darkOverlay(), _heroCopy(desktop)],
                ),
        ),
      ),
    );
  }

  Widget _heroCopy(bool desktop) {
    return Padding(
      padding: EdgeInsets.only(
        right: desktop ? 48 : 26,
        left: desktop ? 0 : 26,
        top: desktop ? 0 : 46,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('DA ZONA SUL DE SÃO PAULO PARA A SUA CASA', mustard),
          const SizedBox(height: 18),
          Text(
            'O feito à mão\nque faz a diferença.',
            style: TextStyle(
              color: Colors.white,
              fontSize: desktop ? 52 : 39,
              height: 1.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 18),
          const SizedBox(
            width: 430,
            child: Text(
              'Peças autorais criadas por artesãs de Heliópolis. Ao escolher uma, você leva beleza e fortalece histórias de autonomia.',
              style: TextStyle(color: Color(0xFFF5F1E4), height: 1.55, fontSize: 15),
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [_buyButton(), _ghostButton('CONHEÇA O PROJETO')],
          ),
        ],
      ),
    );
  }

  Widget _heroPhoto() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://images.unsplash.com/photo-1590736969955-71cc94801759?auto=format&fit=crop&w=1500&q=85',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: leaf),
        ),
        _darkOverlay(),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(width: 48, color: teal),
        ),
      ],
    );
  }

  Widget _darkOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [ink.withValues(alpha: .42), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buyButton() {
    return FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.shopping_bag_outlined, size: 17),
      label: const Text('EXPLORAR A LOJA'),
      style: FilledButton.styleFrom(
        backgroundColor: mustard,
        foregroundColor: ink,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .5),
      ),
    );
  }

  Widget _ghostButton(String label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .5)),
    );
  }

  Widget _collection(bool desktop) {
    final products = [
      _Product('https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=800&q=85', 'Bordado', 'Capa bordada à mão', 'R\$ 89,00', coral),
      _Product('https://images.unsplash.com/photo-1606744837616-56c9a5c6a6eb?auto=format&fit=crop&w=800&q=85', 'Decoração', 'Cesto de fibras naturais', 'R\$ 120,00', teal),
      _Product('https://images.unsplash.com/photo-1494438639946-1ebd1d20bf85?auto=format&fit=crop&w=800&q=85', 'Casa', 'Vaso em cerâmica', 'R\$ 75,00', mustard),
      _Product('https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=800&q=85', 'Têxtil', 'Almofada tecida', 'R\$ 98,00', wine),
    ];
    return _ContentWidth(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: desktop ? 76 : 52),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('VITRINE DE HISTÓRIAS', coral),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Escolha uma peça.\nApoie muitos caminhos.',
                    style: TextStyle(color: ink, fontSize: desktop ? 38 : 29, fontWeight: FontWeight.w900, height: 1.06),
                  ),
                ),
                if (desktop) _allProductsButton(),
              ],
            ),
            const SizedBox(height: 25),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tudo', 'Bordados', 'Casa', 'Acessórios', 'Presentes']
                    .map((filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: filter == 'Tudo',
                            onSelected: (_) {},
                            selectedColor: ink,
                            backgroundColor: Colors.transparent,
                            side: BorderSide(color: ink.withValues(alpha: .2)),
                            labelStyle: TextStyle(color: filter == 'Tudo' ? Colors.white : ink, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 27),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: desktop ? 4 : 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 22,
                childAspectRatio: desktop ? .69 : .61,
              ),
              itemBuilder: (_, index) => _productCard(products[index]),
            ),
            if (!desktop) ...[const SizedBox(height: 25), Center(child: _allProductsButton())],
          ],
        ),
      ),
    );
  }

  Widget _allProductsButton() {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      label: const Text('VER A LOJA COMPLETA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _productCard(_Product product) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(product.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: paleTeal)),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: product.color, borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(product.category.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 9,
                    bottom: 9,
                    child: CircleAvatar(radius: 18, backgroundColor: cream, child: Icon(Icons.add, color: ink)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(product.price, style: const TextStyle(color: coral, fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _storyAndImpact(bool desktop) {
    return Container(
      color: paleTeal,
      child: _ContentWidth(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: desktop ? 72 : 52),
          child: desktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 10, child: _story()), const SizedBox(width: 38), Expanded(flex: 9, child: _impactPanel())])
              : Column(children: [_story(), const SizedBox(height: 26), _impactPanel()]),
        ),
      ),
    );
  }

  Widget _story() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: teal, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _eyebrow('O PROJETO', mustard),
        const SizedBox(height: 16),
        const Text('Quando uma artesã cresce, a comunidade inteira floresce.', style: TextStyle(color: Colors.white, fontSize: 29, height: 1.08, fontWeight: FontWeight.w900)),
        const SizedBox(height: 17),
        const Text('As artesãs de Heliópolis, na zona sul de São Paulo, transformam o artesanato em uma importante ferramenta de geração de renda, autonomia e transformação.', style: TextStyle(color: Color(0xFFF6F2E7), fontSize: 14, height: 1.55)),
        const SizedBox(height: 24),
        _ghostButton('CONHEÇA AS ARTESÃS'),
      ]),
    );
  }

  Widget _impactPanel() {
    final impacts = [
      (Icons.account_balance_wallet_outlined, 'Geração de renda', coral),
      (Icons.auto_awesome_outlined, 'Saberes preservados', mustard),
      (Icons.diversity_1_outlined, 'Comunidade forte', wine),
    ];
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _eyebrow('CADA ESCOLHA IMPORTA', wine),
        const SizedBox(height: 15),
        const Text('Comprar aqui é apoiar um futuro mais justo.', style: TextStyle(color: ink, fontSize: 27, height: 1.1, fontWeight: FontWeight.w900)),
        const SizedBox(height: 23),
        for (final item in impacts)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(children: [CircleAvatar(radius: 18, backgroundColor: item.$3.withValues(alpha: .16), child: Icon(item.$1, color: item.$3, size: 19)), const SizedBox(width: 12), Expanded(child: Text(item.$2, style: const TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800)))]),
          ),
      ]),
    );
  }

  Widget _footer(bool desktop) {
    return Container(
      color: ink,
      child: _ContentWidth(
        child: Padding(
          padding: const EdgeInsets.only(top: 38, bottom: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (desktop)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 2, child: _brand()), Expanded(child: _footerLinks('LOJA', ['Todos os produtos', 'Presentes', 'Como comprar'])), Expanded(child: _footerLinks('SOBRE', ['As artesãs', 'O projeto', 'Contato']))])
            else ...[_brand(), const SizedBox(height: 28), _footerLinks('SOBRE', ['As artesãs', 'O projeto', 'Contato'])],
            const SizedBox(height: 28),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            const Text('© 2026 Artesãs de Heliópolis · Artesanato, Cultura e Renda', style: TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  Widget _brand() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Image.asset('assets/image/logo-removebg-preview.png', width: 180, height: 70),
      const SizedBox(height: 10),
      const SizedBox(width: 285, child: Text('Artesanato que celebra mulheres, cultura e território.', style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13))),
    ]);
  }

  Widget _footerLinks(String title, List<String> links) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: mustard, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
      const SizedBox(height: 13),
      for (final link in links) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(link, style: const TextStyle(color: Colors.white70, fontSize: 13))),
    ]);
  }

  Widget _eyebrow(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 19, height: 3, color: color),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.15)),
    ]);
  }
}

class _ContentWidth extends StatelessWidget {
  const _ContentWidth({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: desktop ? 34 : 22),
          child: child,
        ),
      ),
    );
  }
}

class _Product {
  const _Product(this.image, this.category, this.name, this.price, this.color);
  final String image;
  final String category;
  final String name;
  final String price;
  final Color color;
}
