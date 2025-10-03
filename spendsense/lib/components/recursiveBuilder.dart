import 'package:flutter/material.dart';
import 'dart:async';
import 'package:spendsense/components/notification_service.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:intl/intl.dart';
import 'package:spendsense/pages/update_amount_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// --- Database Helper ---
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = p.join(await getDatabasesPath(), 'payments.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE payments(
        id TEXT PRIMARY KEY,
        title TEXT,
        amount REAL,
        category TEXT,
        paymentMode TEXT,
        note TEXT,
        dueDate TEXT,
        recurrence TEXT,
        status TEXT,
        customDaysOfWeek TEXT
      )
      ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE payments ADD COLUMN note TEXT');
    }
  }

  Future<void> insertPayment(Payment payment) async {
    final db = await database;
    await db.insert('payments', payment.toMap());
  }

  Future<void> updatePayment(Payment payment) async {
    final db = await database;
    await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<List<Payment>> getPayments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('payments');
    return List.generate(maps.length, (i) {
      return Payment.fromMap(maps[i]);
    });
  }
}


// --- Enums and Models ---
enum PaymentStatus { pending, paid, overdue }
enum Recurrence { none, daily, weekly, monthly, custom }
enum PaymentCategory { none, bill, emi, dailyExpense, other }
enum PaymentMode { none, cash, card, upi, wallet }

class Payment {
  final String id;
  late final String title;
  late final double? amount;
  late final PaymentCategory category;
  late final PaymentMode paymentMode;
  late final String? note;
  late final DateTime dueDate;
  late final Recurrence recurrence;
  late final List<int>? customDaysOfWeek;
  PaymentStatus status;

  Payment({
    required this.id,
    required this.title,
    this.amount,
    this.category = PaymentCategory.none,
    this.paymentMode = PaymentMode.none,
    this.note,
    required this.dueDate,
    this.recurrence = Recurrence.none,
    this.status = PaymentStatus.pending,
    this.customDaysOfWeek,
  }) {
    if (recurrence == Recurrence.custom && (customDaysOfWeek == null || customDaysOfWeek!.isEmpty)) {
      throw ArgumentError('customDaysOfWeek must be provided for custom recurrence.');
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category.toString(),
        'paymentMode': paymentMode.toString(),
        'note': note,
        'dueDate': dueDate.toIso8601String(),
        'recurrence': recurrence.toString(),
        'status': status.toString(),
        'customDaysOfWeek': customDaysOfWeek?.join(','),
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        amount: (map['amount'])?.toDouble(),
        category: PaymentCategory.values.firstWhere((e) => e.toString() == map['category'], orElse: () => PaymentCategory.none),
        paymentMode: PaymentMode.values.firstWhere((e) => e.toString() == map['paymentMode'], orElse: () => PaymentMode.none),
        note: map['note'],
        dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
        recurrence: Recurrence.values.firstWhere((e) => e.toString() == map['recurrence'], orElse: () => Recurrence.none),
        status: PaymentStatus.values.firstWhere((e) => e.toString() == map['status'], orElse: () => PaymentStatus.pending),
        customDaysOfWeek: map['customDaysOfWeek'] != null && map['customDaysOfWeek'].isNotEmpty ? map['customDaysOfWeek'].split(',').map<int>(int.parse).toList() : null,
      );
}

// --- Main Dashboard ---
class PaymentDashboard extends StatefulWidget {
  const PaymentDashboard({super.key});

