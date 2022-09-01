// ignore_for_file: lines_longer_than_80_chars

import '../../../clvm.dart';
import '../../../clvm/program.dart';

final P2_CONDITIONS_MOD = Program.deserializeHex(
  "ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080",
);

Program puzzleForConditions(Program conditions) {
  return P2_CONDITIONS_MOD.run(Program.list([conditions])).program;
}

Program solution_for_conditions(Program conditions) {
  return Program.list([puzzleForConditions(conditions), Program.fromInt(0)]);
}
