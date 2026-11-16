// lib/features/diner/browse_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

class DinerBrowsePage extends StatefulWidget {
  const DinerBrowsePage({super.key});

  @override
  State<DinerBrowsePage> createState() => _DinerBrowsePageState();
}

class _DinerBrowsePageState extends State<DinerBrowsePage> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  void _loadRestaurants() {
    setState(() {
      _future = Supabase.instance.client
          .from('restaurants')
          .select()
          .eq('is_active', true)
          .order('name');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGray,
      // 👇 Responsive Wrapper for Web/Desktop
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            onRefresh: () async => _loadRestaurants(),
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // 1. Gradient Header Section
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDCFCE7), Color(0xFFF9FAFB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.person, color: AppTheme.primaryGreen),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Hello, Diner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                    Text('Ready to skip the queue?', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
                                  ],
                                ),
                              ],
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(Icons.notifications_none, color: AppTheme.textDark),
                                onPressed: () {},
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Wallet Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Today\'s Budget', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                                  SizedBox(height: 4),
                                  Text('\$150.00', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                  SizedBox(height: 4),
                                  Text('Table Relay Wallet', style: TextStyle(color: AppTheme.textGray, fontSize: 10)),
                                ],
                              ),
                              const Icon(Icons.account_balance_wallet, size: 48, color: AppTheme.primaryGreen),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Time Info Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: const [
                                    Icon(Icons.access_time, size: 20, color: AppTheme.textGray),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order by', style: TextStyle(fontSize: 10, color: AppTheme.textGray)),
                                        Text('10:30 AM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: const [
                                    Icon(Icons.directions_run, size: 20, color: AppTheme.textGray),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Relay Time', style: TextStyle(fontSize: 10, color: AppTheme.textGray)),
                                        Text('12:30 PM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Categories Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Choose Cuisine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            Text('View all', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryChip(Icons.rice_bowl, 'Local', true),
                              _buildCategoryChip(Icons.local_cafe, 'Cafe', false),
                              _buildCategoryChip(Icons.fastfood, 'Fast Food', false),
                              _buildCategoryChip(Icons.ramen_dining, 'Asian', false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Restaurant List Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Popular Near You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        const SizedBox(height: 16),
                        
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                            }
                            
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }

                            final rows = snapshot.data ?? [];
                            if (rows.isEmpty) {
                              return const Center(child: Text('No restaurants available.'));
                            }

                            // Using ListView.builder inside the main scroll view
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: rows.length,
                              itemBuilder: (context, i) {
                                final r = rows[i];
                                final queueMinutes = r['avg_queue_minutes'] as int? ?? 0;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildRestaurantCard(
                                    context: context,
                                    name: r['name'] as String? ?? 'Unknown',
                                    address: r['address'] as String? ?? 'Address not listed',
                                    queueMinutes: queueMinutes,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 40), // Bottom padding for scroll
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper for Category Chips
  Widget _buildCategoryChip(IconData icon, String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.lightGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AppTheme.primaryGreen : AppTheme.textGray),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textGray,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper for Restaurant Cards
  Widget _buildRestaurantCard({
    required BuildContext context,
    required String name,
    required String address,
    required int queueMinutes,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate to detail page here later
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected $name')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image Placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&q=80&w=200'), 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(address, style: const TextStyle(fontSize: 12, color: AppTheme.textGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          const Text('4.8', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: queueMinutes > 20 ? Colors.red : AppTheme.primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            '$queueMinutes min',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: queueMinutes > 20 ? Colors.red : AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Add Button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}