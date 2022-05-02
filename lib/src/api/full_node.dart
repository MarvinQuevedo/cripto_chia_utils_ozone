import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/models/responses/blockchain_state_response.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:chia_utils/src/api/models/responses/coin_record_response.dart';
import 'package:chia_utils/src/api/models/responses/coin_records_response.dart';
import 'package:chia_utils/src/api/models/responses/coin_spend_response.dart';

abstract class FullNode {
  const FullNode(this.baseURL);

  final String baseURL;

  Future<CoinRecordsResponse> getCoinRecordsByPuzzleHashes(
    List<Puzzlehash> puzzlehashes, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  });

  Future<ChiaBaseResponse> pushTransaction(SpendBundle spendBundle);

  Future<CoinRecordResponse> getCoinByName(Bytes coinId);

  Future<CoinSpendResponse> getPuzzleAndSolution(Bytes coinId, int height);

  Future<BlockchainStateResponse> getBlockchainState();
}
