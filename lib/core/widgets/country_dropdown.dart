import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountryDropdown extends StatefulWidget {
  final String selectedCountryCode;
  final ValueChanged<String> onCountryChanged;

  const CountryDropdown({
    super.key,
    required this.selectedCountryCode,
    required this.onCountryChanged,
  });

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  List<Map<String, dynamic>> _countries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/countries.json');
      final List<dynamic> list = json.decode(jsonString);
      setState(() {
        _countries = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _countries = [
          {'code': 'IN', 'name': 'India'},
          {'code': 'US', 'name': 'United States'},
        ];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LinearProgressIndicator();
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: widget.selectedCountryCode.isEmpty ? 'IN' : widget.selectedCountryCode,
      decoration: InputDecoration(
        labelText: 'Country',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _countries.map((c) {
        return DropdownMenuItem<String>(
          value: c['code'] as String,
          child: Text(c['name'] as String, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          widget.onCountryChanged(val);
        }
      },
    );
  }
}