  @override
  _PaymentDashboardState createState() => _PaymentDashboardState();
}

class _PaymentDashboardState extends State<PaymentDashboard> {
  List<Payment> _payments = [];
  final NotificationService _notificationService = NotificationService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _notificationService.init(onNotificationTap: _onNotificationTap);
    _loadPaymentsFromDb();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _updatePaymentStatuses());
  }

  void _onNotificationTap(String? payload) async {
    if (payload == null) return;
    // We need to load the fresh list from DB to make sure we have the payment
    await _loadPaymentsFromDb();
    final matchingPayments = _payments.where((p) => p.id == payload);
    if (matchingPayments.isNotEmpty) {
      _navigateToEditPage(matchingPayments.first);
    }
  }

  void _navigateToEditPage(Payment payment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPaymentPage(payment: payment)),
    );
    if (result is Payment) {
      _updatePayment(result);
    }
  }

  void _navigateToUpdateAmountPage(Payment payment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateAmountPage(payment: payment)),
    );
    if (result is Payment) {
      _updatePayment(result);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPaymentsFromDb() async {
    final payments = await _dbHelper.getPayments();
    setState(() {
      _payments = payments;
    });
    _generateRecurringPayments();
  }

  void _updatePaymentStatuses() {
    for (var payment in _payments) {
      if (payment.status == PaymentStatus.pending && payment.dueDate.isBefore(DateTime.now())) {
        payment.status = PaymentStatus.overdue;
        _updatePayment(payment);
      }
    }
  }

  void _generateRecurringPayments() {
    for (var payment in _payments) {
      if (payment.recurrence != Recurrence.none && payment.status == PaymentStatus.paid) {
        DateTime nextDueDate = payment.dueDate;
        while (nextDueDate.isBefore(DateTime.now())) {
          switch (payment.recurrence) {
            case Recurrence.daily:
              nextDueDate = nextDueDate.add(const Duration(days: 1));
              break;
            case Recurrence.weekly:
              nextDueDate = nextDueDate.add(const Duration(days: 7));
              break;
            case Recurrence.monthly:
              nextDueDate = DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
              break;
            case Recurrence.custom:
              if (payment.customDaysOfWeek != null && payment.customDaysOfWeek!.isNotEmpty) {
                nextDueDate = _findNextCustomDay(nextDueDate, payment.customDaysOfWeek!);
              }
              break;
            case Recurrence.none:
              break;
          }
        }

        final isAlreadyCreated = _payments.any((p) => p.id == payment.id && p.dueDate == nextDueDate);
        if (!isAlreadyCreated) {
          final newPayment = Payment(
            id: payment.id, // Re-use the ID for the recurring series
            title: payment.title,
            dueDate: nextDueDate,
            recurrence: payment.recurrence,
            customDaysOfWeek: payment.customDaysOfWeek,
            category: payment.category,
            paymentMode: payment.paymentMode,
            status: PaymentStatus.pending, // New instance is always pending
          );
          _addPayment(newPayment);
        }
      }
    }
  }

  DateTime _findNextCustomDay(DateTime currentDate, List<int> customDays) {
    DateTime nextDate = currentDate.add(const Duration(days: 1));
    while (!customDays.contains(nextDate.weekday)) {
      nextDate = nextDate.add(const Duration(days: 1));
    }
    return nextDate;
  }

  void _updatePayment(Payment payment) async {
    await _dbHelper.updatePayment(payment);
    _loadPaymentsFromDb();
  }

  void _addPayment(Payment payment) async {
    await _dbHelper.insertPayment(payment);
    _loadPaymentsFromDb();
    _notificationService.scheduleNotification(
      id: payment.id.hashCode,
      title: 'Payment Reminder',
      body: 'Your payment for ${payment.title} is due today.',
      scheduleTime: payment.dueDate,
      payload: payment.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _payments.where((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.overdue).toList();
    final history = _payments.where((p) => p.status == PaymentStatus.paid).toList();

    return Scaffold(
      backgroundColor: Ycolor.gray,
      appBar: AppBar(
        title: Text('Payment Reminders', style: TextStyle(fontWeight: FontWeight.bold, color: Ycolor.whitee)),
        backgroundColor: Ycolor.gray,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPaymentsFromDb,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Ycolor.whitee),
              ),
              const SizedBox(height: 10),
              UpcomingPayments(payments: upcoming, onEditTap: _navigateToUpdateAmountPage),
              const SizedBox(height: 30),
              Text(
                'History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Ycolor.whitee),
              ),
              const SizedBox(height: 10),
              PaymentHistory(payments: history),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPaymentPage()),
          );
          if (result is Payment) {
            _addPayment(result);
          }
        },
        backgroundColor: Ycolor.primarycolor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Upcoming Payments ---
class UpcomingPayments extends StatelessWidget {
  final List<Payment> payments;
  final Function(Payment) onEditTap;

  const UpcomingPayments({super.key, required this.payments, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('No upcoming payments!', style: TextStyle(fontSize: 16, color: Ycolor.gray10)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final isOverdue = payment.dueDate.isBefore(DateTime.now());

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Ycolor.gray80,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Icon(Icons.notifications, color: isOverdue ? Colors.redAccent : Ycolor.primarycolor),
            title: Text(payment.title, style: TextStyle(fontWeight: FontWeight.bold, color: Ycolor.whitee)),
            subtitle: Text(
              'Due: ${DateFormat.yMMMd().format(payment.dueDate)} at ${DateFormat.jm().format(payment.dueDate)}',
              style: TextStyle(color: isOverdue ? Colors.redAccent : Ycolor.gray10),
            ),
            trailing: Text(
              payment.amount != null ? '₹${payment.amount!.toStringAsFixed(2)}' : 'Add Amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: payment.amount != null ? Ycolor.whitee : Ycolor.primarycolor,
              ),
            ),
            onTap: () => onEditTap(payment),
          ),
        );
      },
    );
  }
}

