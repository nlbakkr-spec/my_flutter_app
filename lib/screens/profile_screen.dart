import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;
  bool _hasChanges = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName ?? '');
    _descriptionController = TextEditingController(text: widget.user.description ?? '');

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _nameController.addListener(_checkChanges);
    _descriptionController.addListener(_checkChanges);
  }

  void _checkChanges() {
    final nameChanged = _nameController.text.trim() != (widget.user.fullName ?? '');
    final descChanged = _descriptionController.text.trim() != (widget.user.description ?? '');
    final newValue = nameChanged || descChanged;
    if (newValue != _hasChanges) {
      setState(() => _hasChanges = newValue);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_hasChanges) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.updateProfile(
      fullName: _nameController.text,
      description: _descriptionController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Профиль обновлён'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Не удалось сохранить профиль'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы будете перенаправлены на экран входа.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _navigateToDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Удалить аккаунт?'),
          ],
        ),
        content: const Text(
          'Это действие нельзя отменить. Все ваши данные будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authService = Provider.of<AuthService>(context, listen: false);
              final success = await authService.deleteAccount();
              if (success && mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        elevation: 0,
        title: Text(
          'Профиль',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Аватар
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.user.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Email
              Text(
                widget.user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),

              const SizedBox(height: 32),

              // Форма
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Имя',
                      hint: 'Введите ваше имя',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),

                    CustomTextField(
                      label: 'О себе',
                      hint: 'Расскажите немного о себе',
                      controller: _descriptionController,
                      prefixIcon: const Icon(Icons.description_outlined),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    CustomButton(
                      text: 'Сохранить',
                      onPressed: _hasChanges ? () => _saveProfile() : null,
                      isLoading: _isLoading,
                      backgroundColor: Colors.blue.shade600,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Действия
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.lock_outline,
                      title: 'Сменить пароль',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: Colors.grey.shade300),
                    _ActionTile(
                      icon: Icons.delete_outline,
                      title: 'Удалить аккаунт',
                      titleColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: _navigateToDeleteAccount,
                    ),
                    Divider(height: 1, indent: 56, color: Colors.grey.shade300),
                    _ActionTile(
                      icon: Icons.logout,
                      title: 'Выйти из аккаунта',
                      onTap: _navigateToLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade600),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }
}
