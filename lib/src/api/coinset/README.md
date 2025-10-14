# Coinset.org API Client

Cliente HTTP para interactuar con la API de [coinset.org](https://coinset.org), un servicio público que proporciona acceso a datos de la blockchain de Chia de manera optimizada para clientes ligeros.

## Características

- ✅ Compatible con mainnet y testnet11
- ✅ API completa del Full Node RPC
- ✅ Consultas de coins por puzzle hash, hint, parent ID, etc.
- ✅ Consultas de mempool
- ✅ Push de transacciones
- ✅ Obtención de puzzle y solution
- ✅ Estado de la blockchain
- ✅ Información de la red

## Uso

### Crear un cliente

```dart
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

// Para mainnet
final client = CoinsetClient.mainnet();

// Para testnet11
final testnetClient = CoinsetClient.testnet11();

// Con URL personalizada
final customClient = CoinsetClient(
  baseUrl: 'https://custom.api.coinset.org',
  timeout: Duration(seconds: 30),
);
```

### Obtener el estado de la blockchain

```dart
try {
  final response = await client.getBlockchainState();
  
  if (response.success && response.blockchainState != null) {
    final state = response.blockchainState!;
    print('Peak height: ${state.peak}');
    print('Synced: ${state.sync.synced}');
    print('Mempool size: ${state.mempoolSize}');
  }
} catch (e) {
  print('Error: $e');
}
```

### Buscar coins por puzzle hash

```dart
final puzzleHash = Puzzlehash.fromHex('your_puzzle_hash');

try {
  final response = await client.getCoinRecordsByPuzzleHash(
    puzzleHash,
    includeSpentCoins: false,
  );
  
  if (response.success && response.coinRecords != null) {
    for (final record in response.coinRecords!) {
      print('Coin: ${record.coin}');
      print('Amount: ${record.coin.amount}');
      print('Confirmed at height: ${record.confirmedBlockIndex}');
    }
  }
} catch (e) {
  print('Error: $e');
}
```

### Buscar coins por hint

```dart
final hint = Puzzlehash.fromHex('your_hint');

try {
  final response = await client.getCoinRecordsByHint(
    hint,
    startHeight: 1000000,
    includeSpentCoins: true,
  );
  
  if (response.success && response.coinRecords != null) {
    print('Found ${response.coinRecords!.length} coins');
  }
} catch (e) {
  print('Error: $e');
}
```

### Buscar coins por múltiples puzzle hashes

```dart
final puzzleHashes = [
  Puzzlehash.fromHex('hash1'),
  Puzzlehash.fromHex('hash2'),
  Puzzlehash.fromHex('hash3'),
];

try {
  final response = await client.getCoinRecordsByPuzzleHashes(
    puzzleHashes,
    includeSpentCoins: false,
  );
  
  if (response.success && response.coinRecords != null) {
    print('Found ${response.coinRecords!.length} coins');
  }
} catch (e) {
  print('Error: $e');
}
```

### Obtener puzzle y solution de un coin

```dart
final coinId = Puzzlehash.fromHex('coin_id');

try {
  final response = await client.getPuzzleAndSolution(coinId);
  
  if (response.success && response.coinSolution != null) {
    final coinSpend = response.coinSolution!;
    print('Puzzle reveal: ${coinSpend.puzzleReveal}');
    print('Solution: ${coinSpend.solution}');
  }
} catch (e) {
  print('Error: $e');
}
```

### Enviar una transacción

```dart
final spendBundle = SpendBundle(...);

try {
  final response = await client.pushTx(spendBundle);
  
  if (response.success) {
    print('Transaction pushed: ${response.status}');
  } else {
    print('Error: ${response.error}');
  }
} catch (e) {
  print('Error: $e');
}
```

### Obtener información de la red

```dart
try {
  final response = await client.getNetworkInfo();
  
  if (response.success) {
    print('Network: ${response.networkName}');
    print('Prefix: ${response.networkPrefix}');
    print('Genesis challenge: ${response.genesisChallenge}');
  }
} catch (e) {
  print('Error: $e');
}
```

## Métodos disponibles

### Blockchain State
- `getBlockchainState()` - Obtiene el estado actual de la blockchain

### Coin Queries
- `getCoinRecordByName(name)` - Obtiene un coin por su ID
- `getCoinRecordsByHint(hint, ...)` - Busca coins por hint
- `getCoinRecordsByNames(names, ...)` - Busca múltiples coins por IDs
- `getCoinRecordsByParentIds(parentIds, ...)` - Busca coins por parent IDs
- `getCoinRecordsByPuzzleHash(puzzleHash, ...)` - Busca coins por puzzle hash
- `getCoinRecordsByPuzzleHashes(puzzleHashes, ...)` - Busca coins por múltiples puzzle hashes

### Block Queries
- `getAdditionsAndRemovals(headerHash)` - Obtiene additions y removals de un bloque
- `getBlock(headerHash)` - Obtiene un bloque completo por su hash
- `getBlockRecord(headerHash)` - Obtiene el record de un bloque por hash
- `getBlockRecordByHeight(height)` - Obtiene el record de un bloque por altura
- `getBlockRecords(startHeight, endHeight)` - Obtiene múltiples block records en un rango
- `getBlocks(start, end, ...)` - Obtiene múltiples bloques en un rango
- `getBlockSpends(headerHash)` - Obtiene todos los coin spends de un bloque

### Puzzle & Solution
- `getPuzzleAndSolution(coinId, height)` - Obtiene el puzzle y solution de un coin

### Transactions
- `pushTx(spendBundle)` - Envía una transacción a la red

### Mempool
- `getMempoolItemByTxId(txId)` - Obtiene un item del mempool por transaction ID
- `getMempoolItemsByCoinName(coinName)` - Obtiene items del mempool por coin name

### Network
- `getNetworkInfo()` - Obtiene información de la red

## Manejo de errores

Todos los métodos pueden lanzar `CoinsetException` en caso de error:

```dart
try {
  final response = await client.getCoinRecordByName(coinId);
  // ...
} on CoinsetException catch (e) {
  print('Coinset error: ${e.message}');
  print('Status code: ${e.statusCode}');
} catch (e) {
  print('Other error: $e');
}
```

## Responses

Todas las respuestas tienen la siguiente estructura base:

```dart
class Response {
  final bool success;
  final String? error;
  final YourData? data;
}
```

- `success`: indica si la operación fue exitosa
- `error`: mensaje de error si `success` es `false`
- `data`: los datos solicitados (puede ser `null` si hay error)

## Ventajas sobre Full Node RPC

1. **Sin configuración**: No necesitas ejecutar un full node
2. **Rápido**: Optimizado para consultas de clientes ligeros
3. **Público**: Acceso gratuito sin autenticación
4. **Confiable**: Alta disponibilidad y rendimiento

## Limitaciones

- Rate limiting puede aplicar en uso intensivo
- No todas las funciones de full node están disponibles
- Depende de un servicio de terceros

## Implementación basada en

Este cliente está basado en la implementación de Rust del [chia-wallet-sdk](https://github.com/Rigidity/chia-wallet-sdk) de Rigidity.

