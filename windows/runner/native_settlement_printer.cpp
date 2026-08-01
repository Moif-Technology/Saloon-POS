#include "native_settlement_printer.h"

#include <windows.h>
#include <winspool.h>

#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <ctime>
#include <cstdio>
#include <string>
#include <vector>

#pragma comment(lib, "winspool.lib")
#pragma comment(lib, "gdi32.lib")

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

std::string GetString(const EncodableMap& m, const char* key) {
  auto it = m.find(EncodableValue(std::string(key)));
  if (it == m.end()) return "";
  const auto& v = it->second;
  if (std::holds_alternative<std::string>(v)) return std::get<std::string>(v);
  return "";
}

double GetDouble(const EncodableMap& m, const char* key) {
  auto it = m.find(EncodableValue(std::string(key)));
  if (it == m.end()) return 0.0;
  const auto& v = it->second;
  if (std::holds_alternative<double>(v)) return std::get<double>(v);
  if (std::holds_alternative<int32_t>(v)) return static_cast<double>(std::get<int32_t>(v));
  if (std::holds_alternative<int64_t>(v)) return static_cast<double>(std::get<int64_t>(v));
  return 0.0;
}

struct ReceiptData {
  std::string trn_no;

  std::string bill_no;
  std::string job_no;
  std::string paid_amount;
  std::string balance_paid;
  std::string payment_mode;
  std::string outstanding_balance;
  std::string net_amount;
  std::string taxable_amount;
  std::string tax1_amount;
  std::string tax1_rate;
  std::string counter_no;
  std::string order_no_display;
  std::string order_type;
  std::string table_name;
  std::string waiter_name;
  std::string cashier_name;
  std::string comments;
  std::string customer_name;
  std::string customer_code;
  std::string mobile_no;
  std::string address;
  std::string tax_reg_no;
  bool show_customer = false;
  std::string date_str;
  std::string time_str;
  std::string printer_name;
  int currency_decimals = 2;

  struct LineItem {
    std::string desc;
    std::string qty;
    std::string price;
    std::string total;
    std::string tax_line;
  };
  std::vector<LineItem> items;

  struct PaymentSplit {
    std::string pay_mode;
    std::string amount;
  };
  std::vector<PaymentSplit> payment_splits;
};

