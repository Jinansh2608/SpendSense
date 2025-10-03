import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/constants/api_constants.dart';
import 'package:table_calendar/table_calendar.dart';

/// Standalone Home1 screen with local SQLite, calendar heatmap chips,
/// cash/digital tiles, filters, transaction listing, and add-cash dialog.
/// Replace your previous Home1 with this file.

class Home1 extends StatefulWidget {
  const Home1({super.key});

  @override
  State<Home1> createState() => _Home1State();
}

class _Home1State extends State<Home1> {
  late TransactionDb _db;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterMode = 'All'; // 'All'|'Digital'|'Cash'
  DateTime? _selectedDate; // null = all dates
  Map<String, double> _dailySpending = {}; // yyyy-MM-dd -> totalSpent
  double _digitalTotal = 0.0;
  double _cashTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    _db = await TransactionDb.open();
    await _fetchAndCacheRemote();
    await _loadFromDb();
  }

  /// Fetch remote API and cache into SQLite.
  /// If remote fails, proceed to load local DB.
  Future<void> _fetchAndCacheRemote() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final url = Uri.parse(
          '${ApiConstants.baseUrl}/records/${user.uid}?limit=500',
        );
        final resp = await http.get(url).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final decoded = json.decode(resp.body);
          final List<dynamic> data = decoded['data'] ?? [];
          // Normalize & save each transaction into local db
          for (final item in data) {
            final map = Map<String, dynamic>.from(item as Map);
            // Normalize fields we expect
            // Ensure mode classification: anything not 'Cash' -> Digital
            final mode = (map['mode'] ?? '').toString();
            final txnType = (map['txn_type'] ?? '').toString();
            final amount = (map['amount'] is num)
                ? (map['amount'] as num).toDouble()
                : double.tryParse(map['amount']?.toString() ?? '') ?? 0.0;
            DateTime? date;
            final dateStr = map['date']?.toString();
            if (dateStr != null && dateStr.isNotEmpty) {
              try {
                date = DateTime.parse(dateStr);
              } catch (e) {
                // try fallback
                try {
                  date = DateTime.parse(
                    map['created_at']?.toString() ??
                        DateTime.now().toIso8601String(),
                  );
                } catch (_) {
                  date = DateTime.now();
                }
              }
            } else {
              date = DateTime.now();
            }

            // Decide channel: Cash vs Digital
            final channel =
                (mode.toLowerCase().contains('atm') ||
                    mode.toLowerCase().contains('cash') ||
                    (map['category']?.toString().toLowerCase() == 'cash'))
                ? 'Cash'
                : 'Digital';

            final txn = TransactionModel(
              id: map['id']?.toString() ?? UniqueKey().toString(),
              uid: map['uid']?.toString() ?? user.uid,
              sms: map['sms']?.toString() ?? '',
              sender: map['sender']?.toString() ?? '',
              category: map['category']?.toString() ?? 'Other',
              amount: amount,
              txnType: txnType.isNotEmpty
                  ? txnType
                  : (amount >= 0 ? 'Credit' : 'Debit'),
              mode: mode.isNotEmpty ? mode : channel,
              channel: channel,
              refNo: map['ref_no']?.toString(),
              account: map['account']?.toString(),
              date: date,
              balance: (map['balance'] is num)
                  ? (map['balance'] as num).toDouble()
                  : (double.tryParse(map['balance']?.toString() ?? '') ?? null),
              createdAt:
                  DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                  DateTime.now(),
            );

            await _db.upsertTransaction(txn);
          }
        } else {
          // non-200 - ignore remote but show message
          setState(
            () => _errorMessage = 'Remote load failed: ${resp.statusCode}',
          );
        }
      } else {
        setState(
          () => _errorMessage = 'User not logged in - using local cache only.',
        );
      }
    } catch (e) {
      // Network or parse error - ignore but show message
      setState(() => _errorMessage = 'Remote fetch error: ${e.toString()}');
    } finally {
      // continue to load DB
    }
  }

  Future<void> _loadFromDb() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final rows = await _db.getAllTransactions();
      _transactions = rows.map((r) => r.toMap()).toList();
      _computeAggregates();
    } catch (e) {
      _errorMessage = 'DB load error: ${e.toString()}';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _computeAggregates() {
    _dailySpending.clear();
    _digitalTotal = 0.0;
    _cashTotal = 0.0;

    for (final m in _transactions) {
      final DateTime date = (m['date'] is String)
          ? DateTime.tryParse(m['date']) ?? DateTime.now()
          : (m['date'] as DateTime);
      final key = _dateKey(date);
      final amt = (m['amount'] is num)
          ? (m['amount'] as num).toDouble()
          : double.tryParse(m['amount'].toString()) ?? 0.0;
      final channel = (m['channel'] ?? 'Digital').toString();
      final txnType = (m['txn_type'] ?? 'Debit').toString();

      if (txnType == 'Debit') {
        _dailySpending.update(
          key,
          (v) => v + amt.abs(),
          ifAbsent: () => amt.abs(),
        );

        if (channel == 'Digital') {
          _digitalTotal -= amt.abs();
        } else {
          _cashTotal -= amt.abs();
        }
      } else if (txnType == 'Credit') {
        if (channel == 'Digital') {
          _digitalTotal += amt.abs();
        } else {
          _cashTotal += amt.abs();
        }
      }
    }
  }

  String _dateKey(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day).toIso8601String().split('T').first;

  /// Filter and order transactions for display
  List<Map<String, dynamic>> _filteredTransactions() {
    var list = _transactions;
    if (_filterMode == 'Digital') {
      list = list
          .where((t) => (t['channel'] ?? 'Digital') == 'Digital')
          .toList();
    } else if (_filterMode == 'Cash') {
      list = list.where((t) => (t['channel'] ?? 'Digital') == 'Cash').toList();
    }
    if (_selectedDate != null) {
      final key = _dateKey(_selectedDate!);
      list = list
          .where(
            (t) =>
                _dateKey(
                  (t['date'] is String)
                      ? DateTime.tryParse(t['date']) ?? DateTime.now()
                      : (t['date'] as DateTime),
                ) ==
                key,
          )
          .toList();
    }
    // sort descending by createdAt or date
    list.sort((a, b) {
      final da = (a['date'] is String)
          ? DateTime.tryParse(a['date']) ?? DateTime.now()
          : (a['date'] as DateTime);
      final dbt = (b['date'] is String)
          ? DateTime.tryParse(b['date']) ?? DateTime.now()
          : (b['date'] as DateTime);
      return dbt.compareTo(da);
    });
    return list;
  }

  /// Add a manual cash transaction via dialog
  Future<void> _showAddCashDialog() async {
    final _formKey = GlobalKey<FormState>();
    String desc = '';
    String category = 'Cash';
    double amount = 0.0;
    String type = 'Debit'; // Debit/ Credit
    DateTime date = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Cash Transaction'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    onSaved: (v) => desc = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty || double.tryParse(v) == null)
                        ? 'Enter valid amount'
                        : null,
                    onSaved: (v) => amount = double.tryParse(v ?? '0') ?? 0.0,
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: const [
                      DropdownMenuItem(
                        value: 'Debit',
                        child: Text('Expense (Debit)'),
                      ),
                      DropdownMenuItem(
                        value: 'Credit',
                        child: Text('Income (Credit)'),
                      ),
                    ],
                    onChanged: (v) => type = v ?? 'Debit',
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Date: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: date,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            date = picked;
                            // force rebuild dialog
                            (ctx as Element).markNeedsBuild();
                          }
                        },
                        child: Text(
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();
                  final txn = TransactionModel(
                    id: UniqueKey().toString(),
                    uid: FirebaseAuth.instance.currentUser?.uid ?? 'local',
                    sms: desc,
                    sender: 'Cash',
                    category: category,
                    amount: amount,
                    txnType: type,
                    mode: 'Cash',
                    channel: 'Cash',
                    refNo: null,
                    account: null,
                    date: date,
                    balance: null,
                    createdAt: DateTime.now(),
                  );
                  await _db.upsertTransaction(txn);
                  await _loadFromDb();
                  if (mounted) Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Image.asset('assets/google_logo.png', height: 32, width: 32),
        const SizedBox(width: 8),
        Text('SpendSense', style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }

  Widget _buildCalendarDropdown() {
    return TextButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              height: 400,
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _selectedDate ?? DateTime.now(),
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDate, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedDate == null
                ? 'Select Date'
                : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ],
      ),
    );
  }

  /// Build Cash & Digital summary tiles
  Widget _buildWalletTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => setState(() {
                  _filterMode = 'Cash';
                }),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${_cashTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.wallet, color: Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => setState(() {
                  _filterMode = 'Digital';
                }),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${_digitalTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.payments, color: Colors.cyanAccent),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      bottomNavigationBar: const MyNavbar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCashDialog,
        label: const Text('Add Cash'),
        icon: const Icon(Icons.add),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: _buildHeader(),
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    SizedBox(height: kToolbarHeight + 40),
                    _buildCalendarDropdown(),
                    _buildWalletTiles(),
                  ],
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () => _loadFromDb(),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Filter toggle buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _filterMode == 'All',
                            onSelected: (s) =>
                                setState(() => _filterMode = 'All'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Digital'),
                            selected: _filterMode == 'Digital',
                            onSelected: (s) =>
                                setState(() => _filterMode = 'Digital'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Cash'),
                            selected: _filterMode == 'Cash',
                            onSelected: (s) =>
                                setState(() => _filterMode = 'Cash'),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              // toggle date filter off
                              setState(() => _selectedDate = null);
                            },
                            icon: Icon(
                              Icons.clear_all,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                            tooltip: 'Clear date filter',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Transaction list
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                _errorMessage.isNotEmpty
                                    ? _errorMessage
                                    : 'No transactions',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onBackground,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final tx = filtered[index];
                                return TransactionTile(
                                  transaction: tx,
                                  onDelete: (id) async {
                                    await _db.deleteTransaction(id);
                                    await _loadFromDb();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Simple in-file Transaction model and SQLite helper
class TransactionModel {
  final String id;
  final String uid;
  final String sms;
  final String sender;
  final String category;
  final double amount;
  final String txnType; // Credit / Debit
  final String mode; // e.g., UPI, ATM, Cash
  final String channel; // 'Digital' or 'Cash'
  final String? refNo;
  final String? account;
  final DateTime date;
  final double? balance;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.uid,
    required this.sms,
    required this.sender,
    required this.category,
    required this.amount,
    required this.txnType,
    required this.mode,
    required this.channel,
    this.refNo,
    this.account,
    required this.date,
    this.balance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'sms': sms,
    'sender': sender,
    'category': category,
    'amount': amount,
    'txn_type': txnType,
    'mode': mode,
    'channel': channel,
    'ref_no': refNo,
    'account': account,
    'date': date.toIso8601String(),
    'balance': balance,
    'created_at': createdAt.toIso8601String(),
  };

  static TransactionModel fromMap(Map<String, dynamic> m) {
    return TransactionModel(
      id: m['id'].toString(),
      uid: m['uid'].toString(),
      sms: m['sms'].toString(),
      sender: m['sender'].toString(),
      category: m['category'].toString(),
      amount: (m['amount'] is num)
          ? (m['amount'] as num).toDouble()
          : double.tryParse(m['amount'].toString()) ?? 0.0,
      txnType: m['txn_type'].toString(),
      mode: m['mode'].toString(),
      channel: m['channel'].toString(),
      refNo: m['ref_no']?.toString(),
      account: m['account']?.toString(),
      date: DateTime.tryParse(m['date'].toString()) ?? DateTime.now(),
      balance: (m['balance'] is num)
          ? (m['balance'] as num).toDouble()
          : (m['balance'] == null
                ? null
                : double.tryParse(m['balance'].toString())),
      createdAt:
          DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now(),
    );
  }
}

class TransactionDb {
  static Database? _db;

  static Future<TransactionDb> open() async {
    if (_db != null) return TransactionDb();
    final docs = await getApplicationDocumentsDirectory();
    final path = p.join(docs.path, 'spendsense_transactions.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE transactions(
          id TEXT PRIMARY KEY,
          uid TEXT,
          sms TEXT,
          sender TEXT,
          category TEXT,
          amount REAL,
          txn_type TEXT,
          mode TEXT,
          channel TEXT,
          ref_no TEXT,
          account TEXT,
          date TEXT,
          balance REAL,
          created_at TEXT
        );
      ''');
      },
    );
    return TransactionDb();
  }

  Future<void> upsertTransaction(TransactionModel t) async {
    final db = _db!;
    await db.insert(
      'transactions',
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = _db!;
    final rows = await db.query('transactions');
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  Future<void> deleteTransaction(String id) async {
    final db = _db!;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // optional: query by date or channel etc.
}

/// Inline TransactionTile widget (standalone)
class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final FutureOr<void> Function(String id)? onDelete;

  const TransactionTile({super.key, required this.transaction, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final id = transaction['id'].toString();
    final title = (transaction['sms']?.toString().isNotEmpty ?? false)
        ? transaction['sms'].toString()
        : (transaction['category']?.toString() ?? 'Transaction');
    final amount = (transaction['amount'] is num)
        ? (transaction['amount'] as num).toDouble()
        : double.tryParse(transaction['amount'].toString()) ?? 0.0;
    final txnType = (transaction['txn_type']?.toString() ?? 'Debit');
    final channel = (transaction['channel']?.toString() ?? 'Digital');
    final sender = (transaction['sender']?.toString() ?? '');
    final date = (transaction['date'] is String)
        ? (DateTime.tryParse(transaction['date']) ?? DateTime.now())
        : (transaction['date'] as DateTime);
    final amountText = '₹${amount.toStringAsFixed(2)}';
    final isCredit = txnType.toLowerCase() == 'credit';
    final primaryColor = Theme.of(context).colorScheme.onBackground;

    Widget leading;
    if (channel == 'Digital') {
      // show arrow
      leading = CircleAvatar(
        radius: 20,
        backgroundColor: isCredit ? Colors.green.shade700 : Colors.red.shade700,
        child: Icon(
          isCredit ? Icons.arrow_upward : Icons.arrow_downward,
          color: Colors.white,
        ),
      );
    } else {
      // cash: show rupee symbol with color
      leading = CircleAvatar(
        radius: 20,
        backgroundColor: isCredit ? Colors.green.shade700 : Colors.red.shade700,
        child: Text(
          '₹',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          sender.isNotEmpty
              ? '$sender • ${_formatDate(date)}'
              : _formatDate(date),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amountText,
              style: TextStyle(
                color: isCredit ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                if (onDelete != null) onDelete!(id);
              },
              child: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 18,
              ),
            ),
          ],
        ),
        onTap: () {
          // optional: show details
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Transaction Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount: $amountText'),
                  Text('Type: $txnType'),
                  Text('Channel: $channel'),
                  Text('Sender: $sender'),
                  Text('Category: ${transaction['category'] ?? 'Other'}'),
                  Text('Date: ${_formatDate(date)}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
