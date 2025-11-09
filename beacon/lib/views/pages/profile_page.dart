import 'package:beacon/data/constants.dart';
import 'package:beacon/views/mobile/auth_service.dart';
import 'package:beacon/views/pages/change_password.dart';
import 'package:beacon/views/pages/update_username.dart';
import 'package:beacon/views/pages/delete_account.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:beacon/views/pages/welcome_page.dart';
import 'package:flutter_color_picker_wheel/models/button_behaviour.dart';
import 'package:flutter_color_picker_wheel/widgets/flutter_color_picker_wheel.dart';
import 'package:beacon/views/mobile/database_service.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  final TextEditingController _aboutMeController = TextEditingController();
  bool _editingAboutMe = false;
  String _settingsMessage = "";
  String _displayName = "";
  bool _isLoading = true;
  // Character selection state
  final List<String> _characterAssets = const [
    'assets/characters/char.jpg',
    'assets/characters/char1.jpg',
    'assets/characters/char2.jpg',
    'assets/characters/char4.jpg',
    'assets/characters/char5.jpg',
    'assets/characters/char6.jpg',
    'assets/characters/char7.jpg',
  ];
  int _currentCharIndex = 0;
  String? _selectedCharacterAsset;

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = authService.value.currentuser;
      if (user != null) {
        final snapshot = await DatabaseService().read(path: "users/${user.uid}");
        if (snapshot != null) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _displayName = data['displayName'] ?? 'Anonymous';
            _aboutMeController.text = data['about'];
            final savedChar = data['character']?.toString();
            if (savedChar != null && _characterAssets.contains(savedChar)) {
              _selectedCharacterAsset = savedChar;
              _currentCharIndex = _characterAssets.indexOf(savedChar);
            } else {
              _selectedCharacterAsset = _characterAssets.first;
              _currentCharIndex = 0;
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _settingsMessage = "Failed to load user data";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAboutMe(String newAbout) async {
    try {
      final user = authService.value.currentuser;
      if (user != null) {
        await DatabaseService().update(
          path: "users/${user.uid}",
          data: {"about": newAbout},
        );
        setState(() {
          _settingsMessage = "About me updated successfully!";
        });
      }
    } catch (e) {
      setState(() {
        _settingsMessage = "Failed to update about me";
      });
    }
  }

  Future<void> _updateCharacter(String assetPath) async {
    try {
      final user = authService.value.currentuser;
      if (user != null) {
        await DatabaseService().update(
          path: "users/${user.uid}",
          data: {"character": assetPath},
        );
        setState(() {
          _settingsMessage = "Character updated!";
        });
      }
    } catch (e) {
      setState(() {
        _settingsMessage = "Failed to update character";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _loadUserData(); // Load user data when the page initializes
  }

  @override
  void dispose() {
    _controller.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  void logout() async {
    try {
      await authService.value.signOut();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
        return WelcomePage();
      },), (route) => false);
    } on FirebaseAuthException catch (e) {
      setState(() { _settingsMessage = e.message ?? "Logout error"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: Colors.white),
                          iconSize: 32,
                          onPressed: _isLoading ? null : () async {
                            setState(() {
                              _currentCharIndex = (_currentCharIndex - 1 + _characterAssets.length) % _characterAssets.length;
                              _selectedCharacterAsset = _characterAssets[_currentCharIndex];
                            });
                            await _updateCharacter(_selectedCharacterAsset!);
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(_selectedCharacterAsset ?? _characterAssets.first),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: Colors.white),
                          iconSize: 32,
                          onPressed: _isLoading ? null : () async {
                            setState(() {
                              _currentCharIndex = (_currentCharIndex + 1) % _characterAssets.length;
                              _selectedCharacterAsset = _characterAssets[_currentCharIndex];
                            });
                            await _updateCharacter(_selectedCharacterAsset!);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (_isLoading)
                      CircularProgressIndicator(color: Colors.white)
                    else
                      Text(
                        _displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Character chooser section
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.face_retouching_natural, color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: 8),
                          Text(
                            'Choose your character',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _characterAssets.length,
                          separatorBuilder: (_, __) => SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final asset = _characterAssets[index];
                            final isSelected = index == _currentCharIndex;
                            return GestureDetector(
                              onTap: () async {
                                setState(() {
                                  _currentCharIndex = index;
                                  _selectedCharacterAsset = asset;
                                });
                                await _updateCharacter(asset);
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                padding: EdgeInsets.all(isSelected ? 6 : 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: isSelected
                                      ? LinearGradient(colors: [
                                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                        ])
                                      : null,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outlineVariant,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    asset,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('About Me', style: KTextStyle.titleTealText.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 8,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_editingAboutMe)
                          Column(
                            children: [
                              TextField(
                                controller: _aboutMeController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: "Edit About Me",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: () async {
                                      await _updateAboutMe(_aboutMeController.text);
                                      if (mounted) {
                                        setState(() { _editingAboutMe = false; });
                                      }
                                    },
                                    child: Text("Save"),
                                  ),
                                  SizedBox(width: 10),
                                  TextButton(
                                    onPressed: () async {
                                      await _loadUserData(); // Reload original data
                                      if (mounted) {
                                        setState(() { _editingAboutMe = false; });
                                      }
                                    },
                                    child: Text("Cancel"),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(_aboutMeController.text, style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                                onPressed: () {
                                  setState(() { _editingAboutMe = true; });
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Woljie Color: ", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  SizedBox(width: 10,),
                  WheelColorPicker(
                    onSelect: (value) {},
                    defaultColor: Theme.of(context).colorScheme.primary,
                    behaviour: ButtonBehaviour.clickToOpen,
                    innerRadius: 60,
                    buttonSize: 40,
                    pieceHeight: 25,
                  ),
                ],
              ),
              SizedBox(height: 30),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 8,
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      SizedBox(height: 10),
                      ListTile(
                        leading: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                        title: Text("Update Username"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UpdateUsernamePage()),
                          );
                          if (result == true) {
                            setState(() { _settingsMessage = "Username updated successfully!"; });
                          }
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                        title: Text("Change Password"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                          );
                          if (result == true) {
                            setState(() { _settingsMessage = "Password changed successfully!"; });
                          }
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.delete_forever, color: Colors.red),
                        title: Text("Delete Account", style: TextStyle(color: Colors.red)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Delete Account"),
                            content: Text("Are you sure you want to delete your account? This action cannot be undone."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Cancel"),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                                    return DeleteAccountPage();
                                  }));
                                },
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                child: Text("Delete"),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 400),
                        child: _settingsMessage.isNotEmpty
                            ? Text(_settingsMessage, key: ValueKey(_settingsMessage), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                            : SizedBox.shrink(),
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
                        title: Text("Logout", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        onTap: logout,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