bool ParseReceiptData(const EncodableValue& args, ReceiptData& out) {
  if (!std::holds_alternative<EncodableMap>(args)) return false;
  const auto& top = std::get<EncodableMap>(args);

  auto getStr = [&top](const char* k) { return GetString(top, k); };
  auto getDbl = [&top](const char* k) { return GetDouble(top, k); };

  out.currency_decimals = static_cast<int>(getDbl("currencyDecimals"));
  if (out.currency_decimals <= 0) out.currency_decimals = 2;

  auto fmtNum = [dec = out.currency_decimals](double v) {
    char buf[64];
    snprintf(buf, sizeof(buf), "%.*f", dec, v);
    return std::string(buf);
  };

  out.trn_no = getStr("trnNo");

  out.bill_no = getStr("billNo");
  out.job_no = getStr("jobNo");
  if (out.job_no.empty()) out.job_no = getStr("orderNoDisplay");

  out.paid_amount = getStr("paidAmountStr");
  if (out.paid_amount.empty()) out.paid_amount = fmtNum(getDbl("paidAmount"));

  out.balance_paid = getStr("balancePaidStr");
  if (out.balance_paid.empty()) out.balance_paid = fmtNum(getDbl("balancePaid"));

  out.payment_mode = getStr("paymentMode");
  out.outstanding_balance = getStr("outstandingBalanceStr");
  if (out.outstanding_balance.empty()) {
    double os = getDbl("outstandingBalance");
    if (os > 0.005) out.outstanding_balance = fmtNum(os);
  }

  out.net_amount = getStr("netAmountStr");
  if (out.net_amount.empty()) out.net_amount = fmtNum(getDbl("netAmount"));

  out.taxable_amount = getStr("taxableAmountStr");
  if (out.taxable_amount.empty()) out.taxable_amount = fmtNum(getDbl("taxableAmount"));

  out.tax1_amount = getStr("tax1AmountStr");
  if (out.tax1_amount.empty()) out.tax1_amount = fmtNum(getDbl("tax1Amount"));

  out.tax1_rate = getStr("tax1RateStr");
  if (out.tax1_rate.empty()) {
    double rate = getDbl("tax1Rate");
    char buf[32];
    snprintf(buf, sizeof(buf), "VAT@%.0f%%", rate > 0 ? rate : 5.0);
    out.tax1_rate = buf;
  }

  out.counter_no = getStr("counterNo");
  out.order_no_display = getStr("orderNoDisplay");
  out.order_type = getStr("orderType");
  out.table_name = getStr("tableName");
  out.waiter_name = getStr("waiterName");
  out.cashier_name = getStr("cashierName");
  out.comments = getStr("comments");
  out.customer_name = getStr("customerName");
  out.customer_code = getStr("customerCode");
  out.mobile_no = getStr("mobileNo");
  out.address = getStr("address");
  out.tax_reg_no = getStr("taxRegNo");
  {
    auto it = top.find(EncodableValue(std::string("showCustomer")));
    if (it != top.end() && std::holds_alternative<bool>(it->second)) {
      out.show_customer = std::get<bool>(it->second);
    } else {
      out.show_customer = !out.customer_name.empty();
    }
  }
  out.date_str = getStr("dateStr");
  out.time_str = getStr("timeStr");
  out.printer_name = getStr("printerName");

  auto it_items = top.find(EncodableValue(std::string("items")));
  if (it_items != top.end() && std::holds_alternative<EncodableList>(it_items->second)) {
    for (const auto& ev : std::get<EncodableList>(it_items->second)) {
      if (!std::holds_alternative<EncodableMap>(ev)) continue;
      const auto& item = std::get<EncodableMap>(ev);
      ReceiptData::LineItem li;

      li.desc = GetString(item, "shortDescription");
      if (li.desc.empty()) li.desc = GetString(item, "ShortDescription");
      if (li.desc.size() > 16) li.desc = li.desc.substr(0, 16);

      li.qty = GetString(item, "qtyStr");
      li.price = GetString(item, "unitPriceStr");
      li.total = GetString(item, "lineTotalStr");

      // Always format from numbers for correct decimals (avoids "1 00" style issues)
      double q = GetDouble(item, "qty");
      double p = GetDouble(item, "unitPrice");
      double t = GetDouble(item, "lineTotal");
      if (t == 0) t = q * p + GetDouble(item, "tax1AmountC");

      char buf[64];
      snprintf(buf, sizeof(buf), "%.0f", q);
      li.qty = buf;
      snprintf(buf, sizeof(buf), "%.2f", p);
      li.price = buf;
      snprintf(buf, sizeof(buf), "%.2f", t);
      li.total = buf;

      li.tax_line = GetString(item, "taxLineStr");
      out.items.push_back(std::move(li));
    }
  }

  auto it_splits = top.find(EncodableValue(std::string("paymentSplits")));
  if (it_splits != top.end() && std::holds_alternative<EncodableList>(it_splits->second)) {
    for (const auto& ev : std::get<EncodableList>(it_splits->second)) {
      if (!std::holds_alternative<EncodableMap>(ev)) continue;
      const auto& split = std::get<EncodableMap>(ev);
      ReceiptData::PaymentSplit ps;
      ps.pay_mode = GetString(split, "payMode");
      if (ps.pay_mode.empty()) ps.pay_mode = GetString(split, "PayMode");
      ps.amount = GetString(split, "amountStr");
      if (ps.amount.empty()) {
        double amt = GetDouble(split, "amount");
        if (amt <= 0) amt = GetDouble(split, "billAmount");
        if (amt > 0) ps.amount = fmtNum(amt);
      }
      if (!ps.pay_mode.empty() && !ps.amount.empty()) {
        out.payment_splits.push_back(std::move(ps));
      }
    }
  }

  return true;
}

// KOT (Kitchen Order Ticket) print data - matches VB Print_KOT layout
struct KotData {
  std::string title;           // "JOB TICKET" | "Duplicate Job" | "CANCEL JOB"
  std::string kitchen_location;// e.g. "PASSING" or kitchen name
  std::string supply_type;     // DINE IN | PARCEL | DELIVERY
  std::string kot_prefix;
  std::string kot_number;
  std::string area_name;
  std::string table_name;
  std::string counter_no;
  std::string date_str;
  std::string time_str;
  std::string waiter_name;
  int chair_no = 1;
  std::string printer_name;
  int item_count = 0;
  double total_qty = 0;

  struct KotItem {
    std::string short_description;
    double qty;
    std::string modifier;  // "mod1-mod2" -> "+++ mod1 +++" etc
  };
  std::vector<KotItem> items;
};

