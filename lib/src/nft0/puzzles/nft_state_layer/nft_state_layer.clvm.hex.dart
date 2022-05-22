// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';

final nftStateLayerProgram = Program.deserializeHex(
  'ff02ffff01ff04ffff04ff10ffff04ff81bfff808080ffff02ff3effff04ff02ffff04ff05ffff04ffff02ff3affff04ff02ffff04ff17ffff04ff0bffff04ffff02ff2fff5f80ff808080808080ffff04ff81bfffff01ff8080808080808080ffff04ffff01ffffff49ff0233ffff0401ff0102ffffffff02ffff03ff05ffff01ff02ff22ffff04ff02ffff04ff0dffff04ffff0bff3cffff0bff34ff2480ffff0bff3cffff0bff3cffff0bff34ff2c80ff0980ffff0bff3cff0bffff0bff34ff8080808080ff8080808080ffff010b80ff0180ff02ffff03ff17ffff01ff02ffff03ffff09ff47ffff0181e880ffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff81a7ff80808080ff0580ffff01ff02ff81a7ffff04ff0bffff04ff05ffff04ff820167ff8080808080ffff01ff088080ff0180ffff01ff02ff32ffff04ff02ffff04ff05ffff04ff0bffff04ff37ff80808080808080ff0180ffff01ff04ffff04ff0bffff04ff05ff808080ffff01ff80808080ff0180ffff02ffff03ff05ffff01ff04ff09ffff02ff2affff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff02ff26ffff04ff02ffff04ffff02ff32ffff04ff02ffff04ff05ffff04ff0bffff04ff17ff808080808080ffff04ff17ff8080808080ffffff04ff09ffff04ffff02ff2affff04ff02ffff04ff15ffff04ff0bff8080808080ff808080ff0bff3cffff0bff34ff2880ffff0bff3cffff0bff3cffff0bff34ff2c80ff0580ffff0bff3cffff02ff22ffff04ff02ffff04ff07ffff04ffff0bff34ff3480ff8080808080ffff0bff34ff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff02ffff03ff2bffff01ff02ffff03ffff09ff818bff3880ffff01ff02ffff03ffff18ff8202cbff3480ffff01ff02ff3effff04ff02ffff04ff05ffff04ffff04ffff04ff23ffff04ff53ff808080ffff04ff6bff808080ffff04ff17ffff04ff4bff80808080808080ffff01ff04ff4bffff02ff3effff04ff02ffff04ff05ffff04ffff04ffff04ff23ffff04ff53ff808080ffff04ff6bff808080ffff04ff17ffff04ff2fff808080808080808080ff0180ffff01ff02ffff03ffff15ff818bff8080ffff01ff04ff4bffff02ff3effff04ff02ffff04ff05ffff04ffff04ffff04ff23ffff04ff53ff808080ffff04ff6bff808080ffff04ff17ffff04ff2fff8080808080808080ffff01ff02ff3effff04ff02ffff04ff05ffff04ffff04ffff04ff23ffff04ff53ff808080ffff04ff6bff808080ffff04ff17ffff04ff2fff8080808080808080ff018080ff0180ffff01ff02ffff03ff2fffff01ff04ffff04ff38ffff04ffff02ff36ffff04ff02ffff04ff05ffff04ff81afffff04ffff0bff34ff5380ffff04ffff02ff2effff04ff02ffff04ff23ff80808080ffff04ffff0bff34ff0580ff8080808080808080ffff04ff17ff8201ef808080ff8080ffff01ff088080ff018080ff0180ff018080',
);
