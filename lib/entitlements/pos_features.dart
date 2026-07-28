import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/utils/privilege_utils.dart';

class PosFeature {
  const PosFeature._();

  static const pos = 'pos';
  static const billing = 'pos.billing';
  static const productSearch = 'pos.product_search';
  static const customerSelection = 'pos.customer_selection';
  static const takeaway = 'pos.takeaway';
  static const kot = 'pos.kot';
  static const kotSave = 'pos.kot.save';
  static const kotPrint = 'pos.kot.print';
  static const kotReprint = 'pos.kot.reprint';
  static const kotDummyBill = 'pos.kot.dummy_bill';
  static const kotComments = 'pos.kot.comments';
  static const kotJoinSplit = 'pos.kot.join_split';
  static const kotItemCancel = 'pos.kot.item_cancel';
  static const kotSaveWithoutArea = 'pos.kot.save_without_area';

  static const settlement = 'pos.settlement';
  static const settlementCash = 'pos.settlement.cash';
  static const settlementCard = 'pos.settlement.card';
  static const settlementCredit = 'pos.settlement.credit';
  static const settlementDirect = 'pos.settlement.direct';
  static const settlementChange = 'pos.settlement.change';
  static const settlementUnsavedCart = 'pos.settlement.unsaved_cart';

  static const reprintBill = 'pos.reprint_bill';
  static const returnBill = 'pos.return_bill';
  static const counterOpenClose = 'pos.counter_open_close';
  static const counterReports = 'pos.counter_reports';

  static const fullUi = 'pos.full_ui';
  static const basicUi = 'pos.ui.basic';
  static const normalUi = 'pos.ui.normal';
  static const groupsPanel = 'pos.ui.groups_panel';
  static const subgroupsPanel = 'pos.ui.subgroups_panel';
  static const areasPanel = 'pos.ui.areas_panel';
  static const tablesPanel = 'pos.ui.tables_panel';
  static const cartKotLabel = 'pos.ui.cart.kot_label';
  static const cartCustomerSelector = 'pos.ui.cart.customer_selector';
  static const cartAddCustomer = 'pos.ui.cart.add_customer';
  static const cartModifier = 'pos.ui.cart.modifier';
  static const cartQtyControls = 'pos.ui.cart.qty_controls';
  static const cartUnitPrice = 'pos.ui.cart.unit_price';
  static const cartSubtotal = 'pos.ui.cart.subtotal';
  static const cartTax = 'pos.ui.cart.tax';
  static const cartLineTotal = 'pos.ui.cart.line_total';
  static const cartDelete = 'pos.ui.cart.delete';
  static const totalsSubtotal = 'pos.ui.totals.subtotal';
  static const totalsTax = 'pos.ui.totals.tax';
  static const totalsGrandTotal = 'pos.ui.totals.grand_total';

  static const dineIn = 'pos.dine_in';
  static const areas = 'pos.areas';
  static const tables = 'pos.tables';
  static const subgroupMaster = 'pos.subgroup_master';
  static const delivery = 'pos.delivery';
  static const voidBill = 'pos.void_bill';
  static const discount = 'pos.discount';
  static const discountAdmin = 'pos.discount.admin';
  static const cashInOut = 'pos.cash_in_out';
  static const priceChange = 'pos.price_change';
  static const quantityChange = 'pos.quantity_change';
  static const noSale = 'pos.no_sale';
  static const orderList = 'pos.order_list';