bool ParseKotData(const EncodableValue& args, KotData& out) {
  if (!std::holds_alternative<EncodableMap>(args)) return false;
  const auto& top = std::get<EncodableMap>(args);

  auto getStr = [&top](const char* k) { return GetString(top, k); };
  auto getDbl = [&top](const char* k) { return GetDouble(top, k); };

  out.title = getStr("title");
  if (out.title.empty()) out.title = "JOB TICKET";
  out.kitchen_location = getStr("kitchenLocation");
  if (out.kitchen_location.empty()) out.kitchen_location = "PASSING";
  out.supply_type = getStr("supplyType");
  if (out.supply_type.empty()) out.supply_type = "DINE IN";
  out.kot_prefix = getStr("kotPrefix");
  out.kot_number = getStr("kotNumber");
  out.area_name = getStr("areaName");
  out.table_name = getStr("tableName");
  out.counter_no = getStr("counterNo");
  out.date_str = getStr("dateStr");
  out.time_str = getStr("timeStr");
  out.waiter_name = getStr("waiterName");
  out.chair_no = static_cast<int>(getDbl("chairNo"));
  if (out.chair_no <= 0) out.chair_no = 1;
  out.printer_name = getStr("printerName");

  auto it_items = top.find(EncodableValue(std::string("items")));
  if (it_items != top.end() && std::holds_alternative<EncodableList>(it_items->second)) {
    for (const auto& ev : std::get<EncodableList>(it_items->second)) {
      if (!std::holds_alternative<EncodableMap>(ev)) continue;
      const auto& item = std::get<EncodableMap>(ev);
      KotData::KotItem ki;
      ki.short_description = GetString(item, "shortDescription");
      if (ki.short_description.empty())
        ki.short_description = GetString(item, "ShortDescription");
      ki.qty = GetDouble(item, "qty");
      if (ki.qty == 0) ki.qty = GetDouble(item, "Qty");
      ki.modifier = GetString(item, "modifier");
      if (ki.modifier.empty()) ki.modifier = GetString(item, "Modifier");
      out.items.push_back(std::move(ki));
      out.total_qty += (ki.qty < 0 ? -ki.qty : ki.qty);
    }
  }
  out.item_count = static_cast<int>(out.items.size());
  return true;
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return L"";
  int n = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  if (n <= 0) return L"";
  std::wstring w(n, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, &w[0], n);
  if (!w.empty() && w.back() == 0) w.pop_back();
  return w;
}

static const wchar_t kMicrosoftPrintToPdf[] = L"Microsoft Print to PDF";

// Create DC for Microsoft Print to PDF with 80mm paper (thermal receipt size).
// Returns valid HDC or NULL. Caller must DeleteDC.
static HDC CreatePdfDcWith80mmPaper() {
  HANDLE hPrinter = nullptr;
  if (!OpenPrinterW(const_cast<LPWSTR>(kMicrosoftPrintToPdf), &hPrinter, nullptr))
    return nullptr;

  LONG devModeSize = DocumentPropertiesW(nullptr, hPrinter,
      const_cast<LPWSTR>(kMicrosoftPrintToPdf), nullptr, nullptr, 0);
  if (devModeSize <= 0) {
    ClosePrinter(hPrinter);
    return nullptr;
  }

  std::vector<BYTE> buf(devModeSize);
  PDEVMODEW pDevMode = reinterpret_cast<PDEVMODEW>(buf.data());

  if (DocumentPropertiesW(nullptr, hPrinter, const_cast<LPWSTR>(kMicrosoftPrintToPdf),
      pDevMode, nullptr, DM_OUT_BUFFER) != IDOK) {
    ClosePrinter(hPrinter);
    return nullptr;
  }

  // 80mm width = 800 in 0.1mm units; 500mm length for receipt (thermal receipt size)
  pDevMode->dmPaperSize = 0;  // DMPAPER_USER = custom
  pDevMode->dmPaperWidth = 800;   // 80mm
  pDevMode->dmPaperLength = 5000; // 500mm
  pDevMode->dmFields |= DM_PAPERLENGTH | DM_PAPERWIDTH;

  HDC hdc = CreateDCW(L"WINSPOOL", kMicrosoftPrintToPdf, nullptr, pDevMode);
  ClosePrinter(hPrinter);
  return hdc;
}

// padding for next line
static const int kLinePadPx = 8;

static std::wstring PadRight(std::wstring s, size_t width) {
  if (s.size() > width) return s.substr(0, width);
  while (s.size() < width) s.push_back(L' ');
  return s;
}

