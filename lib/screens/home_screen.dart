import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/google_drive_service.dart';
import '../widgets/custom_button.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late GoogleDriveService _driveService;
  List<List<dynamic>>? _userData;
  bool _isLoadingData = false;
  bool _isAdding = false;
  String? _dataError;
  final _dataController = TextEditingController();

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _driveService = GoogleDriveService();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _dataController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingData = true;
      _dataError = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        final data = await _driveService.getUserData(authService.currentUser!.id);
        if (mounted) {
          setState(() => _userData = data);
          _animController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _dataError = 'Не удалось загрузить данные');
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _addData() async {
    if (_dataController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Введите данные'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        final success = await _driveService.addDataToSheet(
          authService.currentUser!.id,
          [_dataController.text.trim()],
        );

        if (mounted) {
          if (success) {
            _dataController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Данные добавлены'),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            _loadUserData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Не удалось добавить данные'),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
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
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      // Навигация обрабатывается AuthWrapper
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Шапка
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Привет, ${authService.currentUser?.displayName ?? "!"}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authService.currentUser?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    // Профиль кнопка
                    GestureDetector(
                      onTap: () {
                        if (authService.currentUser != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(user: authService.currentUser!),
                            ),
                          ).then((_) => _loadUserData());
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.purple.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (authService.currentUser?.displayName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Описание
                if (authService.currentUser?.description != null &&
                    authService.currentUser!.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200.withValues(alpha:0.3)),
                    ),
                    child: Text(
                      authService.currentUser!.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade300 : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Добавление данных
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey).withValues(alpha:0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Добавить данные',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _dataController,
                        decoration: InputDecoration(
                          hintText: 'Введите данные...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Добавить',
                        onPressed: _addData,
                        isLoading: _isAdding,
                        backgroundColor: Colors.blue.shade600,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Список данных
                Text(
                  'Мои данные',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                _isLoadingData
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _dataError != null
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade400),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _dataError!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _userData == null || _userData!.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade900 : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Нет данных',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Добавьте что-нибудь выше',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _userData!.length,
                                itemBuilder: (context, index) {
                                  final row = _userData![index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey.shade900 : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (row.length > 1)
                                                Text(
                                                  row[1].toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              const SizedBox(height: 2),
                                              Text(
                                                row.length > 2 ? row[2].toString() : 'Нет данных',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
