import 'package:flutter/material.dart';

void main() {
  runApp(const JaliscoApp());
}

class JaliscoApp extends StatelessWidget {
  const JaliscoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jalisco Cómo Vamos',
      theme: ThemeData(
        // Usamos un color azul más formal/institucional
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      home: const MainNavigator(),
    );
  }
}

// StatefulWidget porque la pantalla va a cambiar de estado (de pestaña)
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  // Esta variable controla qué pestaña está activa (empezamos en la 0)
  int _selectedIndex = 0;

  // Aquí definimos las 4 "pantallas" temporales de tus módulos
  static const List<Widget> _screens = <Widget>[
    Center(child: Text('📊 Dashboard de Resultados', style: TextStyle(fontSize: 22))),
    Center(child: Text('📝 Encuesta y Comparativa', style: TextStyle(fontSize: 22))),
    Center(child: Text('🎙️ Asistente de Voz AI', style: TextStyle(fontSize: 22))),
    Center(child: Text('💳 Donaciones (Stripe)', style: TextStyle(fontSize: 22))),
  ];

  // Función que se ejecuta cuando el usuario toca un botón de la barra inferior
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jalisco Cómo Vamos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      // El 'body' cambia dependiendo del botón que hayamos tocado
      body: _screens.elementAt(_selectedIndex),

      // Construimos la barra de navegación inferior
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Datos'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Encuesta'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voz AI'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Donar'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Mantiene todos los íconos visibles
      ),
    );
  }
}