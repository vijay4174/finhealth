import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'expense_service.dart';

class ExpenseScannerPage extends StatefulWidget {
  const ExpenseScannerPage({super.key});

  @override
  State<ExpenseScannerPage> createState() =>
      _ExpenseScannerPageState();
}

class _ExpenseScannerPageState
    extends State<ExpenseScannerPage> {
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController amountController =
      TextEditingController();

  final TextEditingController titleController =
      TextEditingController();

  final List<String> categories = [
    'Food',
    'Rent',
    'Travel',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];

  File? selectedImage;

  String scannedText = '';
  String selectedCategory = 'Other';

  bool isScanning = false;
  bool hasScanned = false;

  Future<void> pickImage(
    ImageSource source,
  ) async {
    try {
      final XFile? image =
          await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        selectedImage = File(image.path);
        isScanning = true;
        hasScanned = false;
        scannedText = '';
        amountController.clear();
        titleController.clear();
        selectedCategory = 'Other';
      });

      await scanImage(image.path);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open image: $error',
          ),
        ),
      );
    }
  }

  Future<void> scanImage(
    String imagePath,
  ) async {
    final TextRecognizer textRecognizer =
        TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final InputImage inputImage =
          InputImage.fromFilePath(
        imagePath,
      );

      final RecognizedText recognizedText =
          await textRecognizer.processImage(
        inputImage,
      );

      final String fullText =
          recognizedText.text.trim();

      final double detectedAmount =
          detectAmount(fullText);

      final String detectedCategory =
          detectCategory(fullText);

      final String detectedTitle =
          detectTitle(
        fullText,
        detectedCategory,
      );

      if (!mounted) return;

      setState(() {
        scannedText = fullText;

        if (detectedAmount > 0) {
          amountController.text =
              detectedAmount.toStringAsFixed(0);
        }

        selectedCategory =
            detectedCategory;

        titleController.text =
            detectedTitle;

        isScanning = false;
        hasScanned = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to scan receipt: $error',
          ),
        ),
      );
    } finally {
      await textRecognizer.close();
    }
  }

  double detectAmount(
    String text,
  ) {
    if (text.isEmpty) {
      return 0;
    }

    final List<double> priorityAmounts = [];

    final List<RegExp> priorityPatterns = [
      RegExp(
        r'(?:total|grand\s*total|amount\s*paid|fare|ticket\s*fare|net\s*amount|payable)\s*[:₹rs.\s]*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'₹\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'rs\.?\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in priorityPatterns) {
      final matches =
          pattern.allMatches(text);

      for (final match in matches) {
        final value = double.tryParse(
          match.group(1) ?? '',
        );

        if (value != null &&
            value > 0 &&
            value < 10000000) {
          priorityAmounts.add(value);
        }
      }

      if (priorityAmounts.isNotEmpty) {
        return priorityAmounts.reduce(
          (a, b) => a > b ? a : b,
        );
      }
    }

    final RegExp numberPattern = RegExp(
      r'\b([0-9]+(?:\.[0-9]{1,2})?)\b',
    );

    final List<double> fallbackAmounts = [];

    for (final match
        in numberPattern.allMatches(text)) {
      final value = double.tryParse(
        match.group(1) ?? '',
      );

      if (value != null &&
          value > 0 &&
          value < 10000000) {
        fallbackAmounts.add(value);
      }
    }

    if (fallbackAmounts.isEmpty) {
      return 0;
    }

    return fallbackAmounts.reduce(
      (a, b) => a > b ? a : b,
    );
  }

  String detectCategory(
    String text,
  ) {
    final lowerText = text.toLowerCase();

    final Map<String, List<String>>
        categoryKeywords = {
      'Travel': [
        'rtc',
        'tgsrtc',
        'tsrtc',
        'apsrtc',
        'bus',
        'ticket',
        'metro',
        'railway',
        'train',
        'uber',
        'ola',
        'rapido',
        'petrol',
        'diesel',
        'fuel',
        'toll',
        'parking',
      ],
      'Food': [
        'restaurant',
        'hotel',
        'cafe',
        'food',
        'swiggy',
        'zomato',
        'meal',
        'biryani',
        'pizza',
        'burger',
        'bakery',
        'tea',
        'coffee',
      ],
      'Shopping': [
        'amazon',
        'flipkart',
        'shopping',
        'mall',
        'store',
        'mart',
        'supermarket',
        'clothing',
        'fashion',
      ],
      'Bills': [
        'electricity',
        'water bill',
        'mobile recharge',
        'recharge',
        'broadband',
        'internet',
        'wifi',
        'gas bill',
        'telephone',
        'postpaid',
      ],
      'Entertainment': [
        'movie',
        'cinema',
        'theatre',
        'bookmyshow',
        'netflix',
        'spotify',
        'hotstar',
        'prime video',
        'game',
      ],
      'Rent': [
        'rent',
        'house rent',
        'room rent',
        'apartment rent',
      ],
    };

    String bestCategory = 'Other';
    int highestMatches = 0;

    categoryKeywords.forEach(
      (category, keywords) {
        int matches = 0;

        for (final keyword in keywords) {
          if (lowerText.contains(keyword)) {
            matches++;
          }
        }

        if (matches > highestMatches) {
          highestMatches = matches;
          bestCategory = category;
        }
      },
    );

    return bestCategory;
  }

  String detectTitle(
    String text,
    String category,
  ) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('tgsrtc') ||
        lowerText.contains('tsrtc') ||
        lowerText.contains('rtc')) {
      return 'RTC Bus Ticket';
    }

    if (lowerText.contains('metro')) {
      return 'Metro Ticket';
    }

    if (lowerText.contains('uber')) {
      return 'Uber Ride';
    }

    if (lowerText.contains('ola')) {
      return 'Ola Ride';
    }

    if (lowerText.contains('rapido')) {
      return 'Rapido Ride';
    }

    if (lowerText.contains('swiggy')) {
      return 'Swiggy Order';
    }

    if (lowerText.contains('zomato')) {
      return 'Zomato Order';
    }

    if (lowerText.contains('amazon')) {
      return 'Amazon Purchase';
    }

    if (lowerText.contains('flipkart')) {
      return 'Flipkart Purchase';
    }

    if (lowerText.contains('bookmyshow')) {
      return 'Movie Ticket';
    }

    return '$category Expense';
  }

  Future<void> saveExpense() async {
    final double amount =
        double.tryParse(
          amountController.text.trim(),
        ) ??
        0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid amount',
          ),
        ),
      );

      return;
    }

    final String title =
        titleController.text.trim().isEmpty
            ? '$selectedCategory Expense'
            : titleController.text.trim();

    await ExpenseService.saveExpense(
      amount: amount,
      category: selectedCategory,
      title: title,
      source: 'Scanner',
      scannedText: scannedText,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '₹${amount.toStringAsFixed(0)} added to $selectedCategory',
        ),
      ),
    );

    Navigator.pop(
      context,
      true,
    );
  }

  Widget buildImagePickerButton({
    required String title,
    required IconData icon,
    required ImageSource source,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: isScanning
            ? null
            : () {
                pickImage(source);
              },
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    titleController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Expense Scanner',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.document_scanner_outlined,
              size: 70,
              color: Colors.deepPurple,
            ),

            const SizedBox(height: 12),

            const Text(
              'Scan Receipt or Ticket',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'The app will read the image, detect the amount and automatically suggest an expense category.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                buildImagePickerButton(
                  title: 'Camera',
                  icon: Icons.camera_alt,
                  source: ImageSource.camera,
                ),

                const SizedBox(width: 12),

                buildImagePickerButton(
                  title: 'Gallery',
                  icon: Icons.photo_library,
                  source: ImageSource.gallery,
                ),
              ],
            ),

            const SizedBox(height: 25),

            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  selectedImage!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),

            if (isScanning) ...[
              const SizedBox(height: 25),

              const CircularProgressIndicator(),

              const SizedBox(height: 12),

              const Text(
                'Reading receipt...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            if (hasScanned) ...[
              const SizedBox(height: 25),

              Card(
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Text(
                        'Detected Expense',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: amountController,
                        keyboardType:
                            TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Detected Amount',
                          prefixText: '₹ ',
                          prefixIcon:
                              Icon(Icons.currency_rupee),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedCategory,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Detected Category',
                          prefixIcon:
                              Icon(Icons.category),
                          border:
                              OutlineInputBorder(),
                        ),
                        items: categories.map(
                          (category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedCategory = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: titleController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Expense Title',
                          prefixIcon:
                              Icon(Icons.edit_note),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: saveExpense,
                          icon: const Icon(
                            Icons.add_circle_outline,
                          ),
                          label: const Text(
                            'Confirm & Add Expense',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ExpansionTile(
                title: const Text(
                  'View Scanned Text',
                ),
                leading: const Icon(
                  Icons.text_snippet_outlined,
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      scannedText.isEmpty
                          ? 'No text detected'
                          : scannedText,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}