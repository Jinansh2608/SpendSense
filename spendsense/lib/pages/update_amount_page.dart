
import 'package:flutter/material.dart';
import 'package:spendsense/components/recursiveBuilder.dart';
import 'package:spendsense/constants/colors/colors.dart';

class UpdateAmountPage extends StatefulWidget {
  final Payment payment;

  const UpdateAmountPage({super.key, required this.payment});

  @override
  _UpdateAmountPageState createState() => _UpdateAmountPageState();
}

class _UpdateAmountPageState extends State<UpdateAmountPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.payment.amount?.toString() ?? '');
  }

  void _saveAmount() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount != null) {
        final updatedPayment = Payment(
          id: widget.payment.id,
          title: widget.payment.title,
          amount: amount,
          category: widget.payment.category,
          paymentMode: widget.payment.paymentMode,
          note: widget.payment.note,
          dueDate: widget.payment.dueDate,
          recurrence: widget.payment.recurrence,
          customDaysOfWeek: widget.payment.customDaysOfWeek,
          status: widget.payment.status,
        );
        Navigator.pop(context, updatedPayment);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ycolor.gray,
      appBar: AppBar(
        title: Text('Update Amount', style: TextStyle(color: Ycolor.whitee)),
        backgroundColor: Ycolor.gray,
        elevation: 0,
        iconTheme: IconThemeData(color: Ycolor.whitee),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                style: TextStyle(color: Ycolor.whitee),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Ycolor.gray10),
                  filled: true,
                  fillColor: Ycolor.gray80,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAmount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Ycolor.primarycolor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Amount',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Ycolor.whitee),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