// Advance y using REAL rendered height (fixes overlap on thermal drivers)
static void DrawLineAuto(HDC hdc, int x, int& y, HFONT font, const std::wstring& text) {
  SelectObject(hdc, font);

  SIZE sz{};
  GetTextExtentPoint32W(hdc, text.c_str(), static_cast<int>(text.size()), &sz);

  TextOutW(hdc, x, y, text.c_str(), static_cast<int>(text.size()));
  y += sz.cy + kLinePadPx;
}

static void DrawCenteredAuto(HDC hdc, int pageWidth, int& y, HFONT font, const std::wstring& text) {
  SelectObject(hdc, font);

  SIZE sz{};
  GetTextExtentPoint32W(hdc, text.c_str(), static_cast<int>(text.size()), &sz);

  int x = (pageWidth / 2) - (sz.cx / 2);
  TextOutW(hdc, x, y, text.c_str(), static_cast<int>(text.size()));
  y += sz.cy + kLinePadPx;
}

static void DrawLeftRightAuto(HDC hdc, int pageWidth, int left, int& y, HFONT font,
                              const std::wstring& leftText, const std::wstring& rightText) {
  SelectObject(hdc, font);

  SIZE szL{};
  GetTextExtentPoint32W(hdc, leftText.c_str(), static_cast<int>(leftText.size()), &szL);

  SIZE szR{};
  GetTextExtentPoint32W(hdc, rightText.c_str(), static_cast<int>(rightText.size()), &szR);

  TextOutW(hdc, left, y, leftText.c_str(), static_cast<int>(leftText.size()));
  int xRight = pageWidth - left - szR.cx;
  TextOutW(hdc, xRight, y, rightText.c_str(), static_cast<int>(rightText.size()));

  int h = std::max(szL.cy, szR.cy);
  y += h + kLinePadPx;
}

// Item row: Desc | Qty | Price | Total
static void DrawItemRow(HDC hdc, int left, int& y, int cw, int maxChars, HFONT font,
                        const std::wstring& desc, const std::wstring& qty,
                        const std::wstring& price, const std::wstring& total) {
  SelectObject(hdc, font);
  UINT oldAlign = SetTextAlign(hdc, TA_LEFT | TA_TOP);

  int xDesc = left;
  int xQty = left + (cw * 17);
  int priceColEnd = std::min(28, maxChars - 9);
  int totalColEnd = std::min(37, maxChars);
  int xPriceRight = left + (cw * priceColEnd);
  int xTotalRight = left + (cw * totalColEnd);

  TextOutW(hdc, xDesc, y, desc.c_str(), static_cast<int>(desc.size()));
  TextOutW(hdc, xQty, y, qty.c_str(), static_cast<int>(qty.size()));

  SetTextAlign(hdc, TA_RIGHT | TA_TOP);
  TextOutW(hdc, xPriceRight, y, price.c_str(), static_cast<int>(price.size()));
  TextOutW(hdc, xTotalRight, y, total.c_str(), static_cast<int>(total.size()));
  SetTextAlign(hdc, oldAlign);

  SIZE sz{};
  GetTextExtentPoint32W(hdc, L"X", 1, &sz);
  y += sz.cy + kLinePadPx;
}