// --- Payment History ---
class PaymentHistory extends StatelessWidget {
  final List<Payment> payments;

  const PaymentHistory({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('No payment history.', style: TextStyle(fontSize: 16, color: Ycolor.gray10)),
        ),
      );
    }

    final sortedPayments = List<Payment>.from(payments)..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedPayments.length,
      itemBuilder: (context, index) {
        final payment = sortedPayments[index];
        final iconData = _getIconForStatus(payment.status);

        return Card(
          elevation: 1,
          color: Ycolor.gray80,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Icon(iconData.icon, color: iconData.color),
            title: Text(payment.title, style: TextStyle(fontWeight: FontWeight.w500, color: Ycolor.whitee)),
            subtitle: Text(
              '${payment.category.toString().split('.').last.capitalize()} - ${payment.paymentMode.toString().split('.').last.capitalize()}',
              style: TextStyle(color: Ycolor.gray10),
            ),
            trailing: Text(
              payment.amount != null ? '₹${payment.amount!.toStringAsFixed(2)}' : '-',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Ycolor.gray10,
              ),
            ),
          ),
        );
      },
    );
  }

  _IconData _getIconForStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return _IconData(icon: Icons.check_circle, color: Colors.green, text: 'Paid');
      case PaymentStatus.overdue:
        return _IconData(icon: Icons.error, color: Colors.orange, text: 'Overdue');
      default:
        return _IconData(icon: Icons.history, color: Ycolor.gray10, text: 'Logged');
    }
  }
}

class _IconData {
  final IconData icon;
  final Color color;
  final String text;
  _IconData({required this.icon, required this.color, required this.text});
}

// --- Add Payment Page ---
class AddPaymentPage extends StatefulWidget {
  const AddPaymentPage({super.key});

  @override
  _AddPaymentPageState createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Recurrence _selectedRecurrence = Recurrence.none;
  PaymentCategory _selectedCategory = PaymentCategory.none;
  PaymentMode _selectedPaymentMode = PaymentMode.none;
  final List<bool> _selectedDays = List.filled(7, false);

  void _savePayment({bool markAsPaid = false}) {
    if (_formKey.currentState!.validate()) {
      final amount = _amountController.text.isNotEmpty ? double.tryParse(_amountController.text) : null;

      List<int>? customDays;
      if (_selectedRecurrence == Recurrence.custom) {
        customDays = [];
        for (int i = 0; i < _selectedDays.length; i++) {
          if (_selectedDays[i]) {
            customDays.add(i + 1);
          }
        }
        if (customDays.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one day for custom recurrence.'), backgroundColor: Colors.redAccent),
          );
          return;
        }
      }

      final newDueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final payment = Payment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        amount: amount,
        category: _selectedCategory,
        paymentMode: _selectedPaymentMode,
        note: _noteController.text,
        dueDate: newDueDate,
        recurrence: _selectedRecurrence,
        customDaysOfWeek: customDays,
      );

      Navigator.pop(context, payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ycolor.gray,
      appBar: AppBar(
        title: Text('Add Payment', style: TextStyle(color: Ycolor.whitee)),
        backgroundColor: Ycolor.gray,
        elevation: 0,
        iconTheme: IconThemeData(color: Ycolor.whitee),
      ),
      body: _PaymentForm(
        formKey: _formKey,
        titleController: _titleController,
        amountController: _amountController,
        noteController: _noteController,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedRecurrence: _selectedRecurrence,
        selectedCategory: _selectedCategory,
        selectedPaymentMode: _selectedPaymentMode,
        selectedDays: _selectedDays,
        onDateSelected: (date) => setState(() => _selectedDate = date),
        onTimeSelected: (time) => setState(() => _selectedTime = time),
        onRecurrenceChanged: (recurrence) => setState(() => _selectedRecurrence = recurrence),
        onCategoryChanged: (category) => setState(() => _selectedCategory = category),
        onPaymentModeChanged: (mode) => setState(() => _selectedPaymentMode = mode),
        onDaySelected: (index, selected) => setState(() => _selectedDays[index] = selected),
        onSave: _savePayment,
      ),
    );
  }
}

// --- Edit Payment Page ---
class EditPaymentPage extends StatefulWidget {
  final Payment payment;
  const EditPaymentPage({super.key, required this.payment});

  @override
  _EditPaymentPageState createState() => _EditPaymentPageState();
}

