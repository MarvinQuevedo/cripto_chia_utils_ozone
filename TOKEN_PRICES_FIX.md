# Solución para Persistencia de Precios de Tokens

## Problema Identificado

El estado de los precios de los tokens se perdía al navegar entre pantallas porque el `TokenPricesProvider` se creaba localmente en el widget `home.dart` cada vez que se navegaba a la pantalla.

## Solución Implementada

### 1. Singleton Pattern para TokenPricesProvider

Se implementó un patrón singleton en `TokenPricesProvider` para asegurar que solo exista una instancia global:

```dart
class TokenPricesProvider extends ChangeNotifier {
  static TokenPricesProvider? _instance;
  static bool _isInitialized = false;

  TokenPricesProvider._() {
    if (_instance != null) {
      throw Exception('TokenPricesProvider is a singleton');
    }
    _instance = this;
    // Refresh prices every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshPrices();
    });
  }

  factory TokenPricesProvider() {
    if (_instance == null) {
      _instance = TokenPricesProvider._();
    }
    return _instance!;
  }
}
```

### 2. Registro Global en GetX

Se registró el provider como un singleton global en `home_feature.dart`:

```dart
Get.lazyPut<TokenPricesProvider>(
  () {
    final provider = TokenPricesProvider();
    provider.refreshPrices();
    return provider;
  },
  fenix: true, // Mantener la instancia activa
);
```

### 3. Uso del Provider Global en el Widget

Se modificó el widget `home.dart` para usar el provider global en lugar de crear uno nuevo:

```dart
return ChangeNotifierProvider<TokenPricesProvider>.value(
  value: Get.find<TokenPricesProvider>(),
  child: Consumer2<HomeProvider, TokenPricesProvider>(
    // ... resto del código
  ),
);
```

### 4. Mejoras en el Manejo de Datos

- **Caché Robusto**: Los datos no se limpian si hay errores en la API
- **Actualización Inteligente**: Solo se actualiza si han pasado más de 10 segundos desde la última actualización
- **Indicadores Visuales**: Se agregó un indicador de carga en el header
- **Manejo de Errores**: Mejor manejo de errores sin perder datos en caché

### 5. Métodos Adicionales

Se agregaron métodos útiles:

```dart
// Forzar actualización
Future<void> forceRefreshPrices() async

// Verificar si los datos están obsoletos
bool get isPricesStale

// Obtener precio con fallback a caché
double? getTokenPriceWithFallback(String tailHash)
```

## Beneficios de la Solución

1. **Persistencia de Estado**: Los precios se mantienen al navegar entre pantallas
2. **Mejor Performance**: Menos llamadas a la API innecesarias
3. **Experiencia de Usuario**: Indicadores visuales del estado de carga
4. **Robustez**: Mejor manejo de errores y fallbacks
5. **Escalabilidad**: Fácil de extender para más funcionalidades

## Archivos Modificados

1. `lib/wallet_ui/features/home/presentation/providers/token_prices_provider.dart`
2. `lib/wallet_ui/features/home/home_feature.dart`
3. `lib/wallet_ui/features/home/presentation/widgets/home_items/home.dart`

## Testing

Para verificar que la solución funciona:

1. Navegar a la pantalla de home
2. Esperar a que se carguen los precios
3. Navegar a otra pantalla
4. Regresar a home
5. Verificar que los precios siguen mostrándose sin recargar

Los precios se actualizarán automáticamente cada 30 segundos en segundo plano. 