bool PrintSettlementGdi(const ReceiptData& r) {
  std::wstring printerW;
  if (r.printer_name.empty()) {
    wchar_t buf[256] = {};
    DWORD len = 256;
    if (GetDefaultPrinterW(buf, &len)) printerW = buf;
  } else {
    printerW = Utf8ToWide(r.printer_name);
  }

  const wchar_t* pPrinter = printerW.empty() ? nullptr : printerW.c_str();
  const bool wantPdf = (printerW.find(L"Microsoft Print to PDF") != std::wstring::npos);

  HDC hdc = nullptr;
  if (wantPdf) {
    hdc = CreatePdfDcWith80mmPaper();
  }
  if (!hdc) {
    hdc = CreateDCW(L"WINSPOOL", pPrinter, nullptr, nullptr);
  }
  if (!hdc && pPrinter != nullptr) hdc = CreatePdfDcWith80mmPaper();
  if (!hdc && printerW.empty()) hdc = CreatePdfDcWith80mmPaper();
  if (!hdc) return false;

  DOCINFOW di = {};
  di.cbSize = sizeof(di);
  di.lpszDocName = L"Settlement Receipt";

  if (StartDocW(hdc, &di) <= 0) {
    DeleteDC(hdc);
    return false;
  }
  if (StartPage(hdc) <= 0) {
    EndDoc(hdc);
    DeleteDC(hdc);
    return false;
  }

  SetBkMode(hdc, TRANSPARENT);
  SetTextAlign(hdc, TA_LEFT | TA_TOP);
  SetMapMode(hdc, MM_TEXT);

  int logPixelsY = GetDeviceCaps(hdc, LOGPIXELSY);
  int pageWidth = GetDeviceCaps(hdc, HORZRES);

  int fontHeight10 = -MulDiv(10, logPixelsY, 72);
  int fontHeight9 = -MulDiv(9, logPixelsY, 72);
  int fontHeight8 = -MulDiv(8, logPixelsY, 72);
  int fontHeight13 = -MulDiv(13, logPixelsY, 72);

  HFONT fontBold = CreateFontW(fontHeight10, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                               DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                               DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, L"Courier New");

  HFONT font = CreateFontW(fontHeight9, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                           DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                           DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, L"Courier New");

  HFONT fontSmall = CreateFontW(fontHeight8, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                                DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, L"Courier New");

  HFONT bigBold = CreateFontW(fontHeight13, 0, 0, 0, FW_BOLD,
                              FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                              OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                              DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN,
                              L"Courier New");

  TEXTMETRICW tm{};
  SelectObject(hdc, font);
  GetTextMetricsW(hdc, &tm);

  int left = 10;
  int y = 15;
  int charWidth = std::max(1, static_cast<int>(tm.tmAveCharWidth));

  // VB uses fixed 48-char layout and fixed X positions - no page-width dependency.
  // For PDF (wide page), force narrow layout to match thermal/ physical printer.
  const int kBillingLayoutChars = 48;  // VB: "--------------------------------------------------------------"
  if (wantPdf && pageWidth > (kBillingLayoutChars * charWidth + 20)) {
    pageWidth = kBillingLayoutChars * charWidth + (left * 2);
  }

  int usableWidthPx = pageWidth - (left * 2);
  int charsPerLine = usableWidthPx / charWidth;
  if (charsPerLine > 48) charsPerLine = 48;
  if (charsPerLine < 32) charsPerLine = 32;
  std::wstring sep(charsPerLine, L'-');

  // HEADER
  if (!r.trn_no.empty()) {
    DrawCenteredAuto(hdc, pageWidth, y, fontBold, L"TRN No: " + Utf8ToWide(r.trn_no));
  }

  DrawLineAuto(hdc, left, y, fontBold, sep);
  DrawCenteredAuto(hdc, pageWidth, y, bigBold, L"Tax Invoice");
  DrawCenteredAuto(hdc, pageWidth, y, font, L"\x0641\x0627\x062a\x0648\x0631\x0629 \x0636\x0631\x064a\x0628\x064a\x0629");
  DrawLineAuto(hdc, left, y, fontBold, sep);

  // Counter-POS style header + JobNo under Bill #
  DrawLeftRightAuto(hdc, pageWidth, left, y, fontBold,
                    L"BILL # : " + Utf8ToWide(r.bill_no),
                    Utf8ToWide(r.date_str) + L" " + Utf8ToWide(r.time_str));

  {
    std::string jobLabel = r.job_no;
    if (jobLabel.empty()) jobLabel = r.order_no_display;
    if (!jobLabel.empty()) {
      DrawLineAuto(hdc, left, y, fontBold, L"JOB #  : " + Utf8ToWide(jobLabel));
    }
  }

  DrawLeftRightAuto(hdc, pageWidth, left, y, fontBold,
                    L"COUNTER : " + Utf8ToWide(r.counter_no),
                    L"CASHIER : " + Utf8ToWide(r.cashier_name));

  DrawLeftRightAuto(hdc, pageWidth, left, y, fontBold,
                    L"CHAIR : " + Utf8ToWide(r.table_name),
                    L"STYLIST : " + Utf8ToWide(r.waiter_name));

  if (r.show_customer && !r.customer_name.empty()) {
    DrawLineAuto(hdc, left, y, fontBold, sep);
    DrawLineAuto(hdc, left, y, fontBold, L"Customer : " + Utf8ToWide(r.customer_name));
    if (!r.customer_code.empty()) {
      DrawLineAuto(hdc, left, y, fontBold, L"Code     : " + Utf8ToWide(r.customer_code));
    }
    if (!r.tax_reg_no.empty()) {
      DrawLineAuto(hdc, left, y, fontBold, L"TRN      : " + Utf8ToWide(r.tax_reg_no));
    }
    if (!r.mobile_no.empty()) {
      DrawLineAuto(hdc, left, y, fontBold, L"Tel      : " + Utf8ToWide(r.mobile_no));
    }
    if (!r.address.empty()) {
      DrawLineAuto(hdc, left, y, fontBold, L"Address  : " + Utf8ToWide(r.address));
    }
  }

  if (!r.comments.empty() && r.comments != "0") {
    DrawLineAuto(hdc, left, y, fontBold, L"Comments : " + Utf8ToWide(r.comments));
  }

  y += 6;
  DrawLineAuto(hdc, left, y, fontBold, sep);
  DrawItemRow(hdc, left, y, charWidth, charsPerLine, fontBold,
              L"Description     ", L"Qty", L"Price", L"Total");
  DrawLineAuto(hdc, left, y, fontBold, sep);

  for (const auto& item : r.items) {
    std::wstring desc = Utf8ToWide(item.desc);
    if (desc.size() > 16) desc = desc.substr(0, 16);
    desc = PadRight(desc, 16);

    DrawItemRow(hdc, left, y, charWidth, charsPerLine, font, desc,
                Utf8ToWide(item.qty), Utf8ToWide(item.price), Utf8ToWide(item.total));

    if (!item.tax_line.empty()) {
      DrawLineAuto(hdc, left, y, font, Utf8ToWide(item.tax_line));
    }
  }

  // TOTAL & SETTLEMENT
  DrawLineAuto(hdc, left, y, fontBold, sep);

  DrawLeftRightAuto(hdc, pageWidth, left, y, fontBold, L"TOTAL  :", Utf8ToWide(r.net_amount));
  DrawLineAuto(hdc, left, y, fontBold, sep);

  DrawLineAuto(hdc, left, y, fontBold, L"Settlement : " + Utf8ToWide(r.payment_mode));

  for (const auto& split : r.payment_splits) {
    DrawLeftRightAuto(hdc, pageWidth, left, y, fontBold,
                      Utf8ToWide(split.pay_mode),
                      Utf8ToWide(split.amount));
  }

  DrawLeftRightAuto(hdc, pageWidth, left, y, fontBold,
                    L"Items : " + std::to_wstring(r.items.size()),
                    L"Bill Amt : " + Utf8ToWide(r.net_amount));

  DrawLeftRightAuto(hdc, pageWidth, left, y, fontBold,
                    L"Qty : " + std::to_wstring(r.items.size()),
                    L"Paid Amt : " + Utf8ToWide(r.paid_amount));

  DrawLeftRightAuto(hdc, pageWidth, left, y, fontBold,
                    L"",
                    L"Bal. Amount: " + Utf8ToWide(r.balance_paid));

  if (!r.outstanding_balance.empty() ||
      (r.payment_mode == "CREDIT" || r.payment_mode == "credit")) {
    std::string os = r.outstanding_balance.empty() ? r.net_amount : r.outstanding_balance;
    DrawLeftRightAuto(hdc, pageWidth, left, y, fontBold,
                      L"O/S Balance",
                      Utf8ToWide(os));
  }

  DrawLineAuto(hdc, left, y, fontBold, sep);

  y += 8;
  DrawCenteredAuto(hdc, pageWidth, y, fontBold, L"Tax Details");
  DrawLineAuto(hdc, left, y, fontBold, sep);

  DrawLineAuto(hdc, left, y, font,
               PadRight(L"Taxable Amt", 14) + PadRight(Utf8ToWide(r.tax1_rate), 12) + PadRight(L"Bill Amt", 11));

  {
    int cw = charWidth;
    UINT oldA = SetTextAlign(hdc, TA_LEFT | TA_TOP);
    SelectObject(hdc, font);
    int x1 = left;
    int x2Right = left + (cw * 18);
    int x3Right = left + (cw * std::min(charsPerLine, 30));
    TextOutW(hdc, x1, y, Utf8ToWide(r.taxable_amount).c_str(), static_cast<int>(Utf8ToWide(r.taxable_amount).size()));
    SetTextAlign(hdc, TA_RIGHT | TA_TOP);
    TextOutW(hdc, x2Right, y, Utf8ToWide(r.tax1_amount).c_str(), static_cast<int>(Utf8ToWide(r.tax1_amount).size()));
    TextOutW(hdc, x3Right, y, Utf8ToWide(r.net_amount).c_str(), static_cast<int>(Utf8ToWide(r.net_amount).size()));
    SetTextAlign(hdc, oldA);
    SIZE szT{};
    GetTextExtentPoint32W(hdc, L"X", 1, &szT);
    y += szT.cy + kLinePadPx;
  }

  DrawLineAuto(hdc, left, y, fontBold, sep);
  DrawCenteredAuto(hdc, pageWidth, y, fontBold, L"Thank You... Visit Again");

  DeleteObject(font);
  DeleteObject(fontSmall);
  DeleteObject(fontBold);
  DeleteObject(bigBold);

  EndPage(hdc);
  EndDoc(hdc);
  DeleteDC(hdc);
  return true;
}

