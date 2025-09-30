import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class CategorySelectionScreen extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategorySelectionScreen({super.key, required this.onCategorySelected});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<CategoryGroup> _categories = [
    CategoryGroup(
      name: 'Foods & Drinks',
      icon: Icons.restaurant,
      color: Colors.red,
      subcategories: ['Groceries', 'Restaurant, Fast-food', 'Bar, cafe'],
    ),
    CategoryGroup(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: AppColors.lightBlue,
      subcategories: [
        'Clothes & Shoes',
        'Jewel, accessories',
        'Health and beauty',
        'Kids',
        'Stationary, tools',
        'Pets, animals',
        'Electronics, accessories',
        'Gift, joy',
        'Drug-store, chemist'
      ],
    ),
    CategoryGroup(
      name: 'Housing',
      icon: Icons.home,
      color: AppColors.orange,
      subcategories: ['Rent', 'Mortgage', 'Utilities'],
    ),
    CategoryGroup(
      name: 'Transportation',
      icon: Icons.directions_bus,
      color: Colors.grey,
      subcategories: ['Public Transport', 'Taxi', 'Gas'],
    ),
    CategoryGroup(
      name: 'Vehicle',
      icon: Icons.directions_car,
      color: AppColors.purple,
      subcategories: ['Leasing', 'Insurance', 'Maintenance'],
    ),
    CategoryGroup(
      name: 'Life & Entertainment',
      icon: Icons.sports_esports,
      color: AppColors.green,
      subcategories: ['Sports', 'Movies', 'Games'],
    ),
    CategoryGroup(
      name: 'Communication & PC',
      icon: Icons.phone,
      color: AppColors.primaryBlue,
      subcategories: ['Internet', 'Phone Bill', 'Software'],
    ),
    CategoryGroup(
      name: 'Investments',
      icon: Icons.trending_up,
      color: Colors.pink,
      subcategories: ['Stocks', 'Crypto', 'Savings'],
    ),
    CategoryGroup(
      name: 'Income',
      icon: Icons.attach_money,
      color: AppColors.yellow,
      subcategories: ['Salary', 'Freelance', 'Investment Return'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ALL CATEGORIES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            // Categories List
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubcategoryScreen(
                            category: category,
                            onSubcategorySelected: widget.onCategorySelected,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: category.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              category.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class SubcategoryScreen extends StatelessWidget {
  final CategoryGroup category;
  final Function(String) onSubcategorySelected;

  const SubcategoryScreen({
    super.key,
    required this.category,
    required this.onSubcategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Category Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SUB CATEGORIES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            // Subcategories List
            Expanded(
              child: ListView.builder(
                itemCount: category.subcategories.length,
                itemBuilder: (context, index) {
                  final subcategory = category.subcategories[index];
                  return GestureDetector(
                    onTap: () {
                      onSubcategorySelected(subcategory);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: category.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              category.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              subcategory,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryGroup {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> subcategories;

  CategoryGroup({
    required this.name,
    required this.icon,
    required this.color,
    required this.subcategories,
  });
}