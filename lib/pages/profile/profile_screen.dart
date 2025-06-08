import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialLoading = true; // Add separate loading for initial load

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isInitialLoading = true;
    });
    
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null && _currentUser != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // In a real app, you would upload the image to a server
        // For this demo, we'll just update the local path
        final result = await AuthService.updateProfile(
          user: _currentUser!,
          profileImage: pickedFile.path,
        );

        if (result['success']) {
          setState(() {
            _currentUser = result['user'];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await AuthService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditProfileDialog() {
    if (_currentUser == null || _isLoading) return;

    final usernameController = TextEditingController(text: _currentUser!.username);
    final emailController = TextEditingController(text: _currentUser!.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _updateProfile(
                usernameController.text,
                emailController.text,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(String username, String email) async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.updateProfile(
        user: _currentUser!,
        newUsername: username,
        newEmail: email,
      );

      if (result['success']) {
        setState(() {
          _currentUser = result['user'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCourseImpressions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mobile Technology and Programming Course',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Course Impressions',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImpressionCard(
                        'Overall Experience',
                        '⭐⭐⭐⭐⭐',
                        'This course has been incredibly valuable in teaching mobile app development. The hands-on approach with Flutter made complex concepts easy to understand.',
                        Icons.star,
                        Colors.amber,
                      ),
                      const SizedBox(height: 16),
                      _buildImpressionCard(
                        'Technical Learning',
                        'Excellent',
                        'Learned comprehensive mobile development skills including:\n• Flutter framework\n• Dart programming\n• SQLite database\n• API integration\n• UI/UX design principles',
                        Icons.code,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildImpressionCard(
                        'Project Experience',
                        'Very Satisfying',
                        'Building this BookVerse app allowed me to apply theoretical knowledge practically. Working with real APIs, implementing authentication, and creating a functional app was rewarding.',
                        Icons.build,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildImpressionCard(
                        'Instructor Feedback',
                        'Supportive',
                        'The guidance provided throughout the course was excellent. Clear explanations and helpful feedback on assignments made learning effective.',
                        Icons.person,
                        Colors.purple,
                      ),
                      const SizedBox(height: 16),
                      _buildImpressionCard(
                        'Future Application',
                        'Highly Valuable',
                        'The skills learned in this course will be directly applicable to my future career in mobile development. Understanding Flutter opens up opportunities for cross-platform development.',
                        Icons.trending_up,
                        Colors.indigo,
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

  void _showSuggestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Suggestions & Feedback',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                    ),
                    const Text(
                      'Ideas for improvement',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSuggestionCard(
                        'App Improvements',
                        '• Add book reading progress tracking\n• Implement social features for book sharing\n• Include book reviews and ratings\n• Add offline reading capability\n• Integrate with physical bookstores',
                        Icons.lightbulb,
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildSuggestionCard(
                        'Course Enhancements',
                        '• More advanced Flutter topics\n• Backend development integration\n• App store deployment guidance\n• Performance optimization techniques\n• Accessibility best practices',
                        Icons.school,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildSuggestionCard(
                        'Technical Features',
                        '• Push notifications for new releases\n• Dark mode theme\n• Book recommendation AI\n• Voice search functionality\n• AR book preview',
                        Icons.settings,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildSuggestionCard(
                        'Learning Resources',
                        '• Video tutorials for complex topics\n• Code examples repository\n• Student collaboration platform\n• Industry guest lectures\n• Real-world project case studies',
                        Icons.menu_book,
                        Colors.purple,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Failed to load profile'),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        // Profile header - FIXED OVERFLOW ISSUES
                        SliverAppBar(
                          expandedHeight: 220, // Increased height to prevent overflow
                          pinned: true,
                          backgroundColor: Colors.indigo[800],
                          flexibleSpace: FlexibleSpaceBar(
                            background: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.indigo[800]!,
                                    Colors.indigo[600]!,
                                  ],
                                ),
                              ),
                              child: SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20), // Added horizontal padding
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 50), // Reduced top spacing
                                      // Profile image
                                      Stack(
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 3),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: _currentUser!.profileImage != null && 
                                                     File(_currentUser!.profileImage!).existsSync()
                                                  ? Image.file(
                                                      File(_currentUser!.profileImage!),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      color: Colors.white,
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 40,
                                                        color: Colors.indigo[800],
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: _isLoading ? null : _pickProfileImage,
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: _isLoading ? Colors.grey : Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.camera_alt,
                                                  size: 16,
                                                  color: Colors.indigo[800],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16), // Increased spacing
                                      
                                      // Username - FIXED WITH PROPER CONSTRAINTS
                                      SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          _currentUser!.username,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16, // Reduced font size
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 4), // Added small spacing
                                      
                                      // Email - FIXED WITH PROPER CONSTRAINTS
                                      SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          _currentUser!.email,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11, // Slightly reduced font size
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Profile content
                        SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 16),

                            // Profile actions
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading ? null : _showEditProfileDialog,
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit Profile'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo[800],
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Menu items
                            _buildMenuItem(
                              'Course Impressions',
                              'Mobile Technology and Programming',
                              Icons.star,
                              Colors.amber,
                              _showCourseImpressions,
                            ),
                            
                            _buildMenuItem(
                              'Suggestions',
                              'Ideas and feedback for improvement',
                              Icons.lightbulb,
                              Colors.orange,
                              _showSuggestions,
                            ),

                            _buildMenuItem(
                              'About App',
                              'BookVerse v1.0.0 - Digital Library',
                              Icons.info,
                              Colors.blue,
                              () {
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'BookVerse',
                                  applicationVersion: '1.0.0',
                                  applicationIcon: Icon(
                                    Icons.menu_book_rounded,
                                    color: Colors.indigo[800],
                                    size: 32,
                                  ),
                                  children: [
                                    const Text(
                                      'A comprehensive digital library app built with Flutter for Mobile Technology and Programming course final project.',
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Logout section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Card(
                                child: ListTile(
                                  leading: const Icon(Icons.logout, color: Colors.red),
                                  title: const Text(
                                    'Logout',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  subtitle: const Text('Sign out of your account'),
                                  onTap: _isLoading ? null : _logout,
                                  enabled: !_isLoading,
                                ),
                              ),
                            ),

                            // Add extra bottom padding to account for bottom navigation and debug banner
                            SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                          ]),
                        ),
                      ],
                    ),
                    
                    // Loading overlay
                    if (_isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildMenuItem(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildImpressionCard(
    String title,
    String rating,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    String title,
    String suggestions,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestions,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}