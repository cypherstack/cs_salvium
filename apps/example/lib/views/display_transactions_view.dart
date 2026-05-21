import 'package:cs_salvium/cs_salvium.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../util.dart';

class DisplayTransactionsView extends StatefulWidget {
  const DisplayTransactionsView({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<DisplayTransactionsView> createState() =>
      _DisplayTransactionsViewState();
}

class _DisplayTransactionsViewState extends State<DisplayTransactionsView> {
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String _filterText = '';
  TransactionFilter _filterType = TransactionFilter.all;
  TransactionTypeFilter _transactionTypeFilter = TransactionTypeFilter.all;
  SortOrder _sortOrder = SortOrder.newest;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh and get all transactions
      final transactions = await widget.wallet.getAllTxs(refresh: true);

      setState(() {
        _transactions = transactions;
        _filteredTransactions = _applyFilters(transactions);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transactions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Transaction> _applyFilters(List<Transaction> transactions) {
    List<Transaction> filtered = transactions;

    // Apply transaction status filter
    switch (_filterType) {
      case TransactionFilter.received:
        filtered = filtered.where((tx) => !tx.isSpend).toList();
        break;
      case TransactionFilter.sent:
        filtered = filtered.where((tx) => tx.isSpend).toList();
        break;
      case TransactionFilter.pending:
        filtered = filtered.where((tx) => tx.isPending).toList();
        break;
      case TransactionFilter.confirmed:
        filtered = filtered.where((tx) => tx.isConfirmed).toList();
        break;
      case TransactionFilter.all:
        // No filter
        break;
    }

    // Apply transaction type filter
    if (_transactionTypeFilter != TransactionTypeFilter.all) {
      filtered = filtered
          .where((tx) => _transactionTypeFilter.matches(tx.type.value))
          .toList();
    }

    // Apply text filter
    if (_filterText.isNotEmpty) {
      filtered = filtered.where((tx) {
        final searchText = _filterText.toLowerCase();
        return tx.hash.toLowerCase().contains(searchText) ||
            tx.displayLabel.toLowerCase().contains(searchText) ||
            tx.description.toLowerCase().contains(searchText) ||
            tx.paymentId.toLowerCase().contains(searchText);
      }).toList();
    }

    // Apply sorting
    switch (_sortOrder) {
      case SortOrder.newest:
        filtered.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        break;
      case SortOrder.oldest:
        filtered.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
        break;
      case SortOrder.highest:
        filtered.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
        break;
      case SortOrder.lowest:
        filtered.sort((a, b) => a.amount.abs().compareTo(b.amount.abs()));
        break;
    }

    return filtered;
  }

  void _updateFilter() {
    setState(() {
      _filteredTransactions = _applyFilters(_transactions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions (${_filteredTransactions.length})'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and Sort Controls
          _buildFilterControls(),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              _filterText = value;
              _updateFilter();
            },
            decoration: const InputDecoration(
              labelText: 'Search transactions...',
              hintText: 'Hash, label, description, payment ID',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Status Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Status: ',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                ...TransactionFilter.values.map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.displayName),
                      selected: _filterType == filter,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _filterType = filter;
                            _updateFilter();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Transaction Type Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Type: ',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                ...TransactionTypeFilter.values.map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.displayName),
                      selected: _transactionTypeFilter == filter,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _transactionTypeFilter = filter;
                            _updateFilter();
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Sort order
                DropdownButton<SortOrder>(
                  value: _sortOrder,
                  onChanged: (SortOrder? value) {
                    if (value != null) {
                      setState(() {
                        _sortOrder = value;
                        _updateFilter();
                      });
                    }
                  },
                  items: SortOrder.values.map((order) {
                    return DropdownMenuItem<SortOrder>(
                      value: order,
                      child: Text(order.displayName),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _transactions.isEmpty
                ? 'No transactions found'
                : 'No transactions match your filter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          if (_transactions.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterText = '';
                  _filterType = TransactionFilter.all;
                  _transactionTypeFilter = TransactionTypeFilter.all;
                  _updateFilter();
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];
          return _buildTransactionItem(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isReceived = !transaction.isSpend;
    final formattedAmountStr = formattedAmount(
      transaction.amount.abs(),
      widget.wallet.runtimeType,
    );

    final statusColor = transaction.isPending
        ? Colors.orange
        : transaction.isConfirmed
            ? Colors.green
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isReceived
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isReceived ? Icons.call_received : Icons.call_made,
            color: isReceived ? Colors.green : Colors.red,
          ),
        ),
        title: Row(
          children: [
            Text(
              '${isReceived ? '+' : '-'} $formattedAmountStr SAL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isReceived ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            if (transaction.type !=
                TxType
                    .Unset) // Show type indicator for non-standard transactions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTransactionTypeIcon(transaction.type.value),
                      size: 12,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTransactionTypeShortName(transaction.type.value),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                transaction.isPending
                    ? 'Pending (${transaction.confirmations}/${transaction.minConfirms.value})'
                    : 'Confirmed',
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.displayLabel.isNotEmpty)
              Text(
                transaction.displayLabel,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            Text(
              _formatDate(transaction.timeStamp),
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Hash: ${transaction.hash.substring(0, 16)}...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getTransactionTypeIcon(int type) {
    switch (type) {
      case 0:
        return Icons.swap_horiz;
      case 1:
        return Icons.diamond; // Miner
      case 3:
        return Icons.send; // Transfer
      case 6:
        return Icons.savings; // Stake
      default:
        return Icons.help_outline; // Default for all other types
    }
  }

  String _getTransactionTypeShortName(int type) {
    switch (type) {
      case 0:
        return 'STD';
      case 1:
        return 'MINER';
      case 2:
        return 'PROTOCOL';
      case 3:
        return 'TRANSFER';
      case 4:
        return 'CONVERT';
      case 5:
        return 'BURN';
      case 6:
        return 'STAKE';
      case 7:
        return 'RETURN';
      case 8:
        return 'AUDIT';
      default:
        return 'T$type';
    }
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailItem(
                      'Direction',
                      transaction.isSpend ? 'Sent' : 'Received',
                      icon: transaction.isSpend
                          ? Icons.call_made
                          : Icons.call_received,
                    ),
                    _buildDetailItem(
                      'Transaction Type',
                      transaction.type.displayName,
                      icon: _getTransactionTypeIcon(transaction.type.value),
                    ),
                    _buildDetailItem(
                      'Amount',
                      '${transaction.isSpend ? '-' : '+'} ${formattedAmount(transaction.amount.abs(), widget.wallet.runtimeType)} SAL',
                    ),
                    _buildDetailItem(
                      'Fee',
                      '${formattedAmount(transaction.fee, widget.wallet.runtimeType)} SAL',
                    ),
                    _buildDetailItem(
                      'Status',
                      transaction.isPending
                          ? 'Pending (${transaction.confirmations}/${transaction.minConfirms.value})'
                          : 'Confirmed (${transaction.confirmations} confirmations)',
                    ),
                    _buildDetailItem(
                      'Date & Time',
                      transaction.timeStamp.toLocal().toString().split('.')[0],
                    ),
                    _buildDetailItem(
                      'Block Height',
                      transaction.blockHeight.toString(),
                    ),
                    _buildDetailItem(
                      'Transaction Hash',
                      transaction.hash,
                      copyable: true,
                    ),
                    if (transaction.paymentId.isNotEmpty)
                      _buildDetailItem(
                        'Payment ID',
                        transaction.paymentId,
                        copyable: true,
                      ),
                    if (transaction.key.isNotEmpty)
                      _buildDetailItem(
                        'Transaction Key',
                        transaction.key,
                        copyable: true,
                      ),
                    _buildDetailItem(
                      'Account Index',
                      transaction.accountIndex.toString(),
                    ),
                    if (transaction.addressIndexes.isNotEmpty)
                      _buildDetailItem(
                        'Address Indexes',
                        transaction.addressIndexes.join(', '),
                      ),
                    if (transaction.displayLabel.isNotEmpty)
                      _buildDetailItem(
                        'Label',
                        transaction.displayLabel,
                      ),
                    if (transaction.description.isNotEmpty)
                      _buildDetailItem(
                        'Description',
                        transaction.description,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    IconData? icon,
    bool copyable = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (copyable)
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied $label to clipboard'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 13,
              fontFamily: copyable ? 'monospace' : null,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// Enums for filtering and sorting
enum TransactionFilter {
  all,
  received,
  sent,
  pending,
  confirmed;

  String get displayName {
    switch (this) {
      case TransactionFilter.all:
        return 'All';
      case TransactionFilter.received:
        return 'Received';
      case TransactionFilter.sent:
        return 'Sent';
      case TransactionFilter.pending:
        return 'Pending';
      case TransactionFilter.confirmed:
        return 'Confirmed';
    }
  }
}

enum TransactionTypeFilter {
  all,
  MINER,
  PROTOCOL,
  TRANSFER,
  CONVERT,
  BURN,
  STAKE,
  RETURN,
  AUDIT;

  String get displayName {
    switch (this) {
      case TransactionTypeFilter.all:
        return 'All Types';
      case TransactionTypeFilter.MINER:
        return 'Miner';
      case TransactionTypeFilter.PROTOCOL:
        return 'Protocol';
      case TransactionTypeFilter.STAKE:
        return 'Stake';
      case TransactionTypeFilter.RETURN:
        return 'Return';
      case TransactionTypeFilter.AUDIT:
        return 'Audit';
      case TransactionTypeFilter.TRANSFER:
        return 'Transfer';
      case TransactionTypeFilter.CONVERT:
        return 'Convert';
      case TransactionTypeFilter.BURN:
        return 'Burn';
    }
  }

  bool matches(int type) {
    switch (this) {
      case TransactionTypeFilter.all:
        return true;
      case TransactionTypeFilter.MINER:
        return type == 1;
      case TransactionTypeFilter.PROTOCOL:
        return type == 2;
      case TransactionTypeFilter.STAKE:
        return type == 6;
      case TransactionTypeFilter.RETURN:
        return type == 7;
      case TransactionTypeFilter.AUDIT:
        return type == 8;
      case TransactionTypeFilter.TRANSFER:
        return type == 3;
      case TransactionTypeFilter.CONVERT:
        return type == 4;
      case TransactionTypeFilter.BURN:
        return type == 5;
    }
  }
}

enum SortOrder {
  newest,
  oldest,
  highest,
  lowest;

  String get displayName {
    switch (this) {
      case SortOrder.newest:
        return 'Newest First';
      case SortOrder.oldest:
        return 'Oldest First';
      case SortOrder.highest:
        return 'Highest Amount';
      case SortOrder.lowest:
        return 'Lowest Amount';
    }
  }
}
