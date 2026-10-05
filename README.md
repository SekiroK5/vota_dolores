# Vota Dolores Hidalgo

Plebiscito vecinal con gráficas animadas, construido 100% con TDD
(Desarrollo Móvil Integral — proyecto complementario de práctica TDD).

## Estructura

```
lib/
  modelos/
    opcion_votacion.dart
    votacion.dart
    resultado_opcion.dart
  logica/
    resultado_voto.dart
    servicio_votacion.dart
  presentation/
    votacion_screen.dart   (interfaz gráfica animada)
  main.dart
test/
  servicio_votacion_test.dart
```

`lib/modelos/` y `lib/logica/` son Dart puro; la animación vive solo en `lib/presentation/`.

## Cómo ejecutar

Este repositorio contiene el código fuente del manual. Las carpetas de plataforma
(`android/`, `ios/`, `web/`, `windows/`, …) las genera Flutter en tu máquina:

```bash
cd vota_dolores_hidalgo
flutter create --project-name vota_dolores_hidalgo .
# flutter create agrega test/widget_test.dart (prueba de contador de la plantilla, usa MyApp).
# El manual no la incluye y no compila con este main.dart, así que se elimina:
rm test/widget_test.dart          # Windows: del test\widget_test.dart
flutter pub get
flutter test
flutter run
```

O simplemente ejecuta `setup.sh` (Linux/macOS) o `setup.bat` (Windows).

## Pruebas (test/servicio_votacion_test.dart)

| Ronda | Prueba |
|---|---|
| 1 | registrar un voto valido incrementa el contador de esa opcion |
| 2 | votar por una opcion que no existe regresa opcionInvalida |
| 3 | un mismo usuario no puede votar dos veces |
| 4 | calcula el porcentaje de cada opcion correctamente |
| 4 | si no hay ningun voto, todos los porcentajes son 0 |
| 5 | determinarGanador regresa la opcion con mas votos |
| 6 | si hay empate, determinarGanador regresa mas de una opcion |
| 7 | no se puede votar si la votacion ya cerro |
| 7 | si la votacion sigue abierta, el voto se registra normalmente |
| 8 | (refactor — sin pruebas nuevas) |
| Integración | simulacion completa: varios vecinos votan y se determina un ganador |

> Nota: el manual dice "deberían pasar 9 pruebas", pero las rondas 4 y 7 agregan dos
> pruebas cada una, por lo que el total real es **10 pruebas** (9 de las rondas + 1 de integración).

## Historial TDD

Cada paso del manual es un commit (`git log --oneline`): ROJO → VERDE → REFACTOR por ronda.

## Checklist

- [x] Cada regla de negocio (voto único, opción válida, fecha de cierre, empates) tiene su propia prueba
- [x] `ResultadoVoto` se usa para casos esperados; no se abusa de excepciones
- [x] `obtenerResultados()` no divide entre cero cuando no hay votos
- [x] `VotacionScreen` no duplica ninguna regla cubierta por `ServicioVotacion`
- [x] Existe una prueba de integración con un intento de voto duplicado
