import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/votacion.dart';
import '../modelos/opcion_votacion.dart';
import '../modelos/resultado_opcion.dart';
import 'resultado_voto.dart';

class ServicioVotacion {
  static const _storageKey = 'vota_dolores_hidalgo_votacion';

  final Votacion votacion;
  final DateTime Function() reloj;
  final int maxVotos;
  final bool modoAnonimo;

  ServicioVotacion(
    this.votacion, {
    DateTime Function()? reloj,
    this.maxVotos = 500,
    this.modoAnonimo = false,
  }) : reloj = reloj ?? DateTime.now;

  ResultadoVoto registrarVoto({required String idUsuario, required String idOpcion}) {
    final yaCerro = reloj().isAfter(votacion.fechaCierre);
    if (yaCerro) return ResultadoVoto.votacionCerrada;

    final yaVoto = votacion.votantes.contains(idUsuario);
    if (yaVoto) return ResultadoVoto.usuarioYaVoto;

    if (votacion.votantes.length >= maxVotos) {
      return ResultadoVoto.maximoVotosAlcanzado;
    }

    final opcion = _buscarOpcion(idOpcion);
    if (opcion == null) return ResultadoVoto.opcionInvalida;

    opcion.votos++;
    votacion.votantes.add(idUsuario);

    if (!modoAnonimo) {
      votacion.opcionesPorUsuario[idUsuario] = idOpcion;
    }

    return ResultadoVoto.exitoso;
  }

  Future<void> guardarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'pregunta': votacion.pregunta,
      'fechaCierre': votacion.fechaCierre.toIso8601String(),
      'opciones': votacion.opciones
          .map((o) => {'id': o.id, 'texto': o.texto, 'votos': o.votos})
          .toList(),
      'votantes': votacion.votantes.toList(),
      'opcionesPorUsuario': votacion.opcionesPorUsuario,
      'maxVotos': maxVotos,
      'modoAnonimo': modoAnonimo,
    };

    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<void> cargarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return;

    final decoded = jsonDecode(data) as Map<String, dynamic>;
    final opciones = decoded['opciones'] as List<dynamic>? ?? const [];

    for (final opcion in votacion.opciones) {
      opcion.votos = 0;
    }

    for (final item in opciones) {
      final mapa = item as Map<String, dynamic>;
      final opcion = _buscarOpcion(mapa['id'] as String);
      if (opcion != null) {
        opcion.votos = (mapa['votos'] as int?) ?? 0;
      }
    }

    final votantes = decoded['votantes'] as List<dynamic>? ?? const [];
    votacion.votantes
      ..clear()
      ..addAll(votantes.map((v) => v.toString()));

    final opcionesPorUsuario = decoded['opcionesPorUsuario'] as Map<String, dynamic>? ?? const {};
    votacion.opcionesPorUsuario
      ..clear()
      ..addAll(opcionesPorUsuario.map((key, value) => MapEntry(key, value.toString())));
  }

  List<ResultadoOpcion> obtenerResultados() {
    final total = votacion.opciones.fold<int>(0, (suma, o) => suma + o.votos);
    return votacion.opciones.map((o) {
      final porcentaje = total == 0 ? 0.0 : (o.votos / total) * 100;
      return ResultadoOpcion(o, porcentaje);
    }).toList();
  }

  List<OpcionVotacion> determinarGanador() {
    final maxVotos = votacion.opciones.map((o) => o.votos).reduce((a, b) => a > b ? a : b);
    return votacion.opciones.where((o) => o.votos == maxVotos).toList();
  }

  OpcionVotacion? _buscarOpcion(String id) {
    for (final o in votacion.opciones) {
      if (o.id == id) return o;
    }
    return null;
  }
}
