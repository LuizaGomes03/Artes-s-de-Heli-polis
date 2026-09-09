import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'support_api.dart';

const _bg = Color(0xFFF7F0E3);
const _card = Color(0xFFFFF9EF);
const _muted = Color(0xFFEFE3D0);
const _fg = Color(0xFF3A2925);
const _dim = Color(0xFF765F55);
const _primary = Color(0xFF238F89);
const _accent = Color(0xFFC65A3A);
const _purple = Color(0xFF7A3F69);
const _yellow = Color(0xFFD5A62A);
const _border = Color(0xFFD8C5AC);

const _heroImage = 'assets/image/hero.jpg';

const _chatApiUrl = String.fromEnvironment(
  'CHAT_API_URL',
  defaultValue: 'http://127.0.0.1:3000/api',
);

const _aboutImages = [
  'https://images.unsplash.com/photo-1581475319737-4ae69b8926c7?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1552710307-537199cd41c0?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1722957533029-6b62a3826d05?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1699286029931-6315161bb3a7?q=80&w=1200&auto=format&fit=crop',
];

const _products = [
  {'name': 'Cesta Trançada Sol', 'artisan': 'Maria', 'price': 'R\$ 85', 'category': 'Casa', 'image': 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?q=80&w=900&auto=format&fit=crop'},
  {'name': 'Colar Raízes', 'artisan': 'Joana', 'price': 'R\$ 120', 'category': 'Joias', 'image': 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?q=80&w=900&auto=format&fit=crop'},
  {'name': 'Boneca Abayomi', 'artisan': 'Ana', 'price': 'R\$ 95', 'category': 'Brinquedos', 'image': 'https://images.unsplash.com/photo-1560932684-4d7e7a1f2f0f?q=80&w=900&auto=format&fit=crop'},
  {'name': 'Bolsa Horizonte', 'artisan': 'Maria', 'price': 'R\$ 160', 'category': 'Acessórios', 'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=900&auto=format&fit=crop'},
  {'name': 'Brinco Semente', 'artisan': 'Lúcia', 'price': 'R\$ 70', 'category': 'Joias', 'image': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?q=80&w=900&auto=format&fit=crop'},
  {'name': 'Manta Memória', 'artisan': 'Rosa', 'price': 'R\$ 210', 'category': 'Vestuário', 'image': 'https://images.unsplash.com/photo-1604176354204-9268737828e4?q=80&w=900&auto=format&fit=crop'},
];

enum Lang { pt, en, es }
enum Page { home, about, products, login, artisanSignup, accountSignup, buyer, cart, checkout, artisan, legal }
enum ArtisanSection { overview, orders, messages, products, sales, export, help, settings }
enum LegalDoc { terms, privacy, cookies, commerce, community }

String tr(Lang l, String pt, String en, String es) =>
    l == Lang.pt ? pt : l == Lang.en ? en : es;

class CurrentHomePage extends StatefulWidget {
  const CurrentHomePage({super.key});

  @override
  State<CurrentHomePage> createState() => _CurrentHomePageState();
}

class _CurrentHomePageState extends State<CurrentHomePage> {
  Lang lang = Lang.pt;
  Page page = Page.home;
  final cartItems = <int>[];
  final favorites = <int>{};
  bool signedIn = false;
  String role = 'buyer';

  // Seção atual da área "Minha conta" do comprador.
  String buyerSection = 'profile';

  ArtisanSection artisanSection = ArtisanSection.overview;
  LegalDoc legalDoc = LegalDoc.terms;
  String category = 'Todos';

  // Preços dos produtos são cadastrados em BRL. A moeda exibida muda
  // conforme o idioma selecionado e usa a cotação diária da API Frankfurter.
  double _brlToUsd = 0.1956;
  double _brlToEur = 0.1685;
  String _fxDate = '';
  bool _fxLoading = false;

  // Faixa promocional do topo, inspirada na dinâmica de grandes lojas.
  int _promoIndex = 0;
  Timer? _promoTimer;
  bool _cookiesAccepted = false;
  bool _checkoutAfterAuth = false;

  final TextEditingController _newsletterEmailController =
      TextEditingController();
  final TextEditingController _newsletterPhoneController =
      TextEditingController();
  String _newsletterMethod = 'email';

  final List<List<String>> _promoMessages = const [
    [
      '✦ Primeira compra? Use o cupom BEMVINDO e ganhe 10% OFF',
      '✦ First purchase? Use code WELCOME and get 10% OFF',
      '✦ ¿Primera compra? Usa el cupón BIENVENIDA y obtén 10% OFF',
    ],
    [
      '✦ Frete especial para sua primeira compra',
      '✦ Special shipping on your first order',
      '✦ Envío especial en tu primera compra',
    ],
    [
      '✦ Peças únicas feitas à mão por mulheres artesãs',
      '✦ Unique handmade pieces created by women artisans',
      '✦ Piezas únicas hechas a mano por mujeres artesanas',
    ],
    [
      '✦ Compre diretamente de artesãs de Heliópolis',
      '✦ Shop directly from artisans in Heliópolis',
      '✦ Compra directamente de artesanas de Heliópolis',
    ],
  ];

  @override
  void initState() {
    super.initState();
    _loadExchangeRates();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _promoIndex = (_promoIndex + 1) % _promoMessages.length;
      });
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _newsletterEmailController.dispose();
    _newsletterPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadExchangeRates() async {
    if (_fxLoading) return;
    _fxLoading = true;
    try {
      final uri = Uri.parse(
        'https://api.frankfurter.dev/v1/latest?base=BRL&symbols=USD,EUR',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        final usd = (rates?['USD'] as num?)?.toDouble();
        final eur = (rates?['EUR'] as num?)?.toDouble();
        if (usd != null && eur != null && mounted) {
          setState(() {
            _brlToUsd = usd;
            _brlToEur = eur;
            _fxDate = data['date']?.toString() ?? '';
          });
        }
      }
    } catch (_) {
      // Mantém a última cotação conhecida para que a loja continue funcionando
      // mesmo se o serviço de câmbio estiver temporariamente indisponível.
    } finally {
      _fxLoading = false;
    }
  }

  double _displayRate() {
    switch (lang) {
      case Lang.pt:
        return 1;
      case Lang.en:
        return _brlToUsd;
      case Lang.es:
        return _brlToEur;
    }
  }

  String _currencyCode() {
    switch (lang) {
      case Lang.pt:
        return 'BRL';
      case Lang.en:
        return 'USD';
      case Lang.es:
        return 'EUR';
    }
  }

  String _currencySymbol() {
    switch (lang) {
      case Lang.pt:
        return 'R\$';
      case Lang.en:
        return 'US\$';
      case Lang.es:
        return '€';
    }
  }

  String _money(double brlValue) {
    final value = brlValue * _displayRate();
    final formatted = value.toStringAsFixed(2);
    if (lang == Lang.pt) {
      return 'R\$ ${formatted.replaceAll('.', ',')}';
    }
    if (lang == Lang.en) {
      return 'US\$ $formatted';
    }
    return '€ $formatted'.replaceAll('.', ',');
  }

  void go(Page p) => setState(() => page = p);

  void addCart(int productIndex) {
    setState(() => cartItems.add(productIndex));
    _snack(
      tr(
        lang,
        'Produto adicionado ao carrinho.',
        'Product added to cart.',
        'Producto añadido al carrito.',
      ),
    );
  }

  void removeCartItem(int productIndex) {
    setState(() {
      cartItems.remove(productIndex);
    });
  }

  int cartQuantity(int productIndex) {
    return cartItems.where((i) => i == productIndex).length;
  }

  double _priceValue(String price) {
    final clean = price
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(clean) ?? 0;
  }

  void _openCart() => go(Page.cart);

 void _snack(String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        behavior: SnackBarBehavior.floating,
        width: 360,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}
  

  Future<void> _openChat() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _ChatDialog(
        language: lang,
        api: const SupportApi(baseUrl: _chatApiUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    switch (page) {
      case Page.home:
        body = _home();
        break;
      case Page.about:
        body = _about();
        break;
      case Page.products:
        body = _catalog();
        break;
      case Page.login:
        body = _login();
        break;
      case Page.artisanSignup:
        body = _artisanSignup();
        break;
      case Page.accountSignup:
        body = _accountSignup();
        break;
      case Page.buyer:
        body = _buyer();
        break;
      case Page.cart:
        body = _cartPage();
        break;
      case Page.checkout:
        body = _checkoutPage();
        break;
      case Page.artisan:
        body = _artisan();
        break;
      case Page.legal:
        body = _legal();
        break;
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(
            children: [
              if (page != Page.artisan) ...[
                _promoBanner(),
                _header(),
              ],
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(page),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
          if (!_cookiesAccepted && page != Page.artisan)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _cookieBanner(),
            ),
        ],
      ),
      floatingActionButton: page == Page.artisan
          ? null
          : FloatingActionButton.small(
              onPressed: _openChat,
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              tooltip: tr(lang, 'Abrir assistente', 'Open assistant', 'Abrir asistente'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
    );
  }

  Widget _promoBanner() {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 650;

    return Container(
      width: double.infinity,
      height: compact ? 40 : 44,
      color: _fg,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, .7),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );
            return ClipRect(
              child: SlideTransition(
                position: offset,
                child: FadeTransition(opacity: animation, child: child),
              ),
            );
          },
          child: Padding(
            key: ValueKey(_promoIndex),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _promoMessages[_promoIndex][lang.index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 10.5 : 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => go(Page.products),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _fg,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    tr(lang, 'Comprar', 'Shop', 'Comprar'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cookieBanner() {
    final compact = MediaQuery.sizeOf(context).width < 700;

    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 24,
          16,
          compact ? 16 : 24,
          compact ? 14 : 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr(
                      lang,
                      'Usamos cookies para melhorar sua experiência. Para mais informações, consulte nossa Política de Privacidade.',
                      'We use cookies to improve your experience. For more information, see our Privacy Policy.',
                      'Usamos cookies para mejorar tu experiencia. Para más información, consulta nuestra Política de Privacidad.',
                    ),
                    style: const TextStyle(color: _fg, fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            legalDoc = LegalDoc.cookies;
                            go(Page.legal);
                          },
                          child: Text(
                            tr(lang, 'Configurar cookies', 'Cookie settings', 'Configurar cookies'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _cookiesAccepted = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _fg,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            tr(lang, 'Aceitar todos', 'Accept all', 'Aceptar todos'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(
                        lang,
                        'Usamos cookies para melhorar sua experiência. Para mais informações, consulte nossa Política de Privacidade.',
                        'We use cookies to improve your experience. For more information, see our Privacy Policy.',
                        'Usamos cookies para mejorar tu experiencia. Para más información, consulta nuestra Política de Privacidad.',
                      ),
                      style: const TextStyle(color: _fg, fontSize: 14, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 18),
                  TextButton(
                    onPressed: () {
                      legalDoc = LegalDoc.cookies;
                      go(Page.legal);
                    },
                    child: Text(
                      tr(lang, 'Configurar cookies', 'Cookie settings', 'Configurar cookies'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _cookiesAccepted = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _fg,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    ),
                    child: Text(
                      tr(lang, 'Aceitar todos os cookies', 'Accept all cookies', 'Aceptar todas las cookies'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    final wide = MediaQuery.sizeOf(context).width > 860;

    final logo = InkWell(
      onTap: () => go(Page.home),
      child: Image.asset(
        'assets/image/logo-mulheres-artesas-heliopolis.png',
        width: 150,
        height: 70,
        fit: BoxFit.contain,
      ),
    );

    final nav = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _nav('Início', Page.home),
        _nav(
          tr(lang, 'Quem Somos', 'About Us', 'Quiénes Somos'),
          Page.about,
        ),
        _nav(
          tr(lang, 'Produtos', 'Products', 'Productos'),
          Page.products,
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _accountMenu(),
        const SizedBox(width: 12),
        Badge(
          label: Text('${cartItems.length}'),
          isLabelVisible: cartItems.isNotEmpty,
          child: IconButton(
            onPressed: _openCart,
            tooltip: tr(lang, 'Carrinho', 'Cart', 'Carrito'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ),
        const SizedBox(width: 12),
        _language(),
        if (!wide) ...[
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'home') go(Page.home);
              if (v == 'about') go(Page.about);
              if (v == 'products') go(Page.products);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'home', child: Text('Início')),
              PopupMenuItem(value: 'about', child: Text('Quem Somos')),
              PopupMenuItem(value: 'products', child: Text('Produtos')),
            ],
            child: const Icon(Icons.menu),
          ),
        ],
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBF5E9),
        border: Border(
          bottom: BorderSide(color: _border, width: 1.2),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 10,
            ),
            child: SizedBox(
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: logo,
                  ),
                  if (wide)
                    Align(
                      alignment: Alignment.center,
                      child: nav,
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: actions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(String label, Page p) {
    return TextButton(
      onPressed: () => go(p),
      child: Text(
        label,
        style: TextStyle(
          color: page == p ? _fg : _dim,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _accountMenu() {
    if (signedIn) {
      return IconButton(
        onPressed: () => go(role == 'artisan' ? Page.artisan : Page.buyer),
        tooltip: tr(lang, 'Minha conta', 'My account', 'Mi cuenta'),
        icon: const Icon(Icons.person_outline),
      );
    }

    // MenuAnchor abre o menu abaixo do ícone, evitando que ele apareça
    // sobre o próprio botão em janelas grandes.
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Color(0xFFF4F9F7)),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () => go(Page.login),
          child: Text(tr(lang, 'Entrar', 'Sign in', 'Entrar')),
        ),
        MenuItemButton(
          onPressed: () => go(Page.accountSignup),
          child: Text(tr(lang, 'Criar conta', 'Create account', 'Crear cuenta')),
        ),
        const Divider(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 18, color: _primary),
              const SizedBox(width: 8),
              Text(
                tr(lang, 'Mulheres artesãs', 'Women artisans', 'Mujeres artesanas'),
                style: const TextStyle(color: _primary, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () => go(Page.login),
          child: Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(tr(lang, 'Entrar', 'Sign in', 'Entrar')),
          ),
        ),
        MenuItemButton(
          onPressed: () => go(Page.artisanSignup),
          child: Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(tr(lang, 'Inscrever-se', 'Sign up', 'Inscribirse')),
          ),
        ),
      ],
      builder: (context, controller, child) => IconButton(
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        tooltip: tr(lang, 'Minha conta', 'My account', 'Mi cuenta'),
        icon: const Icon(Icons.person_outline),
      ),
    );
  }

  Widget _language() {
    return PopupMenuButton<Lang>(
      initialValue: lang,
      onSelected: (v) {
        setState(() {
          lang = v;
          category = 'Todos';
        });
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: Lang.pt,
          child: Text('🇧🇷 Português'),
        ),
        PopupMenuItem(
          value: Lang.en,
          child: Text('🇺🇸 English'),
        ),
        PopupMenuItem(
          value: Lang.es,
          child: Text('🇪🇸 Español'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          lang == Lang.pt
              ? 'BR PT'
              : lang == Lang.en
                  ? 'EN'
                  : 'ES',
        ),
      ),
    );
  }

  Widget _home() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _hero(),
          _aboutHome(),
          _featured(),
          _how(),
          _signup(),
          _footer(),
        ],
      ),
    );
  }

  Widget _hero() {
    final desktop = MediaQuery.sizeOf(context).width > 900;

    final copy = tr(
      lang,
      'Uma plataforma feita para conectar você ao artesanato de Heliópolis. Descubra produtos únicos feitos à mão por mulheres artesãs da comunidade, conheça suas histórias e encontre peças com identidade, criatividade e propósito.',
      'A platform made to connect you with the crafts of Heliópolis. Discover unique handmade products created by women artisans from the community, learn their stories and find pieces with identity, creativity and purpose.',
      'Una plataforma creada para conectarte con la artesanía de Heliópolis. Descubre productos únicos hechos a mano por mujeres artesanas de la comunidad, conoce sus historias y encuentra piezas con identidad, creatividad y propósito.',
    );

    final left = Container(
      height: desktop ? 620 : null,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 58 : 26,
        vertical: desktop ? 70 : 55,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _bg,
            Color(0xFFF1DFC6),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1E8),
              border: Border.all(
                color: const Color(0xFF9BC7C1),
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              tr(
                lang,
                '✦ Comunidade de Heliópolis, SP',
                '✦ Heliópolis Community, SP',
                '✦ Comunidad de Heliópolis, SP',
              ),
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            tr(
              lang,
              'O artesanato\nde Heliópolis\npara o mundo.',
              'The craftsmanship\nof Heliópolis\nfor the world.',
              'La artesanía\nde Heliópolis\npara el mundo.',
            ),
            style: TextStyle(
              fontSize: desktop ? 58 : 42,
              height: 1.03,
              fontWeight: FontWeight.w800,
              color: _fg,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              copy,
              style: TextStyle(
                color: _dim,
                fontSize: desktop ? 16 : 14,
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => go(Page.products),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  tr(lang, 'Ver produtos', 'View products', 'Ver productos'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => go(Page.about),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  tr(
                    lang,
                    'Conheça o projeto',
                    'Discover the project',
                    'Conoce el proyecto',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final right = SizedBox(
      height: desktop ? 620 : 360,
      width: double.infinity,
      child: ClipRect(
        child: Image.asset(
          _heroImage,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) {
            return Container(
              color: _muted,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 60,
                color: _dim,
              ),
            );
          },
        ),
      ),
    );

    if (desktop) {
      return SizedBox(
        height: 620,
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            Expanded(child: right),
          ],
        ),
      );
    }

    return Column(
      children: [
        left,
        right,
      ],
    );
  }

  Widget _sectionTitle(
    String eyebrow,
    String title, {
    String? text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: _primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: _fg,
            fontWeight: FontWeight.w800,
            fontSize: 38,
            height: 1.08,
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(
              color: _dim,
              fontSize: 15,
              height: 1.65,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // QUEM SOMOS — NOVA VERSÃO
  // ============================================================

  Widget _about() {
    final desktop = MediaQuery.sizeOf(context).width > 900;

    return SingleChildScrollView(
      child: Column(
        children: [
          _aboutHero(desktop),
          _aboutStory(desktop),
          _aboutImpact(),
          _aboutMission(),
          _aboutPlatform(),
          _aboutGallery(desktop),
          _aboutPillars(),
          _aboutQuote(),
          _aboutCta(),
          _footer(),
        ],
      ),
    );
  }

  Widget _aboutHero(bool desktop) {
    return Container(
      width: double.infinity,
      color: _bg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 65, 28, 75),
            child: desktop
                ? Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _aboutHeroCopy(),
                      ),
                      const SizedBox(width: 55),
                      Expanded(
                        flex: 5,
                        child: _aboutPhoto(
                          _aboutImages[0],
                          height: 500,
                          radius: 24,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _aboutHeroCopy(),
                      const SizedBox(height: 35),
                      _aboutPhoto(
                        _aboutImages[0],
                        height: 360,
                        radius: 22,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _aboutHeroCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _aboutTag(
          tr(
            lang,
            '✦ QUEM SOMOS',
            '✦ ABOUT US',
            '✦ QUIÉNES SOMOS',
          ),
        ),
        const SizedBox(height: 25),
        Text(
          tr(
            lang,
            'Mulheres que criam.\nHistórias que conectam.',
            'Women who create.\nStories that connect.',
            'Mujeres que crean.\nHistorias que conectan.',
          ),
          style: const TextStyle(
            color: _fg,
            fontSize: 50,
            height: 1.04,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          tr(
            lang,
            'O Artesãs de Heliópolis nasceu para dar visibilidade ao talento artesanal da comunidade e criar novas possibilidades para quem transforma criatividade, memória e técnica em trabalho.',
            'Artesãs de Heliópolis was created to give visibility to the community’s artisan talent and create new possibilities for women who turn creativity, memory and technique into work.',
            'Artesãs de Heliópolis nació para dar visibilidad al talento artesanal de la comunidad y crear nuevas posibilidades para quienes transforman creatividad, memoria y técnica en trabajo.',
          ),
          style: const TextStyle(
            color: _dim,
            fontSize: 17,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            _miniInfo(Icons.location_on_outlined, 'Heliópolis, SP'),
            _miniInfo(Icons.public_outlined, 'Brasil + mundo'),
            _miniInfo(Icons.favorite_border, 'Feito à mão'),
          ],
        ),
      ],
    );
  }

  Widget _aboutTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0EC),
        border: Border.all(
          color: const Color(0xFF9BC7C1),
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _primary,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: .7,
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: _primary,
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: _dim,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _aboutStory(bool desktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBF5E9),
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 85,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _aboutPhoto(
                        _aboutImages[1],
                        height: 460,
                        radius: 22,
                      ),
                    ),
                    const SizedBox(width: 65),
                    Expanded(
                      child: _aboutStoryCopy(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _aboutPhoto(
                      _aboutImages[1],
                      height: 350,
                      radius: 22,
                    ),
                    const SizedBox(height: 40),
                    _aboutStoryCopy(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _aboutStoryCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          tr(lang, 'Nossa história', 'Our story', 'Nuestra historia'),
          tr(
            lang,
            'De Heliópolis para novos caminhos.',
            'From Heliópolis to new paths.',
            'De Heliópolis hacia nuevos caminos.',
          ),
        ),
        const SizedBox(height: 25),
        _bodyText(
          tr(
            lang,
            'O projeto nasceu com uma ideia simples: aproximar o trabalho das mulheres artesãs de Heliópolis de pessoas que valorizam produtos feitos à mão e, ao mesmo tempo, ampliar as oportunidades para quem produz.',
            'The project started with a simple idea: connect the work of women artisans from Heliópolis with people who value handmade products while expanding opportunities for those who create them.',
            'El proyecto nació con una idea sencilla: acercar el trabajo de las mujeres artesanas de Heliópolis a personas que valoran los productos hechos a mano y, al mismo tiempo, ampliar las oportunidades para quienes los crean.',
          ),
        ),
        const SizedBox(height: 17),
        _bodyText(
          tr(
            lang,
            'Cada peça representa mais do que um produto. Ela carrega uma técnica, uma lembrança, uma identidade e muitas horas de dedicação. Por isso, queremos que cada criação tenha espaço para ser conhecida e valorizada.',
            'Each piece represents more than a product. It carries a technique, a memory, an identity and many hours of dedication. That is why we want every creation to have a space to be known and valued.',
            'Cada pieza representa más que un producto. Lleva una técnica, un recuerdo, una identidad y muchas horas de dedicación. Por eso queremos que cada creación tenga un espacio para ser conocida y valorada.',
          ),
        ),
        const SizedBox(height: 17),
        _bodyText(
          tr(
            lang,
            'A tecnologia entra como ponte: catálogo digital, comunicação, acessibilidade, orientação e conexão com novos públicos. A essência continua sendo humana: pessoas criando, contando suas histórias e construindo oportunidades.',
            'Technology acts as a bridge: digital catalogue, communication, accessibility, guidance and connection with new audiences. The essence remains human: people creating, telling their stories and building opportunities.',
            'La tecnología funciona como puente: catálogo digital, comunicación, accesibilidad, orientación y conexión con nuevos públicos. La esencia sigue siendo humana: personas creando, contando sus historias y construyendo oportunidades.',
          ),
        ),
      ],
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _dim,
        fontSize: 15,
        height: 1.75,
      ),
    );
  }

  Widget _aboutPhoto(
    String url, {
    required double height,
    double radius = 18,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: height,
            width: double.infinity,
            color: _muted,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 50,
              color: _dim,
            ),
          );
        },
      ),
    );
  }

  Widget _aboutImpact() {
    return Container(
      width: double.infinity,
      color: _bg,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                tr(lang, 'Nosso impacto', 'Our impact', 'Nuestro impacto'),
                tr(
                  lang,
                  'Mais do que produtos. Novas possibilidades.',
                  'More than products. New possibilities.',
                  'Más que productos. Nuevas posibilidades.',
                ),
              ),
              const SizedBox(height: 35),
              LayoutBuilder(
                builder: (_, c) {
                  final count = c.maxWidth > 900
                      ? 4
                      : c.maxWidth > 580
                          ? 2
                          : 1;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: count,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [
                      _impactCard(
                        Icons.groups_outlined,
                        'Mulheres',
                        tr(
                          lang,
                          'Colocamos as artesãs no centro da experiência.',
                          'Artisans are at the center of the experience.',
                          'Las artesanas están en el centro de la experiencia.',
                        ),
                      ),
                      _impactCard(
                        Icons.handyman_outlined,
                        'Artesanato',
                        tr(
                          lang,
                          'Valorizamos técnicas, materiais e saberes.',
                          'We value techniques, materials and knowledge.',
                          'Valoramos técnicas, materiales y conocimientos.',
                        ),
                      ),
                      _impactCard(
                        Icons.public_outlined,
                        'Novos mercados',
                        tr(
                          lang,
                          'Criamos pontes entre Heliópolis e o mundo.',
                          'We build bridges between Heliópolis and the world.',
                          'Creamos puentes entre Heliópolis y el mundo.',
                        ),
                      ),
                      _impactCard(
                        Icons.trending_up,
                        'Oportunidades',
                        tr(
                          lang,
                          'Tecnologia para ampliar visibilidade e possibilidades de renda.',
                          'Technology to expand visibility and income opportunities.',
                          'Tecnología para ampliar visibilidad y oportunidades de ingresos.',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _impactCard(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F0EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _primary,
              size: 27,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: _fg,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: _dim,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutMission() {
    return Container(
      width: double.infinity,
      color: _primary,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 85,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 930),
          child: Column(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(height: 20),
              Text(
                tr(
                  lang,
                  'NOSSA MISSÃO',
                  'OUR MISSION',
                  'NUESTRA MISIÓN',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                tr(
                  lang,
                  'Dar visibilidade ao talento das mulheres artesãs de Heliópolis e criar caminhos para que seus produtos alcancem novos públicos, mercados e oportunidades.',
                  'Give visibility to the talent of women artisans from Heliópolis and create paths for their products to reach new audiences, markets and opportunities.',
                  'Dar visibilidad al talento de las mujeres artesanas de Heliópolis y crear caminos para que sus productos lleguen a nuevos públicos, mercados y oportunidades.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutPlatform() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBF5E9),
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 85,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                tr(lang, 'A plataforma', 'The platform', 'La plataforma'),
                tr(
                  lang,
                  'Como transformamos essa ideia em experiência.',
                  'How we turn this idea into an experience.',
                  'Cómo transformamos esta idea en una experiencia.',
                ),
              ),
              const SizedBox(height: 35),
              LayoutBuilder(
                builder: (_, c) {
                  final count = c.maxWidth > 900
                      ? 3
                      : c.maxWidth > 580
                          ? 2
                          : 1;

                  final items = [
                    [
                      Icons.storefront_outlined,
                      tr(lang, 'Vitrine digital', 'Digital showcase', 'Escaparate digital'),
                      tr(
                        lang,
                        'Artesãs podem apresentar suas peças, técnicas, histórias e informações de compra.',
                        'Artisans can showcase pieces, techniques, stories and purchase information.',
                        'Las artesanas pueden presentar piezas, técnicas, historias e información de compra.',
                      ),
                    ],
                    [
                      Icons.language_outlined,
                      tr(lang, 'Alcance internacional', 'International reach', 'Alcance internacional'),
                      tr(
                        lang,
                        'Conteúdo em diferentes idiomas para aproximar o artesanato de compradores de outros lugares.',
                        'Multilingual content helps connect crafts with buyers from other places.',
                        'Contenido multilingüe para acercar la artesanía a compradores de otros lugares.',
                      ),
                    ],
                    [
                      Icons.school_outlined,
                      tr(lang, 'Orientação', 'Guidance', 'Orientación'),
                      tr(
                        lang,
                        'Informações para apoiar as artesãs em vendas, organização e preparação para novos mercados.',
                        'Information to support artisans with sales, organization and new markets.',
                        'Información para apoyar a las artesanas en ventas, organización y nuevos mercados.',
                      ),
                    ],
                    [
                      Icons.accessibility_new_outlined,
                      tr(lang, 'Acessibilidade', 'Accessibility', 'Accesibilidad'),
                      tr(
                        lang,
                        'Uma experiência simples, clara e pensada para diferentes públicos.',
                        'A simple, clear experience designed for different audiences.',
                        'Una experiencia simple, clara y pensada para diferentes públicos.',
                      ),
                    ],
                    [
                      Icons.favorite_border,
                      tr(lang, 'Histórias', 'Stories', 'Historias'),
                      tr(
                        lang,
                        'Cada produto pode ser conhecido também pela pessoa e pela trajetória por trás dele.',
                        'Each product can also be discovered through the person and story behind it.',
                        'Cada producto también puede conocerse a través de la persona y la historia que hay detrás.',
                      ),
                    ],
                    [
                      Icons.shopping_bag_outlined,
                      tr(lang, 'Conexão', 'Connection', 'Conexión'),
                      tr(
                        lang,
                        'Facilitamos a aproximação entre quem cria e quem valoriza o feito à mão.',
                        'We bring creators and people who value handmade work closer together.',
                        'Acercamos a quienes crean y a quienes valoran lo hecho a mano.',
                      ),
                    ],
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: 1.12,
                    ),
                    itemBuilder: (_, i) {
                      return _platformCard(
                        items[i][0] as IconData,
                        items[i][1] as String,
                        items[i][2] as String,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _platformCard(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F0EC),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: _primary,
              size: 25,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: _fg,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: _dim,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutGallery(bool desktop) {
    return Container(
      width: double.infinity,
      color: _bg,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 85,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                tr(
                  lang,
                  'O fazer artesanal',
                  'The craft',
                  'El trabajo artesanal',
                ),
                tr(
                  lang,
                  'Por trás de cada peça existe uma história.',
                  'Behind every piece there is a story.',
                  'Detrás de cada pieza hay una historia.',
                ),
              ),
              const SizedBox(height: 35),
              desktop
                  ? SizedBox(
                      height: 430,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _galleryImage(_aboutImages[2]),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _galleryImage(_aboutImages[3]),
                                ),
                                const SizedBox(height: 15),
                                Expanded(
                                  child: _galleryImage(_aboutImages[1]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _galleryImage(
                          _aboutImages[2],
                          height: 300,
                        ),
                        const SizedBox(height: 15),
                        _galleryImage(
                          _aboutImages[3],
                          height: 240,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _galleryImage(
    String url, {
    double? height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        url,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: double.infinity,
            height: height,
            color: _muted,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              size: 45,
              color: _dim,
            ),
          );
        },
      ),
    );
  }

  Widget _aboutPillars() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBF5E9),
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 85,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                tr(lang, 'O que nos move', 'What drives us', 'Lo que nos mueve'),
                tr(
                  lang,
                  'Três princípios no coração do projeto.',
                  'Three principles at the heart of the project.',
                  'Tres principios en el corazón del proyecto.',
                ),
              ),
              const SizedBox(height: 35),
              LayoutBuilder(
                builder: (_, c) {
                  final count = c.maxWidth > 850
                      ? 3
                      : c.maxWidth > 550
                          ? 2
                          : 1;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: count,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.05,
                    children: [
                      _pillarCard(
                        '01',
                        'VALORIZAR',
                        tr(
                          lang,
                          'Reconhecer o valor do trabalho manual, dos saberes e das histórias que cada artesã carrega.',
                          'Recognize the value of handmade work, knowledge and the stories each artisan carries.',
                          'Reconocer el valor del trabajo manual, los conocimientos y las historias de cada artesana.',
                        ),
                        _primary,
                      ),
                      _pillarCard(
                        '02',
                        'CONECTAR',
                        tr(
                          lang,
                          'Criar pontes entre artesãs, compradores, parceiros e novos mercados.',
                          'Build bridges between artisans, buyers, partners and new markets.',
                          'Crear puentes entre artesanas, compradores, socios y nuevos mercados.',
                        ),
                        _accent,
                      ),
                      _pillarCard(
                        '03',
                        'TRANSFORMAR',
                        tr(
                          lang,
                          'Transformar visibilidade em oportunidades, autonomia e novas possibilidades.',
                          'Turn visibility into opportunities, autonomy and new possibilities.',
                          'Transformar visibilidad en oportunidades, autonomía y nuevas posibilidades.',
                        ),
                        _purple,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillarCard(
    String number,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 13),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: _dim,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutQuote() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1DFC6),
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 90,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              const Text(
                '“',
                style: TextStyle(
                  color: _primary,
                  fontSize: 72,
                  height: .7,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                tr(
                  lang,
                  'Cada peça carrega um pouco de quem somos, de onde viemos e do que podemos construir juntas.',
                  'Every piece carries a little of who we are, where we come from and what we can build together.',
                  'Cada pieza lleva un poco de quiénes somos, de dónde venimos y de lo que podemos construir juntas.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _fg,
                  fontSize: 29,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutCta() {
    return Container(
      width: double.infinity,
      color: _bg,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 80,
      ),
      child: Center(
        child: Column(
          children: [
            _aboutTag(
              tr(
                lang,
                'FAÇA PARTE',
                'BE PART OF IT',
                'SÉ PARTE',
              ),
            ),
            const SizedBox(height: 22),
            Text(
              tr(
                lang,
                'Conheça quem cria.\nDescubra o que transforma.',
                'Meet the creators.\nDiscover what transforms.',
                'Conoce a quienes crean.\nDescubre lo que transforma.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _fg,
                fontSize: 34,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              tr(
                lang,
                'Explore produtos únicos feitos à mão e apoie histórias que merecem chegar mais longe.',
                'Explore unique handmade products and support stories that deserve to go farther.',
                'Explora productos únicos hechos a mano y apoya historias que merecen llegar más lejos.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _dim,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => go(Page.products),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                tr(
                  lang,
                  'Conhecer produtos',
                  'Explore products',
                  'Conocer productos',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 27,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _aboutHome() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: LayoutBuilder(
            builder: (context, c) {
              final d = c.maxWidth > 800;

              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    tr(lang, 'Quem Somos', 'About Us', 'Quiénes Somos'),
                    tr(
                      lang,
                      'Mulheres, histórias e oportunidades que começam em Heliópolis.',
                      'Women, stories and opportunities that begin in Heliópolis.',
                      'Mujeres, historias y oportunidades que comienzan en Heliópolis.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  _bodyText(
                    tr(
                      lang,
                      'Conheça as mulheres que transformam técnicas, memórias e materiais em peças únicas. Cada criação nasce de uma trajetória, de saberes compartilhados e do desejo de construir novas possibilidades.',
                      'Meet the women who turn techniques, memories and materials into unique pieces. Each creation grows from a journey, shared knowledge and the desire to build new possibilities.',
                      'Conoce a las mujeres que transforman técnicas, memorias y materiales en piezas únicas. Cada creación nace de una trayectoria, saberes compartidos y el deseo de construir nuevas posibilidades.',
                    ),
                  ),
                ],
              );

              final image = _aboutPhoto(
                _aboutImages[0],
                height: 380,
              );

              return d
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: text),
                        const SizedBox(width: 55),
                        Expanded(child: image),
                      ],
                    )
                  : Column(
                      children: [
                        image,
                        const SizedBox(height: 30),
                        text,
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _featured() {
    return Container(
      color: const Color(0xFFFBF5E9),
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _sectionTitle(
                      tr(lang, 'Nossa loja', 'Our store', 'Nuestra tienda'),
                      tr(
                        lang,
                        'Peças com história.',
                        'Pieces with a story.',
                        'Piezas con historia.',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => go(Page.products),
                    child: Text(
                      tr(lang, 'Ver mais →', 'See more →', 'Ver más →'),
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              LayoutBuilder(
                builder: (_, c) {
                  final count = c.maxWidth > 900
                      ? 3
                      : c.maxWidth > 600
                          ? 2
                          : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: .76,
                    ),
                    itemBuilder: (_, i) => _productCard(i),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productCard(int i) {
    final p = _products[i];

    return Card(
      color: _card,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    p['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: _muted,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 45,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor:
                        Colors.white.withValues(alpha: .92),
                    child: IconButton(
                      iconSize: 18,
                      onPressed: () {
                        setState(() {
                          favorites.contains(i)
                              ? favorites.remove(i)
                              : favorites.add(i);
                        });
                      },
                      icon: Icon(
                        favorites.contains(i)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: favorites.contains(i)
                            ? _accent
                            : _fg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['category']!.toUpperCase(),
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  p['name']!,
                  style: const TextStyle(
                    color: _fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tr(lang, 'por', 'by', 'por')} ${p['artisan']}',
                  style: const TextStyle(
                    color: _dim,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _money(_priceValue(p['price']!)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _fg,
                      ),
                    ),
                    TextButton(
                      onPressed: () => addCart(i),
                      child: Text(
                        tr(lang, 'Comprar', 'Buy', 'Comprar'),
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

  Widget _how() {
    final items = [
      tr(lang, 'Peças feitas à mão', 'Handmade pieces', 'Piezas hechas a mano'),
      tr(lang, 'Histórias que conectam', 'Stories that connect', 'Historias que conectan'),
      tr(lang, 'Compra direta', 'Buy directly', 'Compra directa'),
      tr(lang, 'Impacto na comunidade', 'Community impact', 'Impacto en la comunidad'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                tr(lang, 'Como funciona', 'How it works', 'Cómo funciona'),
                tr(
                  lang,
                  'Do feito à mão para o mundo.',
                  'From handmade to the world.',
                  'De lo hecho a mano al mundo.',
                ),
              ),
              const SizedBox(height: 30),
              LayoutBuilder(
                builder: (_, c) {
                  final n = c.maxWidth > 900
                      ? 4
                      : c.maxWidth > 550
                          ? 2
                          : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: n,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (_, i) {
                      return Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _card,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '0${i + 1}',
                              style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 25),
                            Text(
                              items[i],
                              style: const TextStyle(
                                color: _fg,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Text(
                                tr(
                                  lang,
                                  [
                                    'Encontre produtos únicos feitos com cuidado por mulheres artesãs.',
                                    'Conheça técnicas, histórias e referências culturais.',
                                    'Escolha sua peça e compre pela plataforma.',
                                    'Sua compra fortalece renda e trabalho na comunidade.',
                                  ][i],
                                  [
                                    'Find unique products carefully made by women artisans.',
                                    'Learn techniques, stories and cultural references.',
                                    'Choose your piece and buy through the platform.',
                                    'Your purchase strengthens income and work in the community.',
                                  ][i],
                                  [
                                    'Encuentra productos únicos hechos por mujeres artesanas.',
                                    'Conoce técnicas, historias y referencias culturales.',
                                    'Elige tu pieza y compra en la plataforma.',
                                    'Tu compra fortalece los ingresos y el trabajo comunitario.',
                                  ][i],
                                ),
                                style: const TextStyle(
                                  color: _dim,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signup() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 70,
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              tr(
                lang,
                'Pronta para fazer parte?',
                'Ready to be part of it?',
                '¿Lista para ser parte?',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr(
                lang,
                'Cadastre-se para comprar ou apresentar sua arte ao mundo.',
                'Sign up to shop or present your art to the world.',
                'Regístrate para comprar o presentar tu arte al mundo.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 25),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => go(Page.accountSignup),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primary,
                  ),
                  child: Text(
                    tr(
                      lang,
                      'Criar uma conta',
                      'Create an account',
                      'Crear una cuenta',
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => go(Page.artisanSignup),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: Text(
                    tr(
                      lang,
                      'Quero ser artesã',
                      'I want to be an artisan',
                      'Quiero ser artesana',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBF5E9),
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 55,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              _newsletter(),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 35,
                spacing: 70,
                children: [
                  SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/image/logo-mulheres-artesas-heliopolis.png',
                          width: 175,
                          height: 78,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          tr(
                            lang,
                            'Conectando o talento artesanal de Heliópolis com o mercado mundial.',
                            'Connecting Heliópolis artisan talent with the global market.',
                            'Conectando el talento artesanal de Heliópolis con el mercado mundial.',
                          ),
                          style: const TextStyle(
                            color: _dim,
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _footerCol(
                    tr(lang, 'Plataforma', 'Platform', 'Plataforma'),
                    [
                      tr(
                        lang,
                        'Como Funciona',
                        'How It Works',
                        'Cómo funciona',
                      ),
                      tr(
                        lang,
                        'Catálogo',
                        'Catalogue',
                        'Catálogo',
                      ),
                      tr(
                        lang,
                        'Guia de Exportação',
                        'Export Guide',
                        'Guía de exportación',
                      ),
                      tr(
                        lang,
                        'Mercados',
                        'Markets',
                        'Mercados',
                      ),
                    ],
                  ),

                  _footerCol(
                    tr(lang, 'Suporte', 'Support', 'Soporte'),
                    [
                      tr(
                        lang,
                        'Central de Ajuda',
                        'Help Center',
                        'Centro de ayuda',
                      ),
                      tr(
                        lang,
                        'WhatsApp',
                        'WhatsApp',
                        'WhatsApp',
                      ),
                      tr(
                        lang,
                        'Documentação',
                        'Documentation',
                        'Documentación',
                      ),
                      tr(
                        lang,
                        'Parceiros',
                        'Partners',
                        'Socios',
                      ),
                    ],
                  ),

                  _footerCol(
                    tr(lang, 'Comunidade', 'Community', 'Comunidad'),
                    [
                      tr(
                        lang,
                        'Sobre Heliópolis',
                        'About Heliópolis',
                        'Sobre Heliópolis',
                      ),
                      tr(
                        lang,
                        'Histórias de Sucesso',
                        'Success Stories',
                        'Historias de éxito',
                      ),
                      tr(
                        lang,
                        'Eventos',
                        'Events',
                        'Eventos',
                      ),
                      tr(
                        lang,
                        'Blog',
                        'Blog',
                        'Blog',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 38),

              const Divider(
                color: _border,
                height: 1,
              ),

              const SizedBox(height: 24),

              Text(
                tr(
                  lang,
                  '© 2026 Artesãs de Heliópolis Global · Heliópolis, São Paulo, Brasil',
                  '© 2026 Artesãs de Heliópolis Global · Heliópolis, São Paulo, Brazil',
                  '© 2026 Artesãs de Heliópolis Global · Heliópolis, São Paulo, Brasil',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _dim,
                  fontSize: 12.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                tr(
                  lang,
                  'Desenvolvido por alunos do Instituto Mauá de Tecnologia.',
                  'Developed by students from Instituto Mauá de Tecnologia.',
                  'Desarrollado por estudiantes del Instituto Mauá de Tecnologia.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9A8880),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newsletter() {
    final compact = MediaQuery.sizeOf(context).width < 700;
    final phone = _newsletterMethod == 'phone';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC8DDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(
              lang,
              'Receba novidades das Artesãs',
              'Get updates from the Artisans',
              'Recibe novedades de las Artesanas',
            ),
            style: const TextStyle(
              color: _fg,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            tr(
              lang,
              'Cadastre-se para receber lançamentos, novidades, oportunidades e ofertas especiais.',
              'Sign up for launches, news, opportunities and special offers.',
              'Regístrate para recibir lanzamientos, novedades, oportunidades y ofertas especiales.',
            ),
            style: const TextStyle(color: _dim, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 17),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                selected: !phone,
                label: Text(tr(lang, '✉ E-mail', '✉ Email', '✉ Correo')),
                onSelected: (_) => setState(() => _newsletterMethod = 'email'),
              ),
              ChoiceChip(
                selected: phone,
                label: Text(tr(lang, '☎ Telefone / WhatsApp', '☎ Phone / WhatsApp', '☎ Teléfono / WhatsApp')),
                onSelected: (_) => setState(() => _newsletterMethod = 'phone'),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (compact)
            Column(
              children: [
                _newsletterField(phone),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _newsletterButton(),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _newsletterField(phone)),
                const SizedBox(width: 10),
                _newsletterButton(),
              ],
            ),
          const SizedBox(height: 9),
          Text(
            tr(
              lang,
              'Ao cadastrar, você concorda em receber comunicações da plataforma.',
              'By subscribing, you agree to receive communications from the platform.',
              'Al suscribirte, aceptas recibir comunicaciones de la plataforma.',
            ),
            style: const TextStyle(color: _dim, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _newsletterField(bool phone) {
    return TextField(
      controller: phone ? _newsletterPhoneController : _newsletterEmailController,
      keyboardType: phone ? TextInputType.phone : TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: phone
            ? tr(lang, 'Digite seu telefone ou WhatsApp', 'Enter your phone or WhatsApp', 'Ingresa tu teléfono o WhatsApp')
            : tr(lang, 'Digite seu melhor e-mail', 'Enter your email', 'Ingresa tu correo electrónico'),
        prefixIcon: Icon(phone ? Icons.phone_outlined : Icons.email_outlined),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _newsletterButton() {
    return ElevatedButton(
      onPressed: _subscribeNewsletter,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Text(tr(lang, 'Cadastrar', 'Subscribe', 'Suscribirme')),
    );
  }

  void _subscribeNewsletter() {
    final value = (_newsletterMethod == 'email'
            ? _newsletterEmailController
            : _newsletterPhoneController)
        .text
        .trim();

    if (value.isEmpty) {
      _snack(
        tr(
          lang,
          'Digite seu e-mail ou telefone para continuar.',
          'Enter your email or phone to continue.',
          'Ingresa tu correo o teléfono para continuar.',
        ),
      );
      return;
    }

    _snack(
      tr(
        lang,
        'Cadastro realizado! Você receberá nossas novidades.',
        'Subscribed! You will receive our latest updates.',
        '¡Registro realizado! Recibirás nuestras novedades.',
      ),
    );

    if (_newsletterMethod == 'email') {
      _newsletterEmailController.clear();
    } else {
      _newsletterPhoneController.clear();
    }
  }

  Widget _footerCol(String title, List<String> links) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: _fg,
            ),
          ),
          const SizedBox(height: 10),
          ...links.map(
            (x) => TextButton(
              onPressed: () => _footerAction(x),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                x,
                style: const TextStyle(
                  color: _dim,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _footerAction(String x) {
    if (x == 'Catálogo') {
      go(Page.products);
    } else if (x == 'Sobre Heliópolis') {
      go(Page.about);
    } else if (x == 'Guia de Exportação') {
      go(Page.artisanSignup);
    } else if (x == 'Central de Ajuda') {
      artisanSection = ArtisanSection.help;
      go(Page.artisan);
    }
  }

  // ============================================================
  // CATÁLOGO
  // ============================================================

  Widget _catalog() {
    final cats = [
      'Todos',
      'Acessórios',
      'Joias',
      'Casa',
      'Vestuário',
      'Brinquedos',
    ];

    final list = category == 'Todos'
        ? List.generate(_products.length, (i) => i)
        : List.generate(_products.length, (i) => i)
            .where((i) => _products[i]['category'] == category)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _sectionTitle(
                tr(lang, 'Catálogo', 'Catalogue', 'Catálogo'),
                tr(
                  lang,
                  'Feito à mão, com propósito.',
                  'Handmade, with purpose.',
                  'Hecho a mano, con propósito.',
                ),
              ),
              const SizedBox(height: 25),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map(
                  (c) => ChoiceChip(
                    label: Text(c),
                    selected: category == c,
                    onSelected: (_) {
                      setState(() => category = c);
                    },
                    selectedColor: _primary,
                    labelStyle: TextStyle(
                      color: category == c ? Colors.white : _fg,
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 30),
              LayoutBuilder(
                builder: (_, c) {
                  final n = c.maxWidth > 950
                      ? 3
                      : c.maxWidth > 600
                          ? 2
                          : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: n,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: .76,
                    ),
                    itemBuilder: (_, j) => _productCard(list[j]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN / CADASTROS
  // ============================================================

  Widget _login() {
    return _formPage(
      title: tr(lang, 'Minha conta', 'My account', 'Mi cuenta'),
      subtitle: tr(
        lang,
        'Entre para acompanhar compras ou gerenciar seu perfil de artesã.',
        'Sign in to manage purchases or your artisan profile.',
        'Inicia sesión para gestionar compras o tu perfil de artesana.',
      ),
      fields: ['E-mail', 'Senha'],
      button: tr(lang, 'Entrar', 'Sign in', 'Entrar'),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Ainda não tem conta?'),
          TextButton(
            onPressed: () => go(Page.accountSignup),
            child: Text(
              tr(lang, 'Criar conta', 'Create account', 'Crear cuenta'),
            ),
          ),
        ],
      ),
      onSubmit: () {
        signedIn = true;
        role = 'buyer';
        _snack(tr(lang, 'Login realizado com sucesso!', 'Signed in successfully!', '¡Sesión iniciada con éxito!'));
        if (_checkoutAfterAuth) {
          _checkoutAfterAuth = false;
          go(Page.checkout);
        } else {
          go(Page.home);
        }
      },
    );
  }

  Widget _accountSignup() {
    return _formPage(
      title: tr(
        lang,
        'Crie sua conta',
        'Create your account',
        'Crea tu cuenta',
      ),
      subtitle: tr(
        lang,
        'Cadastre-se para comprar, favoritar produtos e acompanhar pedidos.',
        'Sign up to shop, favorite products and track orders.',
        'Regístrate para comprar, guardar favoritos y seguir pedidos.',
      ),
      fields: ['Nome', 'E-mail', 'Senha', 'Confirmar senha'],
      button: tr(
        lang,
        'Criar minha conta',
        'Create my account',
        'Crear mi cuenta',
      ),
      footer: TextButton(
        onPressed: () => go(Page.login),
        child: Text(
          tr(
            lang,
            'Já tenho uma conta',
            'I already have an account',
            'Ya tengo una cuenta',
          ),
        ),
      ),
      onSubmit: () {
        signedIn = true;
        role = 'buyer';
        _snack(tr(lang, 'Conta criada com sucesso!', 'Account created successfully!', '¡Cuenta creada con éxito!'));
        if (_checkoutAfterAuth) {
          _checkoutAfterAuth = false;
          go(Page.checkout);
        } else {
          go(Page.home);
        }
      },
    );
  }

  Widget _artisanSignup() {
    return _formPage(
      title: tr(
        lang,
        'Inscreva-se no programa exclusivo',
        'Apply to the exclusive program',
        'Inscríbete en el programa exclusivo',
      ),
      subtitle: tr(
        lang,
        'Somente para mulheres artesãs de Heliópolis. Nossa equipe entra em contato após o cadastro.',
        'Only for women artisans from Heliópolis. Our team will contact you after registration.',
        'Solo para mujeres artesanas de Heliópolis. Nuestro equipo se pondrá en contacto tras el registro.',
      ),
      fields: [
        'Nome',
        'WhatsApp',
        'E-mail',
        'Instagram',
        'Endereço',
        'Produto principal',
      ],
      button: tr(lang, 'Inscrever', 'Apply', 'Inscribirme'),
      footer: TextButton(
        onPressed: () => go(Page.home),
        child: Text(
          tr(
            lang,
            'Voltar para o início',
            'Back to home',
            'Volver al inicio',
          ),
        ),
      ),
      onSubmit: () {
        signedIn = true;
        role = 'artisan';
        artisanSection = ArtisanSection.overview;
        _snack(
          tr(
            lang,
            'Cadastro recebido! Nossa equipe entrará em contato.',
            'Registration received! Our team will contact you.',
            '¡Registro recibido! Nuestro equipo se pondrá en contacto.',
          ),
        );
        go(Page.artisan);
      },
    );
  }

  Widget _formPage({
    required String title,
    required String subtitle,
    required List<String> fields,
    required String button,
    required Widget footer,
    required VoidCallback onSubmit,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 55),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 42,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: _fg,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _dim,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 30),
              ...fields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: TextFormField(
                    obscureText: f.toLowerCase().contains('senha'),
                    decoration: InputDecoration(
                      labelText: f,
                      filled: true,
                      fillColor: _card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _border),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  child: Text(button),
                ),
              ),
              const SizedBox(height: 15),
              Center(child: footer),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARRINHO
  // ============================================================

  Widget _cartPage() {
    final selected = <int>[];
    for (final i in cartItems) {
      if (!selected.contains(i)) selected.add(i);
    }

    final total = cartItems.fold<double>(
      0,
      (sum, i) => sum + _priceValue(_products[i]['price']!),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 38, 28, 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => go(Page.products),
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  tr(lang, 'Continuar comprando', 'Continue shopping', 'Seguir comprando'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr(lang, 'Meu carrinho', 'My cart', 'Mi carrito'),
                style: const TextStyle(
                  color: _fg,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cartItems.isEmpty
                    ? tr(
                        lang,
                        'Você ainda não selecionou nenhuma peça.',
                        'You have not selected any pieces yet.',
                        'Todavía no has seleccionado ninguna pieza.',
                      )
                    : tr(
                        lang,
                        '${cartItems.length} ${cartItems.length == 1 ? 'item selecionado' : 'itens selecionados'}',
                        '${cartItems.length} ${cartItems.length == 1 ? 'selected item' : 'selected items'}',
                        '${cartItems.length} ${cartItems.length == 1 ? 'artículo seleccionado' : 'artículos seleccionados'}',
                      ),
                style: const TextStyle(color: _dim, fontSize: 14),
              ),
              const SizedBox(height: 28),

              if (cartItems.isEmpty)
                _emptyCart()
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _card,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: selected
                        .map((i) => _cartItem(i))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                if (_fxDate.isNotEmpty)
                  Text(
                    tr(
                      lang,
                      'Cotação diária atualizada em $_fxDate • preços exibidos em BRL.',
                      'Daily exchange rate updated on $_fxDate • prices shown in USD.',
                      'Cotización diaria actualizada el $_fxDate • precios mostrados en EUR.',
                    ),
                    style: const TextStyle(color: _dim, fontSize: 11),
                  ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _card,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr(lang, 'Total', 'Total', 'Total'),
                        style: const TextStyle(
                          color: _fg,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _money(total),
                        style: const TextStyle(
                          color: _fg,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openCheckout,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(
                      tr(lang, 'Finalizar compra', 'Checkout', 'Finalizar compra'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),
              _cartSuggestions(selected),
            ],
          ),
        ),
      ),
    );
  }

  void _openCheckout() {
    if (cartItems.isEmpty) {
      _snack(
        tr(
          lang,
          'Seu carrinho está vazio.',
          'Your cart is empty.',
          'Tu carrito está vacío.',
        ),
      );
      return;
    }
    go(Page.checkout);
  }

  Future<void> _showCheckoutLoginDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: .48),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 24, 30, 28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                    Text(
                      tr(lang, 'Já sou cliente / Entrar', 'Sign in', 'Ya soy cliente / Entrar'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _fg,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 16, color: Color(0xFF15945E)),
                        const SizedBox(width: 5),
                        Text(
                          tr(lang, 'Seus dados estão protegidos.', 'Your data is protected.', 'Tus datos están protegidos.'),
                          style: const TextStyle(color: Color(0xFF15945E), fontSize: 12.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr(lang, 'Número de celular ou E-mail:', 'Phone number or Email:', 'Número de celular o correo:'),
                        style: const TextStyle(color: _dim, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 7),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: tr(lang, 'Senha', 'Password', 'Contraseña'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (emailController.text.trim().isEmpty) {
                            _snack(tr(lang, 'Digite seu e-mail ou celular.', 'Enter your email or phone.', 'Ingresa tu correo o celular.'));
                            return;
                          }
                          setState(() {
                            signedIn = true;
                            role = 'buyer';
                          });
                          Navigator.of(dialogContext).pop();
                          _snack(tr(lang, 'Login realizado! Seus dados do checkout continuam salvos.', 'Signed in! Your checkout data is preserved.', '¡Sesión iniciada! Tus datos del checkout se mantienen.'));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _fg,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          tr(lang, 'CONTINUAR', 'CONTINUE', 'CONTINUAR'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () {},
                      child: Text(tr(lang, 'Não consegue acessar sua conta?', 'Can’t access your account?', '¿No puedes acceder a tu cuenta?')),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(tr(lang, 'Ou', 'Or', 'O'), style: const TextStyle(color: Colors.grey)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          signedIn = true;
                          role = 'buyer';
                        });
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      label: Text(tr(lang, 'Prosseguir com Google', 'Continue with Google', 'Continuar con Google')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        foregroundColor: _fg,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          signedIn = true;
                          role = 'buyer';
                        });
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Icon(Icons.facebook, color: Color(0xFF4054B2)),
                      label: Text(tr(lang, 'Prosseguir com Facebook', 'Continue with Facebook', 'Continuar con Facebook')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        foregroundColor: _fg,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      tr(lang, 'Ao continuar, você concorda com nossa Política de Privacidade e Termos e condições.', 'By continuing, you agree to our Privacy Policy and Terms and Conditions.', 'Al continuar, aceptas nuestra Política de Privacidad y Términos y condiciones.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _dim, fontSize: 11.5, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
  }

  Widget _checkoutPage() {
    final total = cartItems.fold<double>(
      0,
      (sum, i) => sum + _priceValue(_products[i]['price']!),
    );

    final selected = <int>[];
    for (final i in cartItems) {
      if (!selected.contains(i)) selected.add(i);
    }

    return _CheckoutPage(
      language: lang,
      itemIndexes: selected,
      total: total,
      quantityFor: cartQuantity,
      brlToUsd: _brlToUsd,
      brlToEur: _brlToEur,
      signedIn: signedIn,
      onRequestLogin: _showCheckoutLoginDialog,
      onRequestSignup: () {
        _checkoutAfterAuth = true;
        go(Page.accountSignup);
      },
      onBack: () => go(Page.cart),
      onFinished: () {
        cartItems.clear();
        _snack(
          tr(
            lang,
            'Pedido recebido! Obrigada pela compra.',
            'Order received! Thank you for your purchase.',
            '¡Pedido recibido! Gracias por tu compra.',
          ),
        );
        go(Page.home);
      },
    );
  }

  Widget _emptyCart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F0EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: _primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr(lang, 'Seu carrinho está vazio', 'Your cart is empty', 'Tu carrito está vacío'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _fg,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            tr(
              lang,
              'Que tal descobrir algumas peças feitas à mão por nossas artesãs?',
              'How about discovering some handmade pieces from our artisans?',
              '¿Qué tal descubrir algunas piezas hechas a mano por nuestras artesanas?',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _dim,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartItem(int i) {
    final p = _products[i];
    final quantity = cartQuantity(i);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              p['image']!,
              width: 105,
              height: 105,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 105,
                height: 105,
                color: _muted,
                child: const Icon(Icons.image_outlined),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['category']!.toUpperCase(),
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  p['name']!,
                  style: const TextStyle(
                    color: _fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tr(lang, 'por', 'by', 'por')} ${p['artisan']}',
                  style: const TextStyle(color: _dim, fontSize: 12),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text(
                      _money(_priceValue(p['price']!)),
                      style: const TextStyle(
                        color: _fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _muted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x$quantity',
                        style: const TextStyle(
                          color: _fg,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: tr(lang, 'Remover', 'Remove', 'Eliminar'),
            onPressed: () => removeCartItem(i),
            icon: const Icon(Icons.delete_outline),
            color: _accent,
          ),
        ],
      ),
    );
  }

  Widget _cartSuggestions(List<int> selected) {
    final suggestions = List.generate(_products.length, (i) => i)
        .where((i) => !selected.contains(i))
        .take(4)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(
            lang,
            cartItems.isEmpty ? 'Você pode gostar destas peças' : 'Continue descobrindo',
            cartItems.isEmpty ? 'You may like these pieces' : 'Keep discovering',
            cartItems.isEmpty ? 'Estas piezas podrían gustarte' : 'Sigue descubriendo',
          ),
          style: const TextStyle(
            color: _fg,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          tr(
            lang,
            'Sugestões de artesãs da nossa comunidade.',
            'Suggestions from artisans in our community.',
            'Sugerencias de artesanas de nuestra comunidad.',
          ),
          style: const TextStyle(color: _dim),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (_, c) {
            final n = c.maxWidth > 900
                ? 4
                : c.maxWidth > 600
                    ? 2
                    : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: n,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: .78,
              ),
              itemBuilder: (_, i) => _cartSuggestionCard(suggestions[i]),
            );
          },
        ),
      ],
    );
  }

  Widget _cartSuggestionCard(int i) {
    final p = _products[i];

    return Card(
      color: _card,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              p['image']!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _muted,
                child: const Icon(Icons.image_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _money(_priceValue(p['price']!)),
                      style: const TextStyle(
                        color: _fg,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      tooltip: tr(lang, 'Adicionar', 'Add', 'Añadir'),
                      onPressed: () => addCart(i),
                      icon: const Icon(Icons.add_shopping_cart),
                      color: _primary,
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

  // ============================================================
  // CONTA DO COMPRADOR
  // ============================================================

  Widget _buyer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      tr(lang, 'Minha conta', 'My account', 'Mi cuenta'),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: _fg,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      signedIn = false;
                      role = 'buyer';
                      go(Page.home);
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(
                      tr(lang, 'Sair', 'Sign out', 'Salir'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _accountTile(
                    Icons.receipt_long_outlined,
                    tr(lang, 'Meus pedidos', 'My orders', 'Mis pedidos'),
                    '2',
                  ),
                  InkWell(
                    onTap: _openCart,
                    borderRadius: BorderRadius.circular(12),
                    child: _accountTile(
                      Icons.shopping_cart_outlined,
                      tr(lang, 'Carrinho', 'Cart', 'Carrito'),
                      '${cartItems.length}',
                    ),
                  ),
                  _accountTile(
                    Icons.favorite_border,
                    tr(lang, 'Favoritos', 'Favorites', 'Favoritos'),
                    '${favorites.length}',
                  ),
                  _accountTile(
                    Icons.settings_outlined,
                    tr(lang, 'Configurações', 'Settings', 'Configuración'),
                    '',
                  ),
                ],
              ),
              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _card,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(
                        lang,
                        'Seus próximos passos',
                        'Your next steps',
                        'Tus próximos pasos',
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _fg,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(
                        lang,
                        'Explore o catálogo, salve seus favoritos e acompanhe suas compras por aqui.',
                        'Explore the catalogue, save favorites and track your purchases here.',
                        'Explora el catálogo, guarda favoritos y sigue tus compras aquí.',
                      ),
                      style: const TextStyle(
                        color: _dim,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () => go(Page.products),
                      child: Text(
                        tr(
                          lang,
                          'Ir para a loja',
                          'Go to store',
                          'Ir a la tienda',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      width: 235,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _fg,
                  ),
                ),
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: const TextStyle(
                      color: _dim,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAINEL DA ARTESÃ
  // ============================================================

  Widget _artisan() {
    final items = {
      'Visão geral': ArtisanSection.overview,
      'Pedidos': ArtisanSection.orders,
      'Mensagens': ArtisanSection.messages,
      'Minha vitrine': ArtisanSection.products,
      'Vendas': ArtisanSection.sales,
      'Alcançar o mundo': ArtisanSection.export,
      'Ajuda': ArtisanSection.help,
      'Configurações': ArtisanSection.settings,
    };

    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width > 850)
            Container(
              width: 260,
              color: const Color(0xFFFBF5E9),
              padding: const EdgeInsets.fromLTRB(20, 35, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/image/logo-mulheres-artesas-heliopolis.png',
                    width: 170,
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'Bem-vinda de volta,',
                    style: TextStyle(color: _dim),
                  ),
                  const Text(
                    'Maria!',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: _fg,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: items.entries
                          .map((e) => _side(e.key, e.value))
                          .toList(),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => go(Page.home),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair da conta'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 70),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _artisanTop(),
                      _artisanContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _side(String label, ArtisanSection s) {
    return ListTile(
      selected: artisanSection == s,
      selectedTileColor: const Color(0xFFE2F0EC),
      leading: const Icon(
        Icons.circle_outlined,
        size: 17,
      ),
      title: Text(label),
      onTap: () {
        setState(() => artisanSection = s);
      },
    );
  }

  Widget _artisanTop() {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _sectionLabel(),
          style: const TextStyle(
            color: _primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _sectionTitleArtisan(),
          style: const TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.w800,
            color: _fg,
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(
              () => artisanSection = ArtisanSection.export,
            );
          },
          icon: const Icon(Icons.public),
          label: const Text('Exportação'),
        ),
        ElevatedButton.icon(
          onPressed: () => _snack('Produto salvo!'),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar produto'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (_, c) {
        return c.maxWidth < 620
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 16),
                  actions,
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(child: title),
                  const SizedBox(width: 16),
                  actions,
                ],
              );
      },
    );
  }

  String _sectionLabel() {
    return artisanSection == ArtisanSection.overview
        ? 'UM BOM DIA PARA CRIAR'
        : 'PAINEL DA ARTESÃ';
  }

  String _sectionTitleArtisan() {
    return {
          ArtisanSection.overview: 'Olá, Maria!',
          ArtisanSection.orders: 'Pedidos',
          ArtisanSection.messages: 'Mensagens',
          ArtisanSection.products: 'Minha vitrine',
          ArtisanSection.sales: 'Vendas',
          ArtisanSection.export: 'Alcançar o mundo',
          ArtisanSection.help: 'Ajuda e suporte',
          ArtisanSection.settings: 'Configurações',
        }[artisanSection] ??
        'Painel';
  }

  Widget _artisanContent() {
    switch (artisanSection) {
      case ArtisanSection.overview:
        return _artisanOverview();
      case ArtisanSection.orders:
        return _artisanOrders();
      case ArtisanSection.messages:
        return _artisanMessages();
      case ArtisanSection.products:
        return _artisanProducts();
      case ArtisanSection.sales:
        return _artisanSales();
      case ArtisanSection.export:
        return _artisanExport();
      case ArtisanSection.help:
        return _artisanHelp();
      case ArtisanSection.settings:
        return _artisanSettings();
    }
  }

  Widget _artisanOverview() {
    return Column(
      children: [
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F0EA),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Row(
            children: [
              Icon(Icons.public, color: _primary),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Seu feito à mão pode cruzar fronteiras. Conte a história da sua peça. A gente ajuda com idioma, frete e os próximos passos.',
                  style: TextStyle(
                    color: _fg,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat(
              'Produtos ativos',
              '12',
              '+2 este mês',
              ArtisanSection.products,
            ),
            _stat(
              'Pedidos',
              '4',
              '2 aguardando envio',
              ArtisanSection.orders,
            ),
            _stat(
              'Vendas no mês',
              _money(1240),
              '+18% que no mês passado',
              ArtisanSection.sales,
            ),
            _stat(
              'Mensagens',
              '2',
              'de compradores',
              ArtisanSection.messages,
            ),
          ],
        ),
        const SizedBox(height: 30),
        _panel('Pedidos recentes', _orderList()),
      ],
    );
  }

  Widget _stat(
    String a,
    String b,
    String c,
    ArtisanSection target,
  ) {
    return InkWell(
      onTap: () {
        setState(() => artisanSection = target);
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a,
              style: const TextStyle(
                color: _dim,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              b,
              style: const TextStyle(
                color: _fg,
                fontWeight: FontWeight.w900,
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              c,
              style: const TextStyle(
                color: _primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _fg,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _orderList() {
    final orders = [
      ['#HLP-2408', 'Cesta Trançada Sol', 'Ana Clara', 'R\$ 85'],
      ['#HLP-2397', 'Colar Raízes', 'Camila M.', 'R\$ 120'],
      ['#HLP-2379', 'Boneca Abayomi', 'Sofia R.', 'R\$ 95'],
      ['#HLP-2364', 'Kit Casa', 'Marina L.', 'R\$ 210'],
    ];

    return Column(
      children: orders
          .map(
            (o) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE2F0EC),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: _primary,
                  size: 19,
                ),
              ),
              title: Text(
                o[1],
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text('${o[0]} · ${o[2]}'),
              trailing: Text(
                _money(_priceValue(o[3])),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _artisanOrders() {
    return _panel('Pedidos', _orderList());
  }

  Widget _artisanMessages() {
    final messages = [
      [
        'Camila M.',
        'Dúvida sobre o prazo',
        'Olá, Maria! Você consegue enviar o Colar Raízes ainda esta semana?',
      ],
      [
        'Ana Clara',
        'Pedido #HLP-2408',
        'Estou ansiosa para receber minha cesta. Obrigada pelo cuidado!',
      ],
      [
        'Equipe Artesãs',
        'Sua vitrine está linda',
        'Uma dica: fotos com luz natural recebem mais visitas.',
      ],
    ];

    return _panel(
      'Mensagens',
      Column(
        children: messages
            .map(
              (m) => ListTile(
                leading: CircleAvatar(
                  child: Text(m[0][0]),
                ),
                title: Text(
                  m[1],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(m[2]),
                trailing: const Icon(Icons.chevron_right),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _artisanProducts() {
    return Column(
      children: [
        _panel(
          'Minha vitrine',
          LayoutBuilder(
            builder: (_, c) {
              final n = c.maxWidth > 700
                  ? 3
                  : c.maxWidth > 420
                      ? 2
                      : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: n,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: .75,
                children: _products
                    .take(4)
                    .map(
                      (p) => Card(
                        color: _card,
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.network(
                                p['image']!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: _muted,
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['category']!,
                                    style: const TextStyle(
                                      color: _primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    p['name']!,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    _money(_priceValue(p['price']!)),
                                    style: const TextStyle(
                                      color: _dim,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  OutlinedButton(
                                    onPressed: () => _snack(
                                      'Edição de produto em breve — seu produto já está salvo.',
                                    ),
                                    child: const Text(
                                      'Editar produto',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _artisanSales() {
    return Column(
      children: [
        _panel(
          'Vendas no mês',
          const SizedBox(
            height: 190,
            child: Center(
              child: Icon(
                Icons.show_chart,
                size: 80,
                color: _primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        _panel(
          'Resumo',
          Column(
            children: [
              ListTile(
                title: Text('Receita'),
                trailing: Text(_money(1240)),
              ),
              ListTile(
                title: Text('Pedidos concluídos'),
                trailing: Text('8'),
              ),
              ListTile(
                title: Text('Ticket médio'),
                trailing: Text(_money(155)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _artisanExport() {
    return _panel(
      'Alcançar o mundo',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seu produto pode chegar a compradores internacionais. Organize fotos, descrição, materiais, custos e documentação.',
            style: TextStyle(
              color: _dim,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          ...[
            '1. Prepare sua vitrine',
            '2. Calcule custos e frete',
            '3. Revise documentação',
            '4. Escolha mercados',
            '5. Converse com compradores',
          ].map(
            (x) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE2F0EC),
                child: Icon(
                  Icons.check,
                  color: _primary,
                  size: 17,
                ),
              ),
              title: Text(
                x,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _artisanHelp() {
    return _panel(
      'Ajuda e suporte',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encontre respostas para dúvidas sobre cadastro, produtos, pedidos e exportação.',
            style: TextStyle(
              color: _dim,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 15),
          ...[
            'Como cadastrar um produto?',
            'Como acompanhar um pedido?',
            'Como preparar uma exportação?',
            'Como falar com o suporte?',
          ].map(
            (x) => ExpansionTile(
              title: Text(x),
              children: const [
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    'Nossa equipe pode orientar você pelo canal de suporte da plataforma.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artisanSettings() {
    return _panel(
      'Configurações',
      Column(
        children: [
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text(
              'Receber mensagens de compradores',
            ),
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text(
              'Receber avisos de pedidos',
            ),
          ),
          ListTile(
            title: const Text('Idioma'),
            trailing: Text(
              lang == Lang.pt
                  ? 'Português'
                  : lang == Lang.en
                      ? 'English'
                      : 'Español',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCUMENTOS
  // ============================================================

  Widget _legal() {
    final data = {
      LegalDoc.terms: [
        'Termos de Uso',
        'DOCUMENTO DA PLATAFORMA',
        'Estes termos definem as regras para usar a plataforma, comprar produtos e participar do programa de artesãs.',
      ],
      LegalDoc.privacy: [
        'Política de Privacidade',
        'PROTEÇÃO DE DADOS',
        'Este documento explica quais dados são usados para criar contas, processar pedidos, oferecer suporte e manter a segurança da plataforma.',
      ],
      LegalDoc.cookies: [
        'Política de Cookies',
        'TRANSPARÊNCIA DIGITAL',
        'Cookies e tecnologias semelhantes ajudam a manter a sessão, lembrar preferências e entender como a plataforma é utilizada.',
      ],
      LegalDoc.commerce: [
        'Compras, Trocas e Vendas',
        'REGRAS DA EXPERIÊNCIA',
        'Regras claras ajudam compradores e artesãs a negociar com segurança e previsibilidade.',
      ],
      LegalDoc.community: [
        'Diretrizes da Comunidade',
        'CONVIVÊNCIA E RESPEITO',
        'A plataforma existe para valorizar o trabalho das artesãs e promover relações comerciais respeitosas.',
      ],
    }[legalDoc]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 45),
              TextButton.icon(
                onPressed: () => go(Page.home),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
              const SizedBox(height: 30),
              Text(
                data[1],
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data[0],
                style: const TextStyle(
                  color: _fg,
                  fontSize: 45,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                data[2],
                style: const TextStyle(
                  color: _dim,
                  height: 1.7,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 30),
              ..._legalSections(legalDoc).map(
                (x) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _card,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        x.$1,
                        style: const TextStyle(
                          color: _fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        x.$2,
                        style: const TextStyle(
                          color: _dim,
                          height: 1.65,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  List<(String, String)> _legalSections(LegalDoc d) {
    return {
      LegalDoc.terms: [
        (
          'Uso da plataforma',
          'A plataforma conecta compradores e artesãs. Cada pessoa deve fornecer informações verdadeiras, proteger suas credenciais e usar o serviço de forma legal e respeitosa.',
        ),
        (
          'Compras e pagamentos',
          'Os detalhes de preço, prazo, disponibilidade, entrega, troca e reembolso devem ser apresentados antes da confirmação.',
        ),
        (
          'Conteúdo e responsabilidade',
          'Cada artesã é responsável por seus produtos, descrições, fotos e informações publicadas.',
        ),
      ],
      LegalDoc.privacy: [
        (
          'Dados coletados',
          'Podemos tratar nome, e-mail, telefone, endereço e dados necessários para o cadastro e atendimento.',
        ),
        (
          'Finalidades',
          'Usamos os dados para autenticar contas, processar compras, acompanhar entregas e responder solicitações.',
        ),
        (
          'Direitos',
          'Você pode solicitar confirmação, acesso, correção, atualização ou exclusão dos seus dados, observadas as hipóteses legais.',
        ),
      ],
      LegalDoc.cookies: [
        (
          'Cookies necessários',
          'São usados para segurança, funcionamento do login, carrinho e navegação.',
        ),
        (
          'Preferências e métricas',
          'Preferências de idioma e métricas agregadas podem ser usadas para melhorar a experiência.',
        ),
        (
          'Controle',
          'Você pode bloquear ou apagar cookies nas configurações do navegador.',
        ),
      ],
      LegalDoc.commerce: [
        (
          'Pedido e confirmação',
          'O comprador deve revisar itens, endereço, frete e valor total antes de finalizar.',
        ),
        (
          'Envio e acompanhamento',
          'A artesã atualiza o status do pedido e informa o envio.',
        ),
        (
          'Troca e reembolso',
          'Solicitações serão analisadas conforme a legislação brasileira aplicável e as condições do produto.',
        ),
      ],
      LegalDoc.community: [
        (
          'Respeito',
          'Não são permitidos assédio, discriminação, ameaças, conteúdo ilegal ou tentativas de constranger outros usuários.',
        ),
        (
          'Autenticidade',
          'Produtos, histórias, fotos e avaliações devem ser verdadeiros.',
        ),
        (
          'Moderação',
          'Podemos remover conteúdo e suspender acessos quando houver violação das diretrizes.',
        ),
      ],
    }[d]!;
  }
}


class _CheckoutPage extends StatefulWidget {
  final Lang language;
  final List<int> itemIndexes;
  final double total;
  final int Function(int) quantityFor;
  final double brlToUsd;
  final double brlToEur;
  final bool signedIn;
  final VoidCallback onRequestLogin;
  final VoidCallback onRequestSignup;
  final VoidCallback onBack;
  final VoidCallback onFinished;

  const _CheckoutPage({
    required this.language,
    required this.itemIndexes,
    required this.total,
    required this.quantityFor,
    required this.brlToUsd,
    required this.brlToEur,
    required this.signedIn,
    required this.onRequestLogin,
    required this.onRequestSignup,
    required this.onBack,
    required this.onFinished,
  });

  @override
  State<_CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<_CheckoutPage> {
  int? _accessChoice;
  String _payment = 'pix';

  @override
  void initState() {
    super.initState();
    if (widget.signedIn) {
      _accessChoice = 3;
    }
  }

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cep = TextEditingController();
  final _address = TextEditingController();
  final _number = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _cardNumber = TextEditingController();
  final _cardName = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _cep,
      _address,
      _number,
      _city,
      _state,
      _cardNumber,
      _cardName,
      _expiry,
      _cvv,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _rate() => widget.language == Lang.pt
      ? 1
      : widget.language == Lang.en
          ? widget.brlToUsd
          : widget.brlToEur;

  String _money(double brlValue) {
    final value = brlValue * _rate();
    final formatted = value.toStringAsFixed(2);
    if (widget.language == Lang.pt) {
      return 'R\$ ${formatted.replaceAll('.', ',')}';
    }
    if (widget.language == Lang.en) {
      return 'US\$ $formatted';
    }
    return '€ $formatted'.replaceAll('.', ',');
  }

  String _tr(String pt, String en, String es) =>
      tr(widget.language, pt, en, es);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  _tr(
                    'Voltar ao carrinho',
                    'Back to cart',
                    'Volver al carrito',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tr('Finalizar compra', 'Checkout', 'Finalizar compra'),
                style: const TextStyle(
                  color: _fg,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _tr(
                  widget.signedIn
                      ? 'Seus dados estão prontos. Confira as informações e finalize seu pedido.'
                      : 'Escolha como deseja continuar. Você pode comprar com ou sem conta.',
                  widget.signedIn
                      ? 'Your account is ready. Check your details and complete your order.'
                      : 'Choose how you want to continue. You can shop with or without an account.',
                  widget.signedIn
                      ? 'Tus datos están listos. Revisa la información y finaliza tu pedido.'
                      : 'Elige cómo quieres continuar. Puedes comprar con o sin cuenta.',
                ),
                style: const TextStyle(color: _dim, fontSize: 14),
              ),
              const SizedBox(height: 26),
              _progress(),
              const SizedBox(height: 26),
              if (!widget.signedIn)
                _sectionCard(
                  title: _tr(
                    '1. Como você quer comprar?',
                  '1. How would you like to buy?',
                  '1. ¿Cómo quieres comprar?',
                ),
                child: LayoutBuilder(
                  builder: (_, c) {
                    final count = c.maxWidth > 800 ? 3 : 1;
                    return GridView.count(
                      crossAxisCount: count,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: desktop ? 2.7 : 2.2,
                      children: [
                        _choiceCard(
                          0,
                          Icons.login_outlined,
                          _tr(
                            'Entrar na minha conta',
                            'Sign in to my account',
                            'Entrar en mi cuenta',
                          ),
                          _tr(
                            'Use seus dados salvos.',
                            'Use your saved details.',
                            'Usa tus datos guardados.',
                          ),
                        ),
                        _choiceCard(
                          1,
                          Icons.person_add_alt_1_outlined,
                          _tr(
                            'Criar uma conta',
                            'Create an account',
                            'Crear una cuenta',
                          ),
                          _tr(
                            'Acompanhe seus pedidos depois.',
                            'Track your orders later.',
                            'Sigue tus pedidos después.',
                          ),
                        ),
                        _choiceCard(
                          2,
                          Icons.shopping_bag_outlined,
                          _tr(
                            'Comprar sem conta',
                            'Continue as guest',
                            'Comprar sin cuenta',
                          ),
                          _tr(
                            'Mais rápido, sem cadastro.',
                            'Faster, no registration.',
                            'Más rápido, sin registro.',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_accessChoice != null) ...[
                const SizedBox(height: 18),
                _sectionCard(
                  title: _tr(
                    widget.signedIn ? '1. Seus dados' : '2. Seus dados',
                    widget.signedIn ? '1. Your details' : '2. Your details',
                    widget.signedIn ? '1. Tus datos' : '2. Tus datos',
                  ),
                  child: Column(
                    children: [
                      _fieldRow([
                        _field(_name, _tr('Nome completo', 'Full name', 'Nombre completo')),
                        _field(_email, _tr('E-mail', 'Email', 'Correo electrónico')),
                      ]),
                      const SizedBox(height: 12),
                      _fieldRow([
                        _field(_phone, _tr('Telefone / WhatsApp', 'Phone / WhatsApp', 'Teléfono / WhatsApp')),
                        _field(_cep, _tr('CEP', 'ZIP code', 'Código postal')),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _sectionCard(
                  title: _tr(
                    widget.signedIn ? '2. Endereço de entrega' : '3. Endereço de entrega',
                    widget.signedIn ? '2. Delivery address' : '3. Delivery address',
                    widget.signedIn ? '2. Dirección de entrega' : '3. Dirección de entrega',
                  ),
                  child: Column(
                    children: [
                      _fieldRow([
                        _field(_address, _tr('Rua / Avenida', 'Street / Avenue', 'Calle / Avenida')),
                        _field(_number, _tr('Número', 'Number', 'Número')),
                      ]),
                      const SizedBox(height: 12),
                      _fieldRow([
                        _field(_city, _tr('Cidade', 'City', 'Ciudad')),
                        _field(_state, _tr('Estado', 'State', 'Estado')),
                      ]),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _tr(
                            'O endereço será usado somente para a entrega deste pedido.',
                            'This address will only be used for delivery of this order.',
                            'Esta dirección se utilizará únicamente para entregar este pedido.',
                          ),
                          style: const TextStyle(
                            color: _dim,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _sectionCard(
                  title: _tr(
                    widget.signedIn ? '3. Forma de pagamento' : '4. Forma de pagamento',
                    widget.signedIn ? '3. Payment method' : '4. Payment method',
                    widget.signedIn ? '3. Método de pago' : '4. Método de pago',
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'pix',
                        groupValue: _payment,
                        onChanged: (v) => setState(() => _payment = v!),
                        title: const Text(
                          'PIX',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          _tr(
                            'Pagamento rápido e seguro.',
                            'Fast and secure payment.',
                            'Pago rápido y seguro.',
                          ),
                        ),
                        secondary: const Icon(Icons.pix_outlined, color: _primary),
                      ),
                      RadioListTile<String>(
                        value: 'card',
                        groupValue: _payment,
                        onChanged: (v) => setState(() => _payment = v!),
                        title: Text(
                          _tr(
                            'Cartão',
                            'Card',
                            'Tarjeta',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          _tr(
                            'Crédito ou débito.',
                            'Credit or debit.',
                            'Crédito o débito.',
                          ),
                        ),
                        secondary: const Icon(Icons.credit_card_outlined, color: _primary),
                      ),
                      if (_payment == 'card') ...[
                        const Divider(height: 20),
                        _fieldRow([
                          _field(_cardNumber, _tr('Número do cartão', 'Card number', 'Número de tarjeta')),
                          _field(_cardName, _tr('Nome no cartão', 'Name on card', 'Nombre en la tarjeta')),
                        ]),
                        const SizedBox(height: 12),
                        _fieldRow([
                          _field(_expiry, _tr('Validade', 'Expiry', 'Vencimiento')),
                          _field(_cvv, 'CVV'),
                        ]),
                      ],
                      if (_payment == 'pix')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2EE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, color: _primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _tr(
                                    'A chave/QR Code do PIX será exibido na próxima etapa.',
                                    'The PIX key/QR Code will be shown in the next step.',
                                    'La clave/QR Code de PIX se mostrará en el siguiente paso.',
                                  ),
                                  style: const TextStyle(
                                    color: _fg,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _summary(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onFinished,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(
                      _tr(
                        'Confirmar pedido',
                        'Place order',
                        'Confirmar pedido',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _tr(
                      '🔒 Seus dados de pagamento devem ser processados por um provedor de pagamento seguro.',
                      '🔒 Payment details should be processed by a secure payment provider.',
                      '🔒 Los datos de pago deben ser procesados por un proveedor de pagos seguro.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _dim,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _progress() {
    return Row(
      children: [
        _stepDot('1', _tr('Acesso', 'Access', 'Acceso'), true),
        Expanded(child: Container(height: 1, color: _border)),
        _stepDot('2', _tr('Dados', 'Details', 'Datos'), widget.signedIn || _accessChoice != null),
        Expanded(child: Container(height: 1, color: _border)),
        _stepDot('3', _tr('Pagamento', 'Payment', 'Pago'), widget.signedIn || _accessChoice != null),
      ],
    );
  }

  Widget _stepDot(String number, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? _primary : _muted,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : _dim,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: _dim,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _choiceCard(int value, IconData icon, String title, String subtitle) {
    final selected = _accessChoice == value;
    return InkWell(
      onTap: () {
        setState(() => _accessChoice = value);
        if (value == 0) {
          widget.onRequestLogin();
        } else if (value == 1) {
          widget.onRequestSignup();
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5F1ED) : _card,
          border: Border.all(
            color: selected ? _primary : _border,
            width: selected ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _primary : _dim, size: 27),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _dim,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? _primary : _border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _fg,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
      ),
    );
  }

  Widget _fieldRow(List<Widget> fields) {
    return LayoutBuilder(
      builder: (_, c) {
        if (c.maxWidth < 650) {
          return Column(
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                fields[i],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: fields[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _summary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1DFC6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tr('Resumo da compra', 'Order summary', 'Resumen de compra'),
                style: const TextStyle(
                  color: _fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _money(widget.total),
                style: const TextStyle(
                  color: _fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.itemIndexes.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_products[i]['name']} × ${widget.quantityFor(i)}',
                      style: const TextStyle(
                        color: _dim,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _money(
                      double.parse(
                            _products[i]['price']!
                                .replaceAll('R\$', '')
                                .replaceAll('.', '')
                                .replaceAll(',', '.')
                                .trim(),
                          ) *
                          widget.quantityFor(i),
                    ),
                    style: const TextStyle(
                      color: _fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _ChatDialog extends StatefulWidget {
  final Lang language;
  final SupportApi api;

  const _ChatDialog({required this.language, required this.api});

  @override
  State<_ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<_ChatDialog> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late final List<_ChatMessage> _messages;
  bool _typing = false;

  String get _welcome => tr(
        widget.language,
        'Olá! Eu sou a assistente virtual das Artesãs de Heliópolis. Posso ajudar com cadastro, produtos, compras, pedidos, pagamentos, exportação e outras dúvidas da plataforma. Como posso ajudar?',
        'Hello! I am the virtual assistant for Artesãs de Heliópolis. I can help with registration, products, purchases, orders, payments, exporting and other platform questions. How can I help?',
        '¡Hola! Soy la asistente virtual de Artesãs de Heliópolis. Puedo ayudarte con registro, productos, compras, pedidos, pagos, exportación y otras dudas de la plataforma. ¿Cómo puedo ayudarte?',
      );

  List<String> get _quickQuestions => [
        tr(widget.language, 'Como faço meu cadastro?', 'How do I register?', '¿Cómo me registro?'),
        tr(widget.language, 'Meu pedido não chegou', 'My order did not arrive', 'Mi pedido no llegó'),
        tr(widget.language, 'Quero cadastrar um produto', 'I want to add a product', 'Quiero publicar un producto'),
        tr(widget.language, 'Quero exportar meus produtos', 'I want to export my products', 'Quiero exportar mis productos'),
      ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _messages = [_ChatMessage(text: _welcome, isUser: false)];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _typing) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _typing = true;
    });
    _scrollToBottom();

    try {
      final reply = await widget.api.sendMessage(
        language: switch (widget.language) {
          Lang.pt => 'pt',
          Lang.en => 'en',
          Lang.es => 'es',
        },
        messages: _messages
            .where((m) => m.text.isNotEmpty)
            .map((m) => SupportChatMessage(
                  role: m.isUser ? 'user' : 'assistant',
                  content: m.text,
                ))
            .toList(),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _typing = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: tr(
              widget.language,
              'Não consegui conectar ao assistente agora. Verifique se o servidor de atendimento está ligado. Se o problema continuar, use o suporte da plataforma.',
              'I could not connect to the assistant right now. Please check that the support server is running. If the problem continues, contact platform support.',
              'No pude conectarme al asistente ahora. Comprueba que el servidor de atención esté encendido. Si el problema continúa, contacta al soporte de la plataforma.',
            ),
            isUser: false,
          ),
        );
        _typing = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final dialogWidth = width < 700 ? width - 28 : 470.0;
    final dialogHeight = height < 700 ? height - 40 : 650.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Material(
          color: _card,
          elevation: 20,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _chatHeader(),
              Expanded(child: _chatBody()),
              _chatComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: const BoxDecoration(color: _primary),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/image/logo-mulheres-artesas-heliopolis.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(widget.language, 'Assistente Artesãs', 'Artisans Assistant', 'Asistente Artesanas'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB9F6CA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr(widget.language, 'Online • PT / EN / ES', 'Online • PT / EN / ES', 'En línea • PT / EN / ES'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: tr(widget.language, 'Fechar', 'Close', 'Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _chatBody() {
    return Container(
      color: _bg,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        children: [
          Text(
            tr(widget.language, 'Como posso ajudar?', 'How can I help?', '¿Cómo puedo ayudarte?'),
            style: const TextStyle(
              color: _fg,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _quickQuestions
                .map(
                  (q) => ActionChip(
                    label: Text(q),
                    onPressed: _typing ? null : () => _send(q),
                    backgroundColor: _card,
                    side: const BorderSide(color: _border),
                    labelStyle: const TextStyle(
                      color: _primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          ..._messages.map(_messageBubble),
          if (_typing) _typingBubble(),
        ],
      ),
    );
  }

  Widget _messageBubble(_ChatMessage message) {
    final user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 370),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: user ? _primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(user ? 17 : 4),
            bottomRight: Radius.circular(user ? 4 : 17),
          ),
          border: user ? null : Border.all(color: _border),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: user ? Colors.white : _fg,
            fontSize: 13,
            height: 1.42,
          ),
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 9),
            Text(
              tr(widget.language, 'Digitando...', 'Typing...', 'Escribiendo...'),
              style: const TextStyle(color: _dim, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_typing,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: tr(
                  widget.language,
                  'Digite sua dúvida...',
                  'Type your question...',
                  'Escribe tu pregunta...',
                ),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: IconButton.filled(
              onPressed: _typing ? null : () => _send(),
              style: IconButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send_rounded, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}