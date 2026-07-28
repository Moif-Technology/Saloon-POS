#ifndef RUNNER_NATIVE_SETTLEMENT_PRINTER_H_
#define RUNNER_NATIVE_SETTLEMENT_PRINTER_H_

#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>

// Registers the native settlement print method channel.
// When Flutter calls printSettlementReceipt with a map of receipt data,
// prints via Windows GDI (same as VB).
void RegisterNativeSettlementPrinter(flutter::BinaryMessenger* messenger);

#endif  // RUNNER_NATIVE_SETTLEMENT_PRINTER_H_
