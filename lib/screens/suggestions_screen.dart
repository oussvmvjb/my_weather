import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/daily_suggestion_model.dart';

class SuggestionsScreen extends StatefulWidget {
  final List<Weather> forecasts;
  final String city;

  const SuggestionsScreen({
    super.key,
    required this.forecasts,
    required this.city,
  });

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> with SingleTickerProviderStateMixin {
  late List<DailySuggestion> _suggestions;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedFilter = 0; // 0: All, 1: Indoor, 2: Outdoor
  final List<String> _filters = ['All Suggestions', 'Indoor Activities', 'Outdoor Activities'];

  @override
  void initState() {
    super.initState();
    _generateSuggestions();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }

  void _generateSuggestions() {
    _suggestions = generateDailySuggestions(widget.forecasts);
  }

  List<DailySuggestion> _getFilteredSuggestions() {
    if (_selectedFilter == 0) return _suggestions;
    
    return _suggestions.where((suggestion) {
      if (_selectedFilter == 1) {
        // Indoor activities
        return suggestion.options.any((option) => 
            option.contains('home') || 
            option.contains('Read') || 
            option.contains('project') ||
            option.contains('movie') ||
            option.contains('cafe') ||
            option.contains('Stay') ||
            option.contains('inside'));
      } else {
        // Outdoor activities
        return suggestion.options.any((option) => 
            option.contains('Go') || 
            option.contains('Walk') || 
            option.contains('sports') ||
            option.contains('shopping') ||
            option.contains('cycling') ||
            option.contains('Leave') ||
            option.contains('Visit'));
      }
    }).toList();
  }

  String _getTimePeriod(int hour) {
    if (hour >= 6 && hour < 9) return '🌅 Morning';
    if (hour >= 9 && hour < 12) return '☀️ Mid-Morning';
    if (hour >= 12 && hour < 16) return '🌤️ Afternoon';
    if (hour >= 16 && hour < 20) return '🌆 Late Afternoon';
    return '🌙 Evening';
  }

  Color _getCardColor(int index) {
    final colors = [
      Colors.blueGrey.withOpacity(0.8),
      Colors.indigo.withOpacity(0.8),
      Colors.teal.withOpacity(0.8),
      Colors.purple.withOpacity(0.8),
      Colors.deepOrange.withOpacity(0.8),
      Colors.blue.withOpacity(0.8),
      Colors.green.withOpacity(0.8),
      Colors.pink.withOpacity(0.8),
    ];
    return colors[index % colors.length];
  }

  Widget _buildSuggestionCard(DailySuggestion suggestion, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getCardColor(index),
                _getCardColor(index).withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          suggestion.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTimePeriod(suggestion.startTime.hour),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${suggestion.startTime.hour}:00 - ${suggestion.endTime.hour}:00',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${suggestion.temperature?.toStringAsFixed(1) ?? '0'}°C',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Suggestion text
                Text(
                  suggestion.suggestion,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Options
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestion.options.map((option) {
                    return ActionChip(
                      label: Text(
                        option,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      onPressed: () {
                        _handleOptionSelected(option, suggestion);
                      },
                      avatar: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    );
                  }).toList(),
                ),
                
                // Weather conditions
                if (suggestion.weatherConditions != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          suggestion.weatherConditions!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleOptionSelected(String option, DailySuggestion suggestion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Selected: $option',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    
    // You can add additional logic here like:
    // - Save selection to database
    // - Add reminder
    // - Update UI
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuggestions = _getFilteredSuggestions();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueGrey.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Suggestions',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Ethnocentric',
                          ),
                        ),
                        Text(
                          widget.city,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _generateSuggestions();
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // Filters
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          _filters[index],
                          style: TextStyle(
                            color: _selectedFilter == index 
                                ? Colors.white 
                                : Colors.white70,
                          ),
                        ),
                        selected: _selectedFilter == index,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = index;
                          });
                        },
                        backgroundColor: Colors.white.withOpacity(0.1),
                        selectedColor: Colors.blue.withOpacity(0.8),
                        checkmarkColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              
              // Suggestions Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.yellow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${filteredSuggestions.length} suggestions available',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Today: ${DateTime.now().toString().split(' ')[0]}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Suggestions List
              Expanded(
                child: filteredSuggestions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              color: Colors.white54,
                              size: 80,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No suggestions available',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Try changing the filter',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSuggestions.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildSuggestionCard(
                              filteredSuggestions[index],
                              index,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}