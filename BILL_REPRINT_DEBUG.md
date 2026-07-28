# Bill Reprint - Debugging Guide

## 🔍 Debug Logs Added

I've added comprehensive debug logging throughout the system to help identify the issue.

### **Frontend Debug Logs (Flutter)**
Look for these in your Flutter console/terminal:

```
🔵 Bill Reprint - Fetching bills for counter: X
🟢 Bill Reprint - Fetched X bills
🔵 Bill Reprint - Auto-selecting first bill
⚠️ Bill Reprint - No bills found for today
❌ Bill Reprint - Error loading bills: [error message]

🔵 Bill Reprint - Loading items for SalesID: X
🟢 Bill Reprint - Loaded details: [keys]
🟢 Bill Reprint - Items count: X
❌ Bill Reprint - Error loading items: [error message]

🔵 API - fetchTodayBills: URL=..., counterNo=X
🟢 API - fetchTodayBills: Status=200
🟢 API - fetchTodayBills: Response={...}
✅ API - fetchTodayBills: Found X bills
❌ API - fetchTodayBills: Error=[error]
```

### **Backend Debug Logs (Node.js)**
Look for these in your backend console:

```
🔵 getTodayBillsForReprint: counterNo= X
🔵 fetchTodayBillsForCounter: counterNo=X, today=2026-03-02
✅ fetchTodayBillsForCounter: Found X bills
✅ getTodayBillsForReprint: Returning X bills
❌ getTodayBillsForReprint: [error]
❌ Error in fetchTodayBillsForCounter: [error message]
```

---

## 📋 Troubleshooting Steps

### **Step 1: Check if Backend is Running**
```bash
# Check if port 5002 is responding
curl http://localhost:5002
```

### **Step 2: Test API Directly**
```bash
# Test the billReprint endpoint
curl -X POST http://localhost:5002/billReprint \
  -H "Content-Type: application/json" \
  -H "stationid: 1" \
  -H "staffname: Admin" \
  -d '{"counterNo": 1}'
```

**Expected Response:**
```json
{
  "success": true,
  "data": [
    {
      "SalesID": 123,
      "BillNo": "INV001",
      "HoldNo": 45,
      "Amount": 150.50,
      "PaymentMode": "CASH",
      "BillTime": "2026-03-02T14:30:00",
      "TransactionType": "S",
      "PaidCurrency": "AED"
    }
  ]
}
```

### **Step 3: Check Database**
```sql
-- Check if you have bills for today
SELECT 
  "SalesID",
  "BillNo",
  "CounterNo",
  "BillDate",
  "Amount"
FROM public."SalesMaster"
WHERE "CounterNo" = 1
  AND DATE("BillDate") = CURRENT_DATE
ORDER BY "SalesID" DESC;
```

---

## 🐛 Common Issues & Solutions

### **Issue 1: No Bills Showing**

**Possible Causes:**
1. No bills created today for your counter
2. Wrong counter number
3. Date mismatch (server timezone vs database)

**Solution:**
- Check the backend logs for: `fetchTodayBillsForCounter: Found X bills`
- If it says "Found 0 bills", create a test bill first
- Check your database to see if BillDate matches today

### **Issue 2: API Error / Network Error**

**Possible Causes:**
1. Backend not running on port 5002
2. Wrong API URL in Flutter config
3. CORS or firewall blocking

**Solution:**
- Check `lib/config/api_config.dart` for correct baseUrl
- Restart backend server
- Check Flutter console for the exact URL being called

### **Issue 3: Items Not Loading**

**Possible Causes:**
1. SalesID not found in database
2. No items in SalesChild table
3. API response format mismatch

**Solution:**
- Check backend logs: `fetchSalesDetails`
- Verify SalesChild table has records for that SalesID

---

## 🎯 Quick Diagnostic Checklist

When you open Bill Reprint dialog, you should see:

**✅ Normal Flow:**
```
Frontend Console:
🔵 Bill Reprint - Fetching bills for counter: 1
🔵 API - fetchTodayBills: URL=http://localhost:5002/billReprint, counterNo=1
🟢 API - fetchTodayBills: Status=200
🟢 API - fetchTodayBills: Response={"success":true,"data":[...]}
✅ API - fetchTodayBills: Found 5 bills
🟢 Bill Reprint - Fetched 5 bills
🔵 Bill Reprint - Auto-selecting first bill
🔵 Bill Reprint - Loading items for SalesID: 123
🟢 Bill Reprint - Loaded details: {salesMaster, salesItems}
🟢 Bill Reprint - Items count: 3

Backend Console:
🔵 getTodayBillsForReprint: counterNo= 1
🔵 fetchTodayBillsForCounter: counterNo=1, today=2026-03-02
✅ fetchTodayBillsForCounter: Found 5 bills
✅ getTodayBillsForReprint: Returning 5 bills
```

---

## 🚀 Next Steps

1. **Run the Flutter app in debug mode**
2. **Open Bill Reprint dialog from Reports menu**
3. **Copy ALL the console logs** from both Flutter and Backend
4. **Share the logs** so I can see exactly what's happening

The logs will show:
- What counter number is being used
- What API URL is being called
- What response is coming back
- Any errors in the data flow

---

## 📝 Files Modified (With Debug Logs)

- ✅ `lib/widgets/topPanelWidgets/ReportTab/billReprint.dart` - Added frontend logs
- ✅ `lib/services/api_service.dart` - Added API call logs
- ✅ `backend/services/salesServices.js` - Added backend service logs
- ✅ `backend/controllers/salesController.js` - Added controller logs
