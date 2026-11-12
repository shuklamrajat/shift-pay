// Host side of `flutter drive` for the emulator end-to-end runs
// (tool/run_emulator_e2e.sh). The tests themselves write their checks and
// files on the device; the script pulls them off afterwards.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