class _EditPaymentPageState extends State<EditPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late Recurrence _selectedRecurrence;
  late PaymentCategory _selectedCategory;
  late PaymentMode _selectedPaymentMode;
  late List<bool> _selectedDays;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.payment.title);
    _amountController = TextEditingController(text: widget.payment.amount?.toString());
    _noteController = TextEditingController(text: widget.payment.note);
    _selectedDate = widget.payment.dueDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.payment.dueDate);
    _selectedRecurrence = widget.payment.recurrence;
    _selectedCategory = widget.payment.category;
    _selectedPaymentMode = widget.payment.paymentMode;
    _selectedDays = List.filled(7, false);
    if (widget.payment.customDaysOfWeek != null) {
      for (var day in widget.payment.customDaysOfWeek!) {
        _selectedDays[day - 1] = true;
      }
    }
  }

  void _savePayment({bool markAsPaid = false}) {
    if (_formKey.currentState!.validate()) {
      final amount = _amountController.text.isNotEmpty ? double.tryParse(_amountController.text) : null;

      List<int>? customDays;
      if (_selectedRecurrence == Recurrence.custom) {
        customDays = [];
        for (int i = 0; i < _selectedDays.length; i++) {
          if (_selectedDays[i]) {
            customDays.add(i + 1);
          }
        }
        if (customDays.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one day for custom recurrence.'), backgroundColor: Colors.redAccent),
          );
          return;
        }
      }

      final newDueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final payment = Payment(
        id: widget.payment.id,
        title: _titleController.text,
        amount: amount,
        category: _selectedCategory,
        paymentMode: _selectedPaymentMode,
        note: _noteController.text,
        dueDate: newDueDate,
        recurrence: _selectedRecurrence,
        customDaysOfWeek: customDays,
        status: markAsPaid ? PaymentStatus.paid : widget.payment.status,
      );

      Navigator.pop(context, payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ycolor.gray,
      appBar: AppBar(
        title: Text('Edit Payment', style: TextStyle(color: Ycolor.whitee)),
        backgroundColor: Ycolor.gray,
        elevation: 0,
        iconTheme: IconThemeData(color: Ycolor.whitee),
      ),
      body: _PaymentForm(
        formKey: _formKey,
        titleController: _titleController,
        amountController: _amountController,
        noteController: _noteController,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedRecurrence: _selectedRecurrence,
        selectedCategory: _selectedCategory,
        selectedPaymentMode: _selectedPaymentMode,
        selectedDays: _selectedDays,
        onDateSelected: (date) => setState(() => _selectedDate = date),
        onTimeSelected: (time) => setState(() => _selectedTime = time),
        onRecurrenceChanged: (recurrence) => setState(() => _selectedRecurrence = recurrence),
        onCategoryChanged: (category) => setState(() => _selectedCategory = category),
        onPaymentModeChanged: (mode) => setState(() => _selectedPaymentMode = mode),
        onDaySelected: (index, selected) => setState(() => _selectedDays[index] = selected),
        onSave: _savePayment,
        isEditing: true,
        paymentStatus: widget.payment.status,
      ),
    );
  }
}

