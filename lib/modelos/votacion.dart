import 'opcion_votacion.dart';

class Votacion {
  final String pregunta;
  final List<OpcionVotacion> opciones;
  final DateTime fechaCierre;
  final Set<String> votantes = {};
  final Map<String, String> opcionesPorUsuario = {};

  Votacion({required this.pregunta, required this.opciones, required this.fechaCierre});
}
