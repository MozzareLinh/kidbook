import 'package:flutter/material.dart';

class DictionaryCardModel {
  final String imagePath;
  final String title;
  bool isActive = false;
  final String object;
  final bool isLocal;

  DictionaryCardModel(
      this.imagePath, this.title, this.isActive, this.object, this.isLocal);
}