import 'package:chia_crypto_utils/src/clvm/program.dart';

final notificationProgram = Program.deserializeHex(
  'ff02ffff01ff04ffff04ff04ffff04ff05ffff04ff0bff80808080ffff04ffff04ff06ffff01ff808080ff808080ffff04ffff01ff333cff018080',
);
