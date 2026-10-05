import 'dart:async';

import 'package:flutter/material.dart';

import '../modelos/opcion_votacion.dart';
import '../modelos/votacion.dart';
import '../modelos/resultado_opcion.dart';
import '../logica/resultado_voto.dart';
import '../logica/servicio_votacion.dart';
import 'confetti_painter.dart';

class VotacionScreen extends StatefulWidget {
  const VotacionScreen({super.key});

  @override
  State<VotacionScreen> createState() => _VotacionScreenState();
}

class _VotacionScreenState extends State<VotacionScreen> with SingleTickerProviderStateMixin {
  late final Votacion _votacion;
  late ServicioVotacion _servicio;
  bool _yaVote = false;
  late final TextEditingController _usuarioController;
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _usuarioController = TextEditingController(
      text: 'vecino-${DateTime.now().millisecondsSinceEpoch}',
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _votacion = Votacion(
      pregunta: 'Que obra prioritaria debe realizar el municipio este ano?',
      opciones: [
        OpcionVotacion(id: 'jardin', texto: 'Rehabilitacion del Jardin Principal'),
        OpcionVotacion(id: 'biblioteca', texto: 'Nueva Biblioteca Digital'),
        OpcionVotacion(id: 'alumbrado', texto: 'Alumbrado en el Barrio de Analco'),
        OpcionVotacion(id: 'parque', texto: 'Parque Infantil en la Colonia Guanajuato'),
      ],
      fechaCierre: DateTime.now().add(const Duration(days: 7)),
    );
    _servicio = ServicioVotacion(_votacion);
    unawaited(_cargarPersistencia());
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _cargarPersistencia() async {
    final servicioPersistido = ServicioVotacion(_votacion);
    await servicioPersistido.cargarEstado();
    if (!mounted) return;
    setState(() {
      _servicio = servicioPersistido;
      _yaVote = _votacion.votantes.contains(_usuarioController.text.trim());
    });
  }

  Future<void> _guardarPersistencia() async {
    await _servicio.guardarEstado();
  }

  void _votar(String idOpcion) {
    final idUsuario = _usuarioController.text.trim();
    if (idUsuario.isEmpty) {
      _mensaje('Escribe un nombre de vecino antes de votar.');
      return;
    }

    final resultado = _servicio.registrarVoto(idUsuario: idUsuario, idOpcion: idOpcion);

    switch (resultado) {
      case ResultadoVoto.exitoso:
        _guardarPersistencia();
        setState(() => _yaVote = true);
        _mensaje('Gracias por votar.');
        break;
      case ResultadoVoto.usuarioYaVoto:
        _mensaje('Este vecino ya registró su voto.');
        break;
      case ResultadoVoto.votacionCerrada:
        _mensaje('Esta votacion ya cerro.');
        break;
      case ResultadoVoto.maximoVotosAlcanzado:
        _mensaje('Se alcanzó el máximo de votantes permitidos.');
        break;
      case ResultadoVoto.opcionInvalida:
        _mensaje('La opción seleccionada no existe.');
        break;
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  void _verGanador() {
    final ganadores = _servicio.determinarGanador();

    if (ganadores.length == 1) {
      _confettiController.forward(from: 0);
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ganador',
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final content = ganadores.length == 1
            ? 'La opcion ganadora es:\n\n${ganadores.first.texto}'
            : 'Hay un empate entre:\n\n${ganadores.map((g) => g.texto).join('\n')}';

        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: FadeTransition(
            opacity: anim1,
            child: Stack(
              children: [
                if (ganadores.length == 1)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, _) => CustomPaint(
                        painter: ConfettiPainter(
                          progress: _confettiController.value,
                        ),
                      ),
                    ),
                  ),
                AlertDialog(
                  title: const Text('Resultado del plebiscito'),
                  content: Text(content, textAlign: TextAlign.center),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _servicio.obtenerResultados();
    return Scaffold(
      appBar: AppBar(title: const Text('Plebiscito Vecinal - Dolores Hidalgo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_votacion.pregunta, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _usuarioController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'ID del vecino',
              hintText: 'ej. vecino-01',
            ),
          ),
          const SizedBox(height: 16),
          ...resultados.map((r) => _BarraOpcion(
                resultado: r,
                puedeVotar: !_yaVote,
                onVotar: () => _votar(r.opcion.id),
              )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _verGanador,
            icon: const Icon(Icons.emoji_events),
            label: const Text('Ver resultado del plebiscito'),
          ),
        ],
      ),
    );
  }
}

class _BarraOpcion extends StatelessWidget {
  final ResultadoOpcion resultado;
  final bool puedeVotar;
  final VoidCallback onVotar;

  const _BarraOpcion({required this.resultado, required this.puedeVotar, required this.onVotar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(resultado.opcion.texto, style: const TextStyle(fontWeight: FontWeight.w600))),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: resultado.porcentaje),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) => Text('${valor.toStringAsFixed(0)}%'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 18,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: resultado.porcentaje / 100),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, valor, _) => Container(
                      height: 18,
                      width: constraints.maxWidth * valor,
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          if (puedeVotar)
            OutlinedButton(onPressed: onVotar, child: const Text('Votar por esta opcion')),
        ],
      ),
    );
  }
}