// KOT print - matches VB Print_KOT layout (48 chars, Courier New)
bool PrintKOTGdi(const KotData& k) {
  std::wstring printerW;
  if (k.printer_name.empty()) {
    wchar_t buf[256] = {};
    DWORD len = 256;
    if (GetDefaultPrinterW(buf, &len)) printerW = buf;
  } else {
    printerW = Utf8ToWide(k.printer_name);
  }

  const wchar_t* pPrinter = printerW.empty() ? nullptr : printerW.c_str();
  const bool wantPdf = (printerW.find(L"Microsoft Print to PDF") != std::wstring::npos);

  HDC hdc = nullptr;
  if (wantPdf) {
    hdc = CreatePdfDcWith80mmPaper();
  }
  if (!hdc) {
    hdc = CreateDCW(L"WINSPOOL", pPrinter, nullptr, nullptr);
  }
  if (!hdc && pPrinter != nullptr) hdc = CreatePdfDcWith80mmPaper();
  if (!hdc && printerW.empty()) hdc = CreatePdfDcWith80mmPaper();
  if (!hdc) return false;

  DOCINFOW di = {};
  di.cbSize = sizeof(di);
  di.lpszDocName = L"Job";

  if (StartDocW(hdc, &di) <= 0) {
    DeleteDC(hdc);
    return false;
  }
  if (StartPage(hdc) <= 0) {
    EndDoc(hdc);
    DeleteDC(hdc);
    return false;
  }

  SetBkMode(hdc, TRANSPARENT);
  SetTextAlign(hdc, TA_LEFT | TA_TOP);
  SetMapMode(hdc, MM_TEXT);

  int logPixelsY = GetDeviceCaps(hdc, LOGPIXELSY);
  int pageWidth = GetDeviceCaps(hdc, HORZRES);

  int fontHeight10 = -MulDiv(10, logPixelsY, 72);
  int fontHeight9 = -MulDiv(9, logPixelsY, 72);
  int fontHeight8 = -MulDiv(8, logPixelsY, 72);
  int fontHeight14 = -MulDiv(14, logPixelsY, 72);

  HFONT fontBold = CreateFontW(fontHeight10, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                               DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                               DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, L"Courier New");

  HFONT font = CreateFontW(fontHeight9, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                           DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                           DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, L"Courier New");

  HFONT fontSmall = CreateFontW(fontHeight8, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                                DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, L"Courier New");

  HFONT kotNumFont = CreateFontW(fontHeight14, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                                 DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                 DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, L"Segoe UI");

  TEXTMETRICW tm{};
  SelectObject(hdc, font);
  GetTextMetricsW(hdc, &tm);

  int left = 10;
  int y = 15;
  int charWidth = std::max(1, static_cast<int>(tm.tmAveCharWidth));

  const int kKOTLayoutChars = 48;
  if (wantPdf && pageWidth > (kKOTLayoutChars * charWidth + 20)) {
    pageWidth = kKOTLayoutChars * charWidth + (left * 2);
  }

  int charsPerLine = (pageWidth - left * 2) / charWidth;
  if (charsPerLine > 48) charsPerLine = 48;
  if (charsPerLine < 32) charsPerLine = 32;
  std::wstring sep(charsPerLine, L'-');

  const int kLineLen = 22;  // VB gvKOTLineLength

  // Header
  DrawCenteredAuto(hdc, pageWidth, y, kotNumFont, Utf8ToWide(k.title));
  DrawLineAuto(hdc, left, y, font, sep);

  // Kitchen Location - SupplyType
  std::string locLine = "             " + k.kitchen_location + " - " + k.supply_type;
  DrawLineAuto(hdc, left, y, fontBold, Utf8ToWide(locLine));
  DrawLineAuto(hdc, left, y, font, sep);

  // Job#PrefixNumber-AreaName
  std::string kotLine = "Job#" + k.kot_prefix + k.kot_number + "-" + k.area_name;
  DrawLineAuto(hdc, left, y, kotNumFont, Utf8ToWide(kotLine));
  if (!k.table_name.empty()) {
    DrawLineAuto(hdc, left, y, kotNumFont, L"Table No - " + Utf8ToWide(k.table_name));
  }
  y += 10;
  DrawLineAuto(hdc, left, y, font, sep);
  y += 5;

  // Counter : X    dd/MM/yyyy   HH:mm:ss
  std::string infoLine = "Counter : " + k.counter_no + "  " + k.date_str + "  " + k.time_str;
  DrawLineAuto(hdc, left, y, fontBold, Utf8ToWide(infoLine));
  y += 15;

  // Waiter (and Chair No if > 1)
  std::string waiterLine = "Waiter:" + k.waiter_name;
  if (k.chair_no > 1) {
    waiterLine += "    Chair No:" + std::to_string(k.chair_no);
  }
  DrawLineAuto(hdc, left, y, fontBold, Utf8ToWide(waiterLine));
  y += 15;

  DrawLineAuto(hdc, left, y, font, sep);
  DrawLineAuto(hdc, left, y, font, L"Qty  Description            ");
  DrawLineAuto(hdc, left, y, font, sep);
  y += 15;

  // Items
  for (const auto& it : k.items) {
    char qtyBuf[32];
    snprintf(qtyBuf, sizeof(qtyBuf), "%.3g", it.qty);
    std::string itemStr = std::string(qtyBuf) + "  -" + it.short_description;
    if (itemStr.size() > static_cast<size_t>(kLineLen))
      itemStr = itemStr.substr(0, kLineLen);
    DrawLineAuto(hdc, left, y, fontBold, Utf8ToWide(itemStr));

    if (!it.modifier.empty()) {
      std::string modStr = it.modifier;
      size_t pos = 0;
      while (pos < modStr.size()) {
        size_t dash = modStr.find('-', pos);
        std::string part = (dash != std::string::npos)
            ? modStr.substr(pos, dash - pos) : modStr.substr(pos);
        while (!part.empty() && (part[0] == ' ' || part[0] == '-')) part.erase(0, 1);
        if (!part.empty()) {
          std::string modLine = "+++ " + part + " +++";
          DrawLineAuto(hdc, left, y, fontSmall, Utf8ToWide(modLine));
        }
        pos = (dash != std::string::npos) ? dash + 1 : modStr.size();
      }
    }
    y += 15;
  }

  // Footer
  DrawLineAuto(hdc, left, y, font, sep);
  DrawLineAuto(hdc, left, y, font, L"Items  : " + std::to_wstring(k.item_count));
  DrawLineAuto(hdc, left, y, font, L"Qty      : " + std::to_wstring(static_cast<int>(k.total_qty)));
  DrawLineAuto(hdc, left, y, font, sep);

  time_t now = time(nullptr);
  struct tm tbuf;
  localtime_s(&tbuf, &now);
  char timeBuf[32];
  strftime(timeBuf, sizeof(timeBuf), "%H:%M %p", &tbuf);
  DrawLineAuto(hdc, left, y, fontBold, L"Printed Time : " + Utf8ToWide(std::string(timeBuf)));

  DeleteObject(font);
  DeleteObject(fontSmall);
  DeleteObject(fontBold);
  DeleteObject(kotNumFont);

  EndPage(hdc);
  EndDoc(hdc);
  DeleteDC(hdc);
  return true;
}

}  // namespace

static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_channel;

void RegisterNativeSettlementPrinter(flutter::BinaryMessenger* messenger) {
  g_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.myapp/native_settlement_print",
      &flutter::StandardMethodCodec::GetInstance());

  g_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const auto* args = call.arguments();
        if (!args) {
          result->Error("INVALID_ARGS", "Missing arguments");
          return;
        }

        if (call.method_name() == "printSettlementReceipt") {
          ReceiptData data;
          if (!ParseReceiptData(*args, data)) {
            result->Error("INVALID_ARGS", "Invalid receipt data");
            return;
          }
          if (PrintSettlementGdi(data)) {
            result->Success(flutter::EncodableValue());
          } else {
            result->Error("PRINT_FAILED", "Windows GDI print failed");
          }
          return;
        }

        if (call.method_name() == "printKotReceipt") {
          KotData data;
          if (!ParseKotData(*args, data)) {
            result->Error("INVALID_ARGS", "Invalid job data");
            return;
          }
          if (PrintKOTGdi(data)) {
            result->Success(flutter::EncodableValue());
          } else {
            result->Error("PRINT_FAILED", "Windows GDI job print failed");
          }
          return;
        }

        result->NotImplemented();
      });
}
