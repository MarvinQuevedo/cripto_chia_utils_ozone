import 'package:chia_utils/chia_crypto_utils.dart';

class ReserveFeeCondition implements Condition {
  static int conditionCode = 52;

  int feeAmount;

  ReserveFeeCondition(this.feeAmount);

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode), 
      Program.fromInt(feeAmount)
    ]);
  }
}
