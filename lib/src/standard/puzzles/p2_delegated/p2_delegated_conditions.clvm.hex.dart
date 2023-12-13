// ignore_for_file: lines_longer_than_80_chars

import '../../../bls.dart';
import '../../../clvm.dart';

final p2DelegatedConditionsPuzzleProgram = Program.deserializeHex(
  'ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080',
);

Program puzzleForPk(JacobianPoint publicKey) {
  return p2DelegatedConditionsPuzzleProgram.curry(
    [
      Program.fromBytes(
        publicKey.toBytes(),
      ),
    ],
  );
}
