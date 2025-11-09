import 'package:beacon/views/mobile/auth_service.dart';
import 'package:beacon/views/mobile/database_service.dart';
import 'package:beacon/data/constants.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class CreateBeaconPage extends StatefulWidget {
  const CreateBeaconPage({super.key});

  @override
  State<CreateBeaconPage> createState() => _CreateBeaconPageState();
}

class _CreateBeaconPageState extends State<CreateBeaconPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _expiryTime = TimeOfDay.now();
  String _selectedCategory = BeaconCategories.defaultCategory;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createBeacon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = authService.value.currentuser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current location
      Location location = Location();
      LocationData locationData = await location.getLocation();

      final beaconData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'expiryDate': DateTime(
          _expiryDate.year,
          _expiryDate.month,
          _expiryDate.day,
          _expiryTime.hour,
          _expiryTime.minute,
        ).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': user.uid,
        'status': 'active',
        'location': {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
        },
      };

      final beaconId = DateTime.now().millisecondsSinceEpoch.toString();
      await DatabaseService().create(
        path: 'beacons/$beaconId',
        data: beaconData,
      );

      // Also add to user's beacons
      await DatabaseService().update(
        path: 'users/${user.uid}/beacons',
        data: {beaconId: true},
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _expiryTime,
    );
    if (picked != null) {
      setState(() {
        _expiryTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Beacon'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Beacon',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Beacon Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.label_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a name for your beacon';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description (Optional)',
                              hintText: 'Add a short description...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                            maxLines: 3,
                            maxLength: 200,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: BeaconCategories.all.map((category) {
                              final isSelected = category == _selectedCategory;
                              return AnimatedScale(
                                duration: Duration(milliseconds: 200),
                                scale: isSelected ? 1.05 : 1.0,
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                  elevation: isSelected ? 4 : 0,
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Expiry',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _selectDate,
                                  icon: Icon(Icons.calendar_today),
                                  label: Text(
                                    '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _selectTime,
                                  icon: Icon(Icons.access_time),
                                  label: Text(
                                    _expiryTime.format(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _createBeacon,
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Create Beacon'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}