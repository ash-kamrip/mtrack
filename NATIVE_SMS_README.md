# Native Android SMS Service for Flutter

This implementation provides a native Android SMS service that can be used in your Flutter app to efficiently fetch and parse SMS messages. It's designed to be more performant than the `flutter_sms_inbox` plugin.

## Features

- **Native Android Implementation**: Direct access to Android's SMS content provider
- **Efficient Pagination**: Fetch SMS messages in batches to avoid memory issues
- **Transaction Filtering**: Filter SMS messages by keywords (e.g., "Sent Rs", "Credit Alert")
- **Permission Handling**: Built-in SMS permission checking
- **JSON Response**: Returns structured JSON data for easy parsing
- **Error Handling**: Comprehensive error handling and logging

## Files Created

1. **`android/app/src/main/kotlin/com/example/mtrack/SmsHelper.kt`** - Native Android SMS helper class
2. **`android/app/src/main/kotlin/com/example/mtrack/MainActivity.kt`** - Platform channel setup
3. **`lib/services/native_sms_service.dart`** - Flutter service wrapper
4. **`lib/services/native_sms_example.dart`** - Usage examples

## Setup

### 1. Android Permissions

The SMS permissions are already added to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
```

### 2. Request Permissions in Flutter

You'll need to request SMS permissions at runtime. Add this to your Flutter app:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestSmsPermission() async {
  final status = await Permission.sms.request();
  return status.isGranted;
}
```

## Usage

### Basic Usage

```dart
import 'package:your_app/services/native_sms_service.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final NativeSmsService _smsService = NativeSmsService();

  Future<void> _fetchSmsMessages() async {

    // Fetch transaction SMS messages
    final smsMessages = await _smsService.fetchTransactionSms(
      keywords: ['Sent Rs', 'Credit Alert'],
      limit: 10,
    );

    // Parse into transactions
    final transactions = _smsService.parseTransactionsFromMessages(smsMessages);
    
    print('Found ${transactions.length} transactions');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _fetchSmsMessages,
      child: Text('Fetch SMS'),
    );
  }
}
```

### Advanced Usage with Pagination

```dart
Future<List<Transaction>> getAllSmsWithPagination() async {
  final allTransactions = <Transaction>[];
  var offset = 0;
  const batchSize = 100;
  
  // Get total count
  final totalCount = await _smsService.getSmsCount();
  
  while (offset < totalCount) {
    final smsMessages = await _smsService.fetchSmsMessages(
      limit: batchSize,
      offset: offset,
    );
    
    if (smsMessages.isEmpty) break;
    
    final transactions = _smsService.parseTransactionsFromMessages(smsMessages);
    allTransactions.addAll(transactions);
    
    offset += batchSize;
  }
  
  return allTransactions;
}
```

### Incremental Sync

```dart
Future<List<Transaction>> getNewSmsSinceLastSync() async {
  final lastTimestamp = await SettingsService.getLastProcessedSmsTimestamp();
  
  if (lastTimestamp == null) {
    // First sync - get top 10
    return await _smsService.fetchTransactionSms(limit: 10);
  }
  
  // Get new messages since last sync
  final smsMessages = await _smsService.fetchSmsMessagesSince(
    lastTimestamp,
    limit: 100,
  );
  
  return _smsService.parseTransactionsFromMessages(smsMessages);
}
```

## API Reference

### NativeSmsService Methods

#### `fetchSmsMessages({int limit = 100, int offset = 0})`
Fetch SMS messages with pagination support.

**Parameters:**
- `limit`: Maximum number of messages to fetch (default: 100)
- `offset`: Starting position for pagination (default: 0)

**Returns:** `Future<List<SmsMessage>>`

#### `fetchSmsMessagesSince(DateTime since, {int limit = 100})`
Fetch SMS messages since a specific timestamp.

**Parameters:**
- `since`: DateTime to fetch messages from
- `limit`: Maximum number of messages to fetch (default: 100)

**Returns:** `Future<List<SmsMessage>>`

#### `fetchTransactionSms({List<String> keywords = const ['Sent Rs', 'Credit Alert'], int limit = 10})`
Fetch SMS messages containing specific keywords.

**Parameters:**
- `keywords`: List of keywords to search for
- `limit`: Maximum number of messages to fetch (default: 10)

**Returns:** `Future<List<SmsMessage>>`

#### `getSmsCount()`
Get total count of SMS messages.

**Returns:** `Future<int>`

#### `parseTransactionsFromMessages(List<SmsMessage> messages)`
Parse SMS messages into Transaction objects.

**Parameters:**
- `messages`: List of SMS messages to parse

**Returns:** `List<Transaction>`

### SmsMessage Model

```dart
class SmsMessage {
  final int id;
  final String address;
  final String body;
  final int date;
  final int type;
  final int read;
}
```

## Performance Benefits

1. **Direct Database Access**: Uses Android's ContentResolver directly
2. **Efficient Queries**: Leverages SQL queries with proper indexing
3. **Pagination**: Prevents loading all SMS messages into memory
4. **Filtering**: Server-side filtering reduces data transfer
5. **Native Performance**: No plugin overhead

## Error Handling

The service includes comprehensive error handling:

- Permission checks before operations
- Try-catch blocks around all native calls
- JSON parsing error handling
- Detailed logging for debugging

## Logging

The service uses the `logger` package for detailed logging. You can see logs like:

```
I/NativeSmsService: Fetching SMS messages: limit=10, offset=0
I/NativeSmsService: Successfully fetched 10 SMS messages
I/NativeSmsService: Parsed 3 transactions from 10 messages
```

## Integration with Your App

To integrate this with your existing MTrack app:

1. Replace the `flutter_sms_inbox` plugin usage with `NativeSmsService`
2. Update your `SmsTransactionService` to use the native service
3. Update your main.dart to use the new service for first launch and sync

The native service provides better performance and more control over SMS reading operations. 