import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'BS Project',
        debugShowCheckedModeBanner: false,

        // ─── СВЕТЛАЯ ТЕМА ─────────────────────────────────────
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: Colors.blue,
          scaffoldBackgroundColor: Colors.grey.shade50,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
        ),

        // ─── ТЁМНАЯ ТЕМА ──────────────────────────────────────
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.grey.shade900,
            foregroundColor: Colors.white,
          ),
        ),

        themeMode: ThemeMode.system,

        home: const AuthWrapper(),

        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/change-password':
              return MaterialPageRoute(
                builder: (_) => const ChangePasswordScreen(),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}

/// Следит за состоянием аутентификации и показывает нужный экран
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  void _initializeAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Показываем splash пока идёт инициализация
        if (!authService.isInitialized || authService.isLoading) {
          return const SplashScreen();
        }

        // Переключаемся между экранами
        if (authService.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
