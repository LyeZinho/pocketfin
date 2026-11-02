import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pocket_widgets.dart';
import '../../logic/providers.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({super.key});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _noteController = TextEditingController();
  TxType _type = TxType.expense;
  TxCategory _category = TxCategory.food;
  String _raw = '';
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _amountCents {
    if (_raw.isEmpty) return 0;
    final value = double.tryParse(_raw);
    return value == null ? 0 : (value * 100).round();
  }

  String get _displayAmount {
    if (_raw.isEmpty) return '0.00';
    final parts = _raw.split('.');
    final integerPart = parts.first.isEmpty ? '0' : parts.first;
    final parsed = int.tryParse(integerPart) ?? 0;
    final grouped = NumberFormat.decimalPattern('en_US').format(parsed);
    if (!_raw.contains('.')) return grouped;
    final decimals = parts.length > 1 ? parts[1] : '';
    return '$grouped.${decimals.padRight(2, '0')}';
  }

  void _press(String key) {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'backspace') {
        if (_raw.isNotEmpty) {
          _raw = _raw.substring(0, _raw.length - 1);
        }
        return;
      }
      if (key == '.') {
        if (!_raw.contains('.')) {
          _raw = _raw.isEmpty ? '0.' : '$_raw.';
        }
        return;
      }
      final dot = _raw.indexOf('.');
      if (dot != -1 && _raw.length - dot - 1 >= 2) return;
      if (dot == -1 && _raw.replaceAll('.', '').length >= 7) return;
      if (_raw == '0') {
        _raw = key;
      } else {
        _raw += key;
      }
    });
  }

  Future<void> _save() async {
    final cents = _amountCents;
    if (cents <= 0) {
      _showMessage('Enter an amount greater than zero.');
      return;
    }

    setState(() => _saving = true);
    try {
      final note = _noteController.text.trim();
      await ref.read(repositoryProvider).addEntry(
            title: note.isEmpty ? _category.label : note,
            category: _category,
            type: _type,
            amountCents: cents,
            note: note.isEmpty ? null : note,
            occurredAt: DateTime.now(),
          );
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save this entry.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = TxCategory.forType(_type);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    _CircleButton(
                      icon: Icons.close_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'New entry',
                          style: TextStyle(
                            fontFamily: AppText.ui,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 22),
                SegmentedTabs<TxType>(
                  values: const [TxType.expense, TxType.income],
                  selected: _type,
                  label: (value) =>
                      value == TxType.expense ? 'Expense' : 'Income',
                  activeColor:
                      _type == TxType.expense ? AppColors.coral : AppColors.lime,
                  onChanged: (value) {
                    setState(() {
                      _type = value;
                      _category = TxCategory.forType(value).first;
                    });
                  },
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        r'$',
                        style: AppText.data(
                          34,
                          color: AppColors.muted,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _displayAmount,
                          style: AppText.data(
                            58,
                            weight: FontWeight.w500,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 46,
                      margin: const EdgeInsets.only(left: 4, bottom: 6),
                      color: AppColors.lime,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final category in categories)
                      _CategoryChip(
                        category: category,
                        selected: category == _category,
                        onTap: () => setState(() => _category = category),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _noteController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  style: AppText.body(17),
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle:
                        AppText.body(17, color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _Keypad(onKey: _press),
                const SizedBox(height: 18),
                SizedBox(
                  height: 60,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.onAccent,
                      disabledBackgroundColor: AppColors.lime.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.onAccent,
                            ),
                          )
                        : Text(
                            'Save ${_type == TxType.expense ? 'expense' : 'income'}',
                            style: AppText.body(
                              19,
                              weight: FontWeight.w600,
                              color: AppColors.onAccent,
                            ),
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
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.text, size: 22),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TxCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          category.label,
          style: AppText.body(
            16,
            weight: FontWeight.w600,
            color: selected ? AppColors.onAccent : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});

  final ValueChanged<String> onKey;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', 'backspace'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                for (var index = 0; index < row.length; index++) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Expanded(child: _Key(keyValue: row[index], onKey: onKey)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.keyValue, required this.onKey});

  final String keyValue;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onKey(keyValue),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: keyValue == 'backspace'
            ? const Icon(
                Icons.backspace_outlined,
                color: AppColors.text,
                size: 21,
              )
            : Text(
                keyValue,
                style: AppText.data(23, weight: FontWeight.w400),
              ),
      ),
    );
  }
}
