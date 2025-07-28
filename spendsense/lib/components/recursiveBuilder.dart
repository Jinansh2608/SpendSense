// === recursiveBuilder.dart ===

import 'package:flutter/material.dart';

class RecursiveBuilderScreen extends StatefulWidget {
  const RecursiveBuilderScreen({super.key});

  @override
  State<RecursiveBuilderScreen> createState() => _RecursiveBuilderScreenState();
}

class _RecursiveBuilderScreenState extends State<RecursiveBuilderScreen> {
  final TextEditingController promptController = TextEditingController();
  final List<Map<String, dynamic>> flows = [];

  void processPrompt() {
    final text = promptController.text.trim();
    if (text.isEmpty) return;
    final parsed = FlowParser.parsePrompt(text);
    setState(() {
      flows.addAll(parsed);
    });
    promptController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌀 Recursive Builder"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📝 Enter your cash flow prompt:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: promptController,
                    decoration: const InputDecoration(
                      hintText:
                          "e.g. I receive ₹500 from salary every Friday...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Process"),
                      onPressed: processPrompt,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: flows.length,
              itemBuilder: (context, index) {
                final flow = flows[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ExpansionTile(
                    leading: Icon(
                      flow["type"] == "income" ? Icons.download : Icons.upload,
                    ),
                    title: Text(
                      '${flow["type"] == "income" ? "Income" : "Expense"} - ₹${flow["amount"] ?? '—'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(flow["raw"] ?? ''),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            rowField(
                              "Amount",
                              flow["amount"]?.toString(),
                              (val) => flow["amount"] = int.tryParse(val),
                            ),
                            if (flow["type"] == "income")
                              rowField(
                                "Source",
                                flow["source"] ?? '',
                                (val) => flow["source"] = val,
                              ),
                            if (flow["type"] == "expense")
                              rowField(
                                "Category",
                                flow["category"] ?? '',
                                (val) => flow["category"] = val,
                              ),
                            rowField(
                              "Time",
                              flow["time"] ?? '',
                              (val) => flow["time"] = val,
                            ),
                            dropdownRow(
                              "Frequency",
                              flow["frequency"] ?? 'Daily',
                              (val) => setState(() => flow["frequency"] = val),
                            ),
                            daysSelector(flow),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget rowField(String label, String? value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: TextEditingController(text: value),
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }

  Widget dropdownRow(
    String label,
    String value,
    void Function(String?)? onChanged,
  ) {
    const options = [
      "Daily",
      "Weekly",
      "Weekends",
      "Weekdays",
      "Monthly",
      "Custom",
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : "Daily",
        decoration: InputDecoration(labelText: label),
        items: options
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget daysSelector(Map<String, dynamic> flow) {
    const allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final days = List<String>.from(flow["days"] ?? []);
    return Wrap(
      spacing: 8,
      children: allDays.map((day) {
        final selected = days.contains(day);
        return FilterChip(
          label: Text(day),
          selected: selected,
          onSelected: (val) {
            setState(() {
              if (val) {
                days.add(day);
              } else {
                days.remove(day);
              }
              flow["days"] = days;
            });
          },
        );
      }).toList(),
    );
  }
}

class FlowParser {
  static List<Map<String, dynamic>> parsePrompt(String prompt) {
    final List<Map<String, dynamic>> results = [];
    final parts = prompt.split(
      RegExp(r'(?<=[.,])\s*|\s+and\s+', caseSensitive: false),
    );

    for (var part in parts) {
      if (part.trim().isEmpty) continue;
      final lower = part.toLowerCase();

      var flow = {
        "type": null,
        "amount": null,
        "source": null,
        "category": null,
        "frequency": null,
        "time": null,
        "days": <String>[],
        "raw": part.trim(),
      };

      if (lower.contains("receive") || lower.contains("get")) {
        flow["type"] = "income";
      } else if (lower.contains("spend") || lower.contains("pay")) {
        flow["type"] = "expense";
      }

      final amtMatch = RegExp(r'\u20B9?(\d+)').firstMatch(lower);
      if (amtMatch != null) {
        flow["amount"] = int.tryParse(amtMatch.group(1)!);
      }

      if (flow["type"] == "income") {
        final sourceMatch = RegExp(r'from ([a-z\s]+)').firstMatch(lower);
        if (sourceMatch != null) flow["source"] = sourceMatch.group(1)?.trim();
      } else if (flow["type"] == "expense") {
        final catMatch = RegExp(r'on ([a-z\s]+)').firstMatch(lower);
        if (catMatch != null) flow["category"] = catMatch.group(1)?.trim();
      }

      final timeMatch = RegExp(
        r'(morning|afternoon|evening|night|\d{1,2}(am|pm)?)',
      ).firstMatch(lower);
      if (timeMatch != null) flow["time"] = timeMatch.group(0);

      final freqMatch = RegExp(
        r'(daily|weekly|monthly|weekends|weekdays)',
        caseSensitive: false,
      ).firstMatch(lower);
      if (freqMatch != null)
        flow["frequency"] = _capitalize(freqMatch.group(1));

      final daysMatch = RegExp(
        r'(mon|tue|wed|thu|fri|sat|sun)',
        caseSensitive: false,
      ).allMatches(lower);
      if (daysMatch.isNotEmpty) {
        flow["days"] = daysMatch
            .map((m) => _capitalize(m.group(0)!))
            .toSet()
            .toList();
        flow["frequency"] = "Custom";
      }

      if (flow["type"] != null && flow["amount"] != null) {
        results.add(flow);
      }
    }

    return results;
  }

  static String _capitalize(String? s) => (s != null && s.isNotEmpty)
      ? '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}'
      : '';
}
