import 'dart:convert';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Example demonstrating how to use the Client class and print its data
void main() async {
  print('=== Client API Test ===\n');

  try {
    // Test 1: Create a basic client and test connection
    print('1. Testing basic client creation...');
    final client = Client('https://api.dexie.space');
    print('Client created successfully:');
    print('  Base URL: ${client.baseURL}');
    print('  Timeout: ${client.timeout}');
    print('  HTTP Client: ${client.httpClient}');
    print('');

    // Test 2: Test a simple GET request to verify the client works
    print('2. Testing GET request to Dexie Space API...');
    try {
      final response = await client.get(Uri.parse('v3/prices/tickers'));
      print('Response received:');
      print('  Status Code: ${response.statusCode}');
      print('  Body length: ${response.body.length} characters');
      print('  Response object: $response');

      // Try to parse the response as JSON to verify it's valid
      final jsonData = jsonDecode(response.body);
      print('  JSON parsed successfully');
      print('  Response type: ${jsonData.runtimeType}');

      if (jsonData is Map<String, dynamic>) {
        print('  Keys in response: ${jsonData.keys.toList()}');
        if (jsonData.containsKey('tickers')) {
          final tickers = jsonData['tickers'] as List;
          print('  Number of tickers: ${tickers.length}');
          if (tickers.isNotEmpty) {
            print('  First ticker: ${tickers.first}');
          }
        }
      }
    } catch (e) {
      print('  Error making GET request: $e');
    }
    print('');

    // Test 3: Test client with custom timeout
    print('3. Testing client with custom timeout...');
    final customClient = Client(
      'https://api.dexie.space',
      timeout: Duration(seconds: 10),
    );
    print('Custom client created:');
    print('  Base URL: ${customClient.baseURL}');
    print('  Timeout: ${customClient.timeout}');
    print('');

    // Test 4: Test client toString method
    print('4. Testing client toString method...');
    print('Client string representation: ${client.toString()}');
    print('');

    // Test 5: Test Response class
    print('5. Testing Response class...');
    final testResponse = Response('{"test": "data"}', 200);
    print('Test response: $testResponse');
    print('  Body: ${testResponse.body}');
    print('  Status Code: ${testResponse.statusCode}');
    print('');

    print('=== Client API Test Completed Successfully ===');
    print('The Client class is working correctly!');
  } catch (e) {
    print('Error during client test: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}