  static const groupMaster = 'pos.group_master';
  static const productMaster = 'pos.product_master';
  static const printerSetup = 'pos.printer_setup';
  static const userSetup = 'pos.user_setup';
  static const recipe = 'pos.recipe';
  static const combo = 'pos.combo';
  static const barcode = 'pos.barcode';
  static const kitchenMessage = 'pos.kitchen_message';
  static const onlineOrders = 'pos.online_orders';
  static const stockReports = 'pos.stock_reports';
  static const production = 'pos.production';
  static const stockTransfer = 'pos.stock_transfer';
  static const purchase = 'pos.purchase';
  static const credit = 'pos.credit';
  static const advancedReports = 'pos.advanced_reports';
  static const vatReports = 'pos.vat_reports';
  static const reportExport = 'pos.report_export';
  static const vat = 'pos.vat';
  static const settings = 'pos.settings';
  static const privilegeSetup = 'pos.privilege_setup';
  static const languageSetup = 'pos.language_setup';
  static const mess = 'pos.mess';
  static const notes = 'pos.notes';
  static const kds = 'pos.kds';
  static const customerDisplay = 'pos.customer_display';
  static const multiSupplier = 'pos.multi_supplier';
  static const syncTools = 'pos.sync_tools';
  static const cashierChange = 'pos.cashier_change';
  static const dayClose = 'pos.day_close';
  static const gameZone = 'pos.game_zone';
}

class PosUiFeatures {
  const PosUiFeatures(this.ref);

  final WidgetRef ref;

  bool has(String code) => hasPosFeature(ref, code);
  bool any(List<String> codes) => codes.any(has);

  bool get fullUi => true;
  bool get baseUi => false;
  bool get normalUi => true;

  bool get groupsPanel => has(PosFeature.groupsPanel);
  bool get subgroupsPanel =>
      has(PosFeature.subgroupsPanel) && has(PosFeature.subgroupMaster);
  bool get areasPanel => has(PosFeature.areasPanel) && has(PosFeature.areas);
  bool get tablesPanel => has(PosFeature.tablesPanel) && has(PosFeature.tables);

  bool get kot => has(PosFeature.kot);
  bool get kotSave => kot && has(PosFeature.kotSave);
  bool get kotPrint => kot && has(PosFeature.kotPrint);
  bool get kotReprint => kot && has(PosFeature.kotReprint);
  bool get kotDummyBill => kot && has(PosFeature.kotDummyBill);
  bool get kotComments => kot && has(PosFeature.kotComments);
  bool get kotJoinSplit => kot && has(PosFeature.kotJoinSplit);
  bool get itemCancel => kot && has(PosFeature.kotItemCancel);
  bool get kotSaveWithoutArea => kot && has(PosFeature.kotSaveWithoutArea);

  bool get settlement => has(PosFeature.settlement);
  bool get directSettlement => settlement && has(PosFeature.settlementDirect);
  bool get settlementUnsavedCart =>
      settlement && has(PosFeature.settlementUnsavedCart);
  bool get returnBill => has(PosFeature.returnBill);
  bool get reprintBill => has(PosFeature.reprintBill);
  bool get delivery => has(PosFeature.delivery);
  bool get discount => has(PosFeature.discount);
  bool get cashInOut => has(PosFeature.cashInOut);
  bool get voidBill => has(PosFeature.voidBill);
  bool get priceChange => has(PosFeature.priceChange);
  bool get quantityChange => has(PosFeature.quantityChange);
  bool get noSale => has(PosFeature.noSale);
  bool get orderList => has(PosFeature.orderList);

  bool get cartKotLabel => kot && has(PosFeature.cartKotLabel);
  bool get cartCustomerSelector => has(PosFeature.cartCustomerSelector);
  bool get cartAddCustomer => has(PosFeature.cartAddCustomer);
  bool get cartModifier => has(PosFeature.cartModifier);
  bool get cartQtyControls => has(PosFeature.cartQtyControls);
  bool get cartUnitPrice => has(PosFeature.cartUnitPrice);
  bool get cartSubtotal => has(PosFeature.cartSubtotal);
  bool get cartTax => has(PosFeature.cartTax);
  bool get cartLineTotal => has(PosFeature.cartLineTotal);
  bool get cartDelete => has(PosFeature.cartDelete);
  bool get totalsSubtotal => has(PosFeature.totalsSubtotal);
  bool get totalsTax => has(PosFeature.totalsTax);
  bool get totalsGrandTotal => has(PosFeature.totalsGrandTotal);
}
