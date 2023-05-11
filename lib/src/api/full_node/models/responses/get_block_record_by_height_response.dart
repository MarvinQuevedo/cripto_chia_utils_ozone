import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class GetBlockRecordByHeightResponse extends ChiaBaseResponse {
  const GetBlockRecordByHeightResponse({
    required super.success,
    required super.error,
    this.blockRecord,
  });

  factory GetBlockRecordByHeightResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    return GetBlockRecordByHeightResponse(
      blockRecord: BlockRecord.fromJson(json['block_record'] as Map<String, dynamic>),
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
  final BlockRecord? blockRecord;
}