// --- Common Payment Form ---
class _PaymentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final Recurrence selectedRecurrence;
  final PaymentCategory selectedCategory;
  final PaymentMode selectedPaymentMode;
  final List<bool> selectedDays;
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onTimeSelected;
  final Function(Recurrence) onRecurrenceChanged;
  final Function(PaymentCategory) onCategoryChanged;
  final Function(PaymentMode) onPaymentModeChanged;
  final Function(int, bool) onDaySelected;
  final Function({bool markAsPaid}) onSave;
  final bool isEditing;
  final PaymentStatus? paymentStatus;

  const _PaymentForm({
    required this.formKey,
    required this.titleController,
    required this.amountController,
    required this.noteController,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedRecurrence,
    required this.selectedCategory,
    required this.selectedPaymentMode,
    required this.selectedDays,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.onRecurrenceChanged,
    required this.onCategoryChanged,
    required this.onPaymentModeChanged,
    required this.onDaySelected,
    required this.onSave,
    this.isEditing = false,
    this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTextField(titleController, 'Title', 'Enter payment title'),
          const SizedBox(height: 16),
          _buildTextField(amountController, 'Amount (Optional)', 'Enter amount', keyboardType: const TextInputType.numberWithOptions(decimal: true), isOptional: true),
          const SizedBox(height: 16),
          _buildTextField(noteController, 'Note (Optional)', 'Add a note', isOptional: true, maxLines: 3),
          const SizedBox(height: 24),
          _buildCategorySelector(),
          const SizedBox(height: 24),
          _buildPaymentModeSelector(),
          const SizedBox(height: 24),
          _buildDatePicker(context),
          const SizedBox(height: 24),
          _buildTimePicker(context),
          const SizedBox(height: 24),
          _buildRecurrenceSelector(),
          if (selectedRecurrence == Recurrence.custom) ...[
            const SizedBox(height: 24),
            _buildDaySelector(),
          ],
          const SizedBox(height: 32),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  TextFormField _buildTextField(TextEditingController controller, String label, String hint, {TextInputType keyboardType = TextInputType.text, bool isOptional = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Ycolor.whitee),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Ycolor.gray10),
        hintText: hint,
        hintStyle: TextStyle(color: Ycolor.gray10),
        filled: true,
        fillColor: Ycolor.gray80,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Please enter a value';
        }
        if (keyboardType == const TextInputType.numberWithOptions(decimal: true) && value != null && value.isNotEmpty) {
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    return Card(
      color: Ycolor.gray80,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonFormField<PaymentCategory>(
          value: selectedCategory,
          onChanged: (PaymentCategory? newValue) {
            if (newValue != null) {
              onCategoryChanged(newValue);
            }
          },
          items: PaymentCategory.values.map((PaymentCategory category) {
            return DropdownMenuItem<PaymentCategory>(
              value: category,
              child: Text(category.toString().split('.').last.capitalize()),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Category',
            labelStyle: TextStyle(color: Ycolor.gray10),
            border: InputBorder.none,
          ),
          dropdownColor: Ycolor.gray80,
          style: TextStyle(color: Ycolor.whitee),
        ),
      ),
    );
  }

  Widget _buildPaymentModeSelector() {
    return Card(
      color: Ycolor.gray80,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonFormField<PaymentMode>(
          value: selectedPaymentMode,
          onChanged: (PaymentMode? newValue) {
            if (newValue != null) {
              onPaymentModeChanged(newValue);
            }
          },
          items: PaymentMode.values.map((PaymentMode mode) {
            return DropdownMenuItem<PaymentMode>(
              value: mode,
              child: Text(mode.toString().split('.').last.capitalize()),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Payment Mode',
            labelStyle: TextStyle(color: Ycolor.gray10),
            border: InputBorder.none,
          ),
          dropdownColor: Ycolor.gray80,
          style: TextStyle(color: Ycolor.whitee),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Card(
      color: Ycolor.gray80,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: Ycolor.primarycolor),
        title: Text('Due Date', style: TextStyle(color: Ycolor.whitee)),
        subtitle: Text(DateFormat.yMMMd().format(selectedDate), style: TextStyle(color: Ycolor.gray10)),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (picked != null && picked != selectedDate) {
            onDateSelected(picked);
          }
        },
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return Card(
      color: Ycolor.gray80,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.access_time, color: Ycolor.primarycolor),
        title: Text('Due Time', style: TextStyle(color: Ycolor.whitee)),
        subtitle: Text(selectedTime.format(context), style: TextStyle(color: Ycolor.gray10)),
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: selectedTime,
          );
          if (picked != null && picked != selectedTime) {
            onTimeSelected(picked);
          }
        },
      ),
    );
  }

  Widget _buildRecurrenceSelector() {
    return Card(
      color: Ycolor.gray80,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonFormField<Recurrence>(
          value: selectedRecurrence,
          onChanged: (Recurrence? newValue) {
            if (newValue != null) {
              onRecurrenceChanged(newValue);
            }
          },
          items: Recurrence.values.map((Recurrence recurrence) {
            return DropdownMenuItem<Recurrence>(
              value: recurrence,
              child: Text(recurrence.toString().split('.').last.capitalize()),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Recurrence',
            labelStyle: TextStyle(color: Ycolor.gray10),
            border: InputBorder.none,
          ),
          dropdownColor: Ycolor.gray80,
          style: TextStyle(color: Ycolor.whitee),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Card(
      color: Ycolor.gray80,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repeat on:', style: TextStyle(color: Ycolor.whitee, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(7, (index) {
                return ChoiceChip(
                  label: Text(days[index]),
                  selected: selectedDays[index],
                  onSelected: (selected) {
                    onDaySelected(index, selected);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    bool isPending = isEditing && paymentStatus != PaymentStatus.paid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => onSave(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Ycolor.primarycolor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(isEditing ? 'Update Payment' : 'Save Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Ycolor.whitee)),
        ),
        if (isPending)
          const SizedBox(height: 16),
        if (isPending)
          ElevatedButton(
            onPressed: () => onSave(markAsPaid: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save and Mark as Paid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Ycolor.whitee)),
          ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}