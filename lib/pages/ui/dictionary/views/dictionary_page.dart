
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../model/ar_objects.dart';
import '../model/dictionary_card_model.dart';
import 'ar_objects_screen.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  List<DictionaryCardModel> mycard = [
    DictionaryCardModel('assets/trau.jpg', 'Con trâu', false, ARObjects.bull, true),
    DictionaryCardModel('assets/de.jpg', 'Con dê', false, ARObjects.goat, true),
    DictionaryCardModel('assets/ga.jpg', 'Con gà', false, ARObjects.chicken, true),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thư viện 3D', style: TextStyle(fontSize: 20),),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: mycard
                    .map(
                      (e) => InkWell(
                    onTap: () => onTap(e),
                    child: Card(
                      color: e.isActive ? AppColors.grey : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            e.imagePath,
                            width: 70,
                            height: 70,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            e.title,
                            style: TextStyle(
                                color: e.isActive
                                    ? AppColors.white
                                    : AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
          )
        ],
      ),
    );
  }

  void onTap(DictionaryCardModel e) {
    setState(() {
      e.isActive = !e.isActive;
    });
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ARObjectsScreen(
              object: e.object,
              isLocal: e.isLocal,
            ))).then((value) {
      setState(() {
        e.isActive = !e.isActive;
      });
    });
  }
}
