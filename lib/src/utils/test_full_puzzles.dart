import '../clvm.dart';
import '../core/index.dart';

void testFullPuzzles(Program fullPuzzle, Program solution) {
  final puzzleInfo = OuterPuzzleDriver.matchPuzzle(fullPuzzle);
  if (puzzleInfo == null) {
    print("puzzleInfo is null");
    final output = fullPuzzle.run(solution);
    final conditionsP = output.program;
    final conditions = conditionsP.toList();
    print("conditions: $conditions");
    return;
  }
  final innerPuzzle = OuterPuzzleDriver.getInnerPuzzle(
    constructor: puzzleInfo,
    puzzleReveal: fullPuzzle,
  );

  final innerSolution = OuterPuzzleDriver.getInnerSolution(
    constructor: puzzleInfo,
    solution: solution,
  );
  final output = innerPuzzle!.run(innerSolution!);
  final conditionsP = output.program;
  final conditions = conditionsP.toList();
  print("conditions: $conditions");
}

void testSpendBundle(SpendBundle spendBundle) {
  for (final cs in spendBundle.coinSpends) {
    testFullPuzzles(cs.puzzleReveal, cs.solution);
  }
}
