import 'package:flutter/material.dart';

class PaymentReceivedScreen extends StatelessWidget {
  const PaymentReceivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: _TransactionHistoryUI(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Transaction History",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _TransactionHistoryUI extends StatefulWidget {
  @override
  State<_TransactionHistoryUI> createState() => _TransactionHistoryUIState();
}

class _TransactionHistoryUIState extends State<_TransactionHistoryUI> {
  bool _showAllTransactions = true;

  final List<Map<String, dynamic>> allTransactions = [
    {
      "title": "NPCI BHIM",
      "subtitle": "Received money from",
      "time": "13 Nov, 3:03 PM",
      "amount": "₹2",
      "note": "Bank Account",
      "incoming": true,
      "failed": false,
      "type": "all"
    },
    {
      "title": "AKHAND SINGH",
      "subtitle": "Money sent to",
      "time": "13 Nov, 3:03 PM",
      "amount": "₹110",
      "note": "",
      "incoming": false,
      "failed": true,
      "type": "all"
    },
    {
      "title": "NPCI BHIM",
      "subtitle": "Received money from",
      "time": "13 Nov, 1:25 PM",
      "amount": "₹3",
      "note": "Bank Account",
      "incoming": true,
      "failed": false,
      "type": "all"
    },
    {
      "title": "FLIPKART PAYMENTS",
      "subtitle": "Money sent to",
      "time": "13 Nov, 1:25 PM",
      "amount": "₹882",
      "note": "",
      "incoming": false,
      "failed": true,
      "type": "all"
    },
    {
      "title": "SAFERICH ONLINE",
      "subtitle": "Received money from",
      "time": "13 Nov, 11:46 AM",
      "amount": "₹5,000",
      "note": "Bank Account",
      "incoming": true,
      "failed": false,
      "type": "all"
    },
  ];

  final List<Map<String, dynamic>> upiCircleTransactions = [
    {
      "title": "Google Pay",
      "subtitle": "Received from UPI Circle",
      "time": "12 Nov, 2:30 PM",
      "amount": "₹500",
      "note": "UPI Circle",
      "incoming": true,
      "failed": false,
      "type": "upi"
    },
    {
      "title": "PhonePe",
      "subtitle": "Sent to UPI Circle",
      "time": "12 Nov, 11:15 AM",
      "amount": "₹250",
      "note": "UPI Circle",
      "incoming": false,
      "failed": false,
      "type": "upi"
    },
    {
      "title": "Paytm",
      "subtitle": "Received from UPI Circle",
      "time": "11 Nov, 4:45 PM",
      "amount": "₹1,200",
      "note": "UPI Circle",
      "incoming": true,
      "failed": false,
      "type": "upi"
    },
    {
      "title": "BHIM UPI",
      "subtitle": "Failed UPI Circle transaction",
      "time": "10 Nov, 9:20 AM",
      "amount": "₹750",
      "note": "UPI Circle",
      "incoming": false,
      "failed": true,
      "type": "upi"
    },
    {
      "title": "Amazon Pay",
      "subtitle": "Received from UPI Circle",
      "time": "9 Nov, 6:15 PM",
      "amount": "₹3,000",
      "note": "UPI Circle",
      "incoming": true,
      "failed": false,
      "type": "upi"
    },
    {
      "title": "WhatsApp Pay",
      "subtitle": "Sent to UPI Circle",
      "time": "8 Nov, 1:40 PM",
      "amount": "₹150",
      "note": "UPI Circle",
      "incoming": false,
      "failed": false,
      "type": "upi"
    },
  ];

  List<Map<String, dynamic>> get currentTransactions {
    return _showAllTransactions ? allTransactions : upiCircleTransactions;
  }

  Map<String, String> get currentSummary {
    if (_showAllTransactions) {
      return {
        "received": "₹5,005",
        "sent": "₹992",
        "balance": "₹4,013"
      };
    } else {
      return {
        "received": "₹4,700",
        "sent": "₹400",
        "balance": "₹4,300"
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterTabs(),
        const SizedBox(height: 8),
        _buildSummaryCard(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildTransactionList(),
        ),
      ],
    );
  }

  // ------------------- FILTER TABS -------------------
  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllTransactions = true;
              });
            },
            child: _buildFilterChip("All Transactions", _showAllTransactions),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllTransactions = false;
              });
            },
            child: _buildFilterChip("UPI Circle", !_showAllTransactions),
          ),
          const Spacer(),
          Text(
            "Filter",
            style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.filter_list, size: 18, color: Colors.deepPurple),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.deepPurple[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.deepPurple : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.deepPurple : Colors.black54,
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  // ------------------- SUMMARY CARD -------------------
  Widget _buildSummaryCard() {
    final summary = currentSummary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem("Total Received", summary["received"]!, Colors.green),
          _buildSummaryItem("Total Sent", summary["sent"]!, Colors.red),
          _buildSummaryItem("Balance", summary["balance"]!, Colors.deepPurple),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ------------------- TRANSACTION LIST -------------------
  Widget _buildTransactionList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: currentTransactions.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
        itemCount: currentTransactions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey[300],
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          return _buildTransactionTile(currentTransactions[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No transactions found",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showAllTransactions
                ? "You don't have any transactions yet"
                : "No UPI Circle transactions available",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- TRANSACTION TILE -------------------
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tx["incoming"] ? Colors.green[50] : Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          tx["incoming"] ? Icons.arrow_downward : Icons.arrow_upward,
          color: tx["incoming"] ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        tx["title"],
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            tx["subtitle"],
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tx["time"],
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            tx["amount"],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: tx["incoming"] ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 2),
          if (tx["failed"])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "Failed",
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (tx["note"].isNotEmpty)
            Text(
              tx["note"],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
        ],
      ),
      onTap: () {
        // Handle transaction tap
      },
    );
  }
}