import 'package:flutter/material.dart';

enum TxType { expense, income }

enum TxCategory {
  food('Food', Icons.shopping_basket_outlined),
  transit('Transit', Icons.directions_subway_outlined),
  home('Home', Icons.chair_outlined),
  fun('Fun', Icons.sports_esports_outlined),
  health('Health', Icons.favorite_border_rounded),
  bills('Bills', Icons.receipt_long_outlined),
  salary('Salary', Icons.attach_money_rounded),
  other('Other', Icons.category_outlined);

  const TxCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static TxCategory fromName(String name) {
    for (final category in values) {
      if (category.name == name) return category;
    }
    return TxCategory.other;
  }

  static List<TxCategory> forType(TxType type) {
    return switch (type) {
      TxType.expense => const [
          food,
          transit,
          home,
          fun,
          health,
          bills,
          other,
        ],
      TxType.income => const [salary, other],
    };
  }
}
