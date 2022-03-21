import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class AggSigMeCondition implements Condition {
  static int conditionCode = 50;

  JacobianPoint publicKey;
  Puzzlehash message;

  AggSigMeCondition(this.publicKey, this.message);

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(publicKey.toBytes()),
      Program.fromBytes(message.bytes),
    ]);
  }

  factory AggSigMeCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(AggSigMeCondition);
    }
    return AggSigMeCondition(JacobianPoint.fromBytesG1(programList[1].atom), Puzzlehash(programList[2].atom));
  }

  static bool isThisCondition(Program condition) {
    final conditionParts = condition.toList();
    if (conditionParts.length != 3) {
      return false;
    }
    if (conditionParts[0].toInt() != conditionCode) {
      return false;
    }
    return true;
  }
}
