import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const YumiApp());
}

class YumiApp extends StatefulWidget {
  const YumiApp({super.key});

  @override
  State<YumiApp> createState() => _YumiAppState();
}

class _YumiAppState extends State<YumiApp> {
  String _themeMode = 'auto'; // auto, light, dark, amoled
  String _language = 'auto'; // auto, it, en
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = prefs.getString('yumi_theme') ?? 'auto';
      _language = prefs.getString('yumi_lang') ?? 'auto';
      _isLoaded = true;
    });
  }

  void updateSettings(String newTheme, String newLang) {
    setState(() {
      _themeMode = newTheme;
      _language = newLang;
    });
  }

  String get effectiveLanguage {
    if (_language == 'auto') {
      final systemLanguage = PlatformDispatcher.instance.locale.languageCode;
      return systemLanguage == 'it' ? 'it' : 'en';
    }
    return _language;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    // TEMA CHIARO: Ottimizzato con Verde Acqua Scuro e contrasti elevati
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF005A5B), // Verde acqua scuro principale
        brightness: Brightness.light,
        primary: const Color(0xFF005A5B),
        surface: Colors.white,
        onSurface: const Color(0xFF1E2638),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFE8ECEF),
        shadowColor: Colors.black12,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        titleTextStyle: TextStyle(
            color: Color(0xFF1E2638),
            fontSize: 20,
            fontWeight: FontWeight.bold),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
    );

    // TEMA SCURO STANDARD
    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121824),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.tealAccent,
        brightness: Brightness.dark,
        primary: Colors.tealAccent,
        surface: const Color(0xFF1E2638),
        onSurface: Colors.white,
      ),
      cardTheme: const CardThemeData(color: Color(0xFF252E42)),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E2638)),
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Color(0xFF1E2638)),
    );

    // TEMA AMOLED
    final ThemeData amoledTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.tealAccent,
        brightness: Brightness.dark,
        primary: Colors.tealAccent,
        surface: const Color(0xFF111111),
        onSurface: Colors.white,
      ),
      cardTheme: const CardThemeData(color: Color(0xFF111111)),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF111111)),
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Color(0xFF111111)),
    );

    ThemeData currentTheme;
    if (_themeMode == 'light') {
      currentTheme = lightTheme;
    } else if (_themeMode == 'dark') {
      currentTheme = darkTheme;
    } else if (_themeMode == 'amoled') {
      currentTheme = amoledTheme;
    } else {
      final windowTheme = PlatformDispatcher.instance.platformBrightness;
      currentTheme = windowTheme == Brightness.dark ? darkTheme : lightTheme;
    }

    return MaterialApp(
      title: 'Yumi',
      debugShowCheckedModeBanner: false,
      theme: currentTheme,
      home: MainScreen(
        currentThemeMode: _themeMode,
        currentLanguage: _language,
        effectiveLanguage: effectiveLanguage,
        onSettingsChanged: updateSettings,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String currentThemeMode;
  final String currentLanguage;
  final String effectiveLanguage;
  final Function(String, String) onSettingsChanged;

  const MainScreen({
    super.key,
    required this.currentThemeMode,
    required this.currentLanguage,
    required this.effectiveLanguage,
    required this.onSettingsChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _showManualInput = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _favorites = [];

  final Map<String, Map<String, String>> _localizedStrings = {
    'it': {
      'history': 'Cronologia',
      'favorites': 'Preferiti',
      'settings': 'Impostazioni',
      'info': 'Info & Riconoscimenti',
      'empty': 'Nessun elemento salvato.',
      'unknown': 'Prodotto Sconosciuto',
      'not_found': 'Prodotto non trovato.',
      'server_err': 'Errore di comunicazione server.',
      'conn_err': 'Nessuna connessione ad internet.',
      'barcode_hint': 'Codice a barre...',
      'insufficient_data': 'Valori non sufficienti per il calcolo',
      'estimated_data':
          'Calcolo impreciso in quanto alcuni valori sono mancanti nel database',
      'specifications': 'Specifiche Nutrizionali (100g/ml)',
      'energy': 'Energia',
      'fats': 'Grassi totali',
      'sugars': 'di cui Zuccheri',
      'close': 'Chiudi',
      'theme': 'Tema',
      'lang': 'Lingua',
      'theme_auto': 'Sistema (Auto)',
      'theme_light': 'Chiaro',
      'theme_dark': 'Scuro',
      'theme_amoled': 'Amoled',
      'lang_auto': 'Auto (Sistema)',
      'save': 'Salva',
      'unavailable': 'Indisponibile',
      'app_desc':
          'Applicazione indipendente per l\'analisi nutrizionale e la tutela del consumatore.',
      'req_credits': 'Riconoscimenti Obbligatori:',
    },
    'en': {
      'history': 'History',
      'favorites': 'Favorites',
      'settings': 'Settings',
      'info': 'Info & Credits',
      'empty': 'No items saved yet.',
      'unknown': 'Unknown Product',
      'not_found': 'Product not found.',
      'server_err': 'Server communication error.',
      'conn_err': 'No internet connection.',
      'barcode_hint': 'Barcode...',
      'insufficient_data': 'Insufficient data for score calculation',
      'estimated_data': 'Imprecise calculation due to missing database values',
      'specifications': 'Nutritional Specifications (100g/ml)',
      'energy': 'Energy',
      'fats': 'Total Fats',
      'sugars': 'of which Sugars',
      'close': 'Close',
      'theme': 'Theme',
      'lang': 'Language',
      'theme_auto': 'System (Auto)',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'theme_amoled': 'Amoled',
      'lang_auto': 'Auto (System)',
      'save': 'Save',
      'unavailable': 'Unavailable',
      'app_desc':
          'Independent app for nutritional analysis and consumer protection.',
      'req_credits': 'Required Acknowledgments:',
    }
  };

  String _getText(String key) {
    return _localizedStrings[widget.effectiveLanguage]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadStorageData();
  }

  Future<void> _loadStorageData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final String? historyString = prefs.getString('yumi_history');
      final String? favoritesString = prefs.getString('yumi_favorites');

      if (historyString != null) {
        _history = List<Map<String, dynamic>>.from(json.decode(historyString));
      }
      if (favoritesString != null) {
        _favorites =
            List<Map<String, dynamic>>.from(json.decode(favoritesString));
      }
    });
  }

  Future<void> _saveStorageData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('yumi_history', json.encode(_history));
    await prefs.setString('yumi_favorites', json.encode(_favorites));
  }

  Map<String, dynamic> _calculateHealthScore(
      Map<String, dynamic> productData, String barcode) {
    final String grade =
        (productData['nutriscore_grade'] ?? '').toString().toLowerCase();
    final dynamic rawNutriscoreScore = productData['nutriscore_score'];

    final Map<String, dynamic> nutriscoreData =
        Map<String, dynamic>.from(productData['nutriscore_data'] ?? {});
    final List<dynamic> categoriesTags = productData['categories_tags'] ?? [];

    String status = 'ok';
    if (grade.isEmpty && rawNutriscoreScore == null) {
      status = 'insufficient_data';
    } else if (rawNutriscoreScore == null && grade.isNotEmpty) {
      status = 'estimated_data';
    }

    bool isWater = (nutriscoreData['is_water'] == 1) ||
        categoriesTags
            .any((cat) => cat.toString().toLowerCase().contains('water'));
    bool isBeverage = (nutriscoreData['is_beverage'] == 1) ||
        categoriesTags
            .any((cat) => cat.toString().toLowerCase().contains('beverage'));

    double baseScore = 50.0;
    double malusBio = 5.0;

    if (isWater) {
      baseScore = 100.0;
      malusBio = 0.0;
    } else if (status != 'insufficient_data') {
      if (rawNutriscoreScore != null) {
        final num nutriscoreScore = num.parse(rawNutriscoreScore.toString());
        if (isBeverage) {
          baseScore = 100.0 - (((nutriscoreScore + 20) / 60) * 100);
        } else {
          baseScore = 100.0 - (((nutriscoreScore + 15) / 55) * 100);
        }
      } else {
        switch (grade) {
          case 'a':
            baseScore = 100.0;
            break;
          case 'b':
            baseScore = 85.0;
            break;
          case 'c':
            baseScore = 65.0;
            break;
          case 'd':
            baseScore = 45.0;
            break;
          case 'e':
            baseScore = 25.0;
            break;
          default:
            baseScore = 50.0;
        }
      }
    }

    if (!isWater) {
      final List<dynamic> labels = productData['labels_tags'] ?? [];
      bool isOrganic = labels
          .any((label) => label.toString().toLowerCase().contains('organic'));
      malusBio = isOrganic ? 0.0 : 5.0;
    }

    final List<dynamic> additivesTags = productData['additives_tags'] ?? [];
    double malusAdditivi = 0.0;

    if (additivesTags.isNotEmpty && !isWater) {
      bool hasHighRisk = false;
      bool hasModerateRisk = false;
      bool hasLimitedRisk = false;

      const highRiskAdditives = {
        'e249',
        'e250',
        'e251',
        'e252',
        'e220',
        'e221',
        'e222',
        'e223',
        'e224',
        'e226',
        'e227',
        'e228',
        'e102',
        'e104',
        'e110',
        'e122',
        'e124',
        'e129',
        'e131',
        'e133',
        'e150c',
        'e150d',
        'e151',
        'e950',
        'e951',
        'e952',
        'e954',
        'e955',
        'e961',
        'e962'
      };

      const moderateRiskAdditives = {
        'e338',
        'e339',
        'e340',
        'e341',
        'e343',
        'e450',
        'e451',
        'e452',
        'e620',
        'e621',
        'e622',
        'e623',
        'e624',
        'e625',
        'e627',
        'e631',
        'e635',
        'e432',
        'e433',
        'e434',
        'e435',
        'e436',
        'e466',
        'e471',
        'e472e',
        'e473',
        'e475',
        'e476',
        'e491',
        'e492'
      };

      const limitedRiskAdditives = {
        'e407',
        'e412',
        'e414',
        'e415',
        'e416',
        'e417',
        'e425',
        'e461',
        'e420',
        'e421',
        'e953',
        'e965',
        'e966',
        'e967',
        'e968'
      };

      for (var additive in additivesTags) {
        final String addStr = additive.toString().toLowerCase().trim();
        final String cleanCode =
            addStr.contains(':') ? addStr.split(':').last : addStr;

        if (highRiskAdditives.contains(cleanCode)) {
          hasHighRisk = true;
          break;
        } else if (moderateRiskAdditives.contains(cleanCode)) {
          hasModerateRisk = true;
        } else if (limitedRiskAdditives.contains(cleanCode)) {
          hasLimitedRisk = true;
        }
      }

      if (hasHighRisk) {
        malusAdditivi = 15.0;
      } else if (hasModerateRisk) {
        malusAdditivi = 8.0;
      } else if (hasLimitedRisk) {
        malusAdditivi = 4.0;
      }
    }

    double finalScore = baseScore - malusAdditivi - malusBio;
    finalScore = finalScore.clamp(0.0, 100.0);

    if (grade == 'e') {
      finalScore = finalScore.clamp(0.0, 29.0);
    } else if (grade == 'd') {
      finalScore = finalScore.clamp(0.0, 49.0);
    } else if (grade == 'c') {
      finalScore = finalScore.clamp(0.0, 69.0);
    }

    final nutriments = productData['nutriments'] ?? {};
    final dynamic rawCalories = nutriments['energy-kcal_100g'];
    final dynamic rawFats = nutriments['fat_100g'];
    final dynamic rawSugars = nutriments['sugars_100g'];

    return {
      'barcode': barcode,
      'status': status,
      'name': productData['product_name'] ?? _getText('unknown'),
      'calculatedScore': finalScore.round().clamp(0, 100),
      'officialGrade': grade.isEmpty ? 'N/A' : grade.toUpperCase(),
      'imageUrl': productData['image_url'] ?? productData['image_front_url'],
      'calories': rawCalories != null ? "${rawCalories.toString()} kcal" : "-",
      'fats': rawFats != null ? "${rawFats.toString()}g" : "-",
      'zuckers': rawSugars != null ? "${rawSugars.toString()}g" : "-",
    };
  }

  Future<void> _fetchProduct(String barcode) async {
    if (barcode.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showManualInput = false;
    });

    _scannerController.stop();

    final String url =
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'YumiApp - Flutter - Version 3.0.0',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 1 && jsonResponse['product'] != null) {
          final processed =
              _calculateHealthScore(jsonResponse['product'], barcode);

          setState(() {
            _history.removeWhere((item) => item['barcode'] == barcode);
            _history.insert(0, processed);
          });
          _saveStorageData();

          _showResultBottomSheet(processed);
        } else {
          _showErrorSnackBar(_getText('not_found'));
        }
      } else {
        _showErrorSnackBar(_getText('server_err'));
      }
    } catch (_) {
      _showErrorSnackBar(_getText('conn_err'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResultBottomSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool isFav =
                _favorites.any((item) => item['barcode'] == data['barcode']);
            final isLight = Theme.of(context).brightness == Brightness.light;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40),
                            Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color:
                                    isLight ? Colors.black12 : Colors.white24,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav
                                    ? Colors.redAccent
                                    : (isLight
                                        ? Colors.black54
                                        : Colors.white70),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isFav) {
                                    _favorites.removeWhere((item) =>
                                        item['barcode'] == data['barcode']);
                                  } else {
                                    _favorites.insert(0, data);
                                  }
                                });
                                _saveStorageData();
                                setModalState(() {});
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        ResultWidget(
                            data: data,
                            localizedTexts:
                                _localizedStrings[widget.effectiveLanguage]!),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      _scannerController.start();
    });
  }

  void _openDataListScreen(
      String title, List<Map<String, dynamic>> list, bool isHistory) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.onSurface),
            actions: [
              if (list.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      if (isHistory) {
                        _history.clear();
                      } else {
                        _favorites.clear();
                      }
                    });
                    _saveStorageData();
                    Navigator.of(context).pop();
                  },
                )
            ],
          ),
          body: list.isEmpty
              ? Center(
                  child: Text(_getText('empty'),
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(180))))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return ListTile(
                      leading: item['imageUrl'] != null
                          ? Image.network(item['imageUrl'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.fastfood))
                          : const Icon(Icons.fastfood),
                      title: Text(item['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface)),
                      subtitle: Text(
                        item['status'] == 'insufficient_data'
                            ? _getText('unavailable')
                            : 'Score: ${item['calculatedScore']}/100 | Grade: ${item['officialGrade']}',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(140)),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(80)),
                        onPressed: () {
                          setState(() {
                            if (isHistory) {
                              _history.removeAt(index);
                            } else {
                              _favorites.removeAt(index);
                            }
                          });
                          _saveStorageData();
                          Navigator.of(context).pop();
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showResultBottomSheet(item);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _openSettingsDialog() {
    String localTheme = widget.currentThemeMode;
    String localLang = widget.currentLanguage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_getText('settings'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getText('theme'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              DropdownButton<String>(
                value: localTheme,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                items: [
                  DropdownMenuItem(
                      value: 'auto', child: Text(_getText('theme_auto'))),
                  DropdownMenuItem(
                      value: 'light', child: Text(_getText('theme_light'))),
                  DropdownMenuItem(
                      value: 'dark', child: Text(_getText('theme_dark'))),
                  DropdownMenuItem(
                      value: 'amoled', child: Text(_getText('theme_amoled'))),
                ],
                onChanged: (val) => setDialogState(() => localTheme = val!),
              ),
              const SizedBox(height: 20),
              Text(_getText('lang'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              DropdownButton<String>(
                value: localLang,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                items: [
                  DropdownMenuItem(
                      value: 'auto', child: Text(_getText('lang_auto'))),
                  DropdownMenuItem(value: 'it', child: const Text('Italiano')),
                  DropdownMenuItem(value: 'en', child: const Text('English')),
                ],
                onChanged: (val) => setDialogState(() => localLang = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('yumi_theme', localTheme);
                await prefs.setString('yumi_lang', localLang);
                widget.onSettingsChanged(localTheme, localLang);
                if (mounted) Navigator.of(context).pop();
              },
              child: Text(_getText('save'),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            )
          ],
        ),
      ),
    );
  }

  void _openCreditsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('info'),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Yumi v3.0.0',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 10),
              Text(_getText('app_desc'),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              const Divider(height: 24),
              Text(_getText('req_credits'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(
                  '• Open Food Facts: Open Database License (ODbL) & CC-BY-SA.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('• Flutter SDK & Cupertino: BSD 3-Clause License.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('• mobile_scanner: MIT License.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('• shared_preferences: BSD 3-Clause License.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('• Google ML Kit Barcode: Google APIs Terms of Service.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_getText('close'),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)))
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3)),
    );
    _scannerController.start();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double scanWidth = 280.0;
    const double scanHeight = 140.0;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isLoading) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  _fetchProduct(code);
                }
              }
            },
          ),
          ColorFiltered(
            colorFilter:
                ColorFilter.mode(Colors.black.withAlpha(165), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(color: Colors.transparent),
                Center(
                  child: Container(
                    width: scanWidth,
                    height: scanHeight,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: scanWidth,
              height: scanHeight,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          Center(
            child: Container(
                width: scanWidth * 0.9,
                height: 2,
                color: Theme.of(context).colorScheme.primary.withAlpha(128)),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle),
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: Theme.of(context).colorScheme.primary),
                color: Theme.of(context).colorScheme.surface,
                onSelected: (value) {
                  if (value == 'history') {
                    _openDataListScreen(_getText('history'), _history, true);
                  }
                  if (value == 'fav') {
                    _openDataListScreen(
                        _getText('favorites'), _favorites, false);
                  }
                  if (value == 'settings') {
                    _openSettingsDialog();
                  }
                  if (value == 'info') {
                    _openCreditsDialog();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                      value: 'history',
                      child: Row(children: [
                        Icon(Icons.history,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(_getText('history'),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface))
                      ])),
                  PopupMenuItem(
                      value: 'fav',
                      child: Row(children: [
                        const Icon(Icons.favorite,
                            size: 18, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(_getText('favorites'),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface))
                      ])),
                  PopupMenuItem(
                      value: 'settings',
                      child: Row(children: [
                        const Icon(Icons.settings,
                            size: 18, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(_getText('settings'),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface))
                      ])),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                      value: 'info',
                      child: Row(children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(_getText('info'),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface))
                      ])),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              onPressed: () =>
                  setState(() => _showManualInput = !_showManualInput),
              child: Icon(_showManualInput ? Icons.videocam : Icons.keyboard),
            ),
          ),
          if (_showManualInput)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 76,
              child: Card(
                elevation: 12,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16),
                          decoration: InputDecoration(
                            hintText: _getText('barcode_hint'),
                            hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(100)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.arrow_forward),
                        style: IconButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                isLight ? Colors.white : Colors.black),
                        onPressed: () {
                          _fetchProduct(_controller.text.trim());
                          _controller.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Container(
                color: Colors.black45,
                child: const Center(
                    child:
                        CircularProgressIndicator(color: Colors.tealAccent))),
        ],
      ),
    );
  }
}

class ResultWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, String> localizedTexts;

  const ResultWidget(
      {super.key, required this.data, required this.localizedTexts});

  Color _getScoreColor(int score) {
    if (score >= 75) return Colors.greenAccent.shade700;
    if (score >= 50) return Colors.lightGreenAccent.shade400;
    if (score >= 25) return Colors.orangeAccent.shade400;
    return Colors.redAccent.shade400;
  }

  Color _getNutriGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return Colors.green.shade700;
      case 'B':
        return Colors.lightGreen.shade600;
      case 'C':
        return Colors.amber.shade600;
      case 'D':
        return Colors.orange.shade700;
      case 'E':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = data['status'] ?? 'ok';
    final int score = data['calculatedScore'] ?? 0;
    final String grade = data['officialGrade'] ?? 'N/A';
    final String? imageUrl = data['imageUrl'];
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SizedBox(
                      width: 90,
                      height: 90,
                      child: Icon(Icons.image_not_supported,
                          color: Theme.of(context).colorScheme.onSurface)),
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  if (status != 'insufficient_data')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: _getNutriGradeColor(grade),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('Nutri-Score $grade',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(localizedTexts['unavailable']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white)),
                    )
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 24),
        if (status == 'insufficient_data') ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(25),
              border: Border.all(
                  color: Colors.redAccent.withAlpha(100), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.help_outline,
                    size: 48, color: Colors.redAccent),
                const SizedBox(height: 10),
                Text(
                  localizedTexts['insufficient_data']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      backgroundColor:
                          isLight ? Colors.black12 : Colors.white10,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
                      strokeWidth: 8,
                    ),
                  ),
                  Text('$score/100',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ],
          ),
          if (status == 'estimated_data') ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(25),
                border: Border.all(color: Colors.amber.withAlpha(90), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizedTexts['estimated_data']!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.amber,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 24),
        Text(localizedTexts['specifications']!,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 10),
        BreakdownRow(
            icon: Icons.local_fire_department,
            color: Colors.orangeAccent,
            title: localizedTexts['energy']!,
            value: data['calories']),
        BreakdownRow(
            icon: Icons.water_drop,
            color: Colors.blueAccent,
            title: localizedTexts['fats']!,
            value: data['fats']),
        BreakdownRow(
            icon: Icons.cake,
            color: Colors.purpleAccent,
            title: localizedTexts['sugars']!,
            value: data['zuckers']),
      ],
    );
  }
}

class BreakdownRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const BreakdownRow(
      {super.key,
      required this.icon,
      required this.color,
      required this.title,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isLight ? const Color(0xFFF0F2F5) : const Color(0x3D000000),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
