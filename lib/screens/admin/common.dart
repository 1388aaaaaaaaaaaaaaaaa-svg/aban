import 'package:flutter/material.dart';

import '../../api.dart';
import '../../theme.dart';

class FieldSpec {
  final String key;
  final String label;
  final String initial;
  final bool obscure;
  final bool ltr;
  const FieldSpec(this.key, this.label, {this.initial = '', this.obscure = false, this.ltr = false});
}

/// Dialog with text fields. Returns the values, or null when cancelled.
Future<Map<String, String>?> askFields(BuildContext context, {required String title, required List<FieldSpec> fields}) {
  final ctrls = {for (final f in fields) f.key: TextEditingController(text: f.initial)};
  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: fields
              .map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: ctrls[f.key],
                      obscureText: f.obscure,
                      textDirection: f.ltr ? TextDirection.ltr : null,
                      decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
                    ),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, {for (final e in ctrls.entries) e.key: e.value.text.trim()}),
          child: const Text('ذخیره'),
        ),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String text) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأیید')),
      ],
    ),
  );
  return ok == true;
}

/// Runs an API call and shows the result or the error.
Future<bool> runApi(BuildContext context, Future<void> Function() fn, {String? done}) async {
  try {
    await fn();
    if (done != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عملیات انجام نشد')));
    }
  }
  return false;
}

Widget infoLine(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    );
