import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/animations.dart';
import '../core/constants.dart';
import '../providers/network_provider.dart';

class MyNetworksScreen extends StatefulWidget {
  const MyNetworksScreen({super.key});

  @override
  _MyNetworksScreenState createState() => _MyNetworksScreenState();
}

class _MyNetworksScreenState extends State<MyNetworksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch connections and suggestions when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkProvider =
          Provider.of<NetworkProvider>(context, listen: false);
      networkProvider.fetchConnections();
      networkProvider.fetchSuggestions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'My Networks',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          tabs: [
            Tab(
              child: Text(
                'Connections',
                style: GoogleFonts.poppins(color: AppColors.white),
              ),
            ),
            Tab(
              child: Text(
                'Suggestions',
                style: GoogleFonts.poppins(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
      body: FadeInAnimation(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search connections...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConnectionsList(),
                  _buildSuggestionsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsList() {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        if (networkProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (networkProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading connections',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => networkProvider.fetchConnections(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final connections = networkProvider.connections;
        if (connections == null || connections.isEmpty) {
          return Center(
            child: Text(
              'No connections yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final connection = connections[index];
            return SlideInAnimation(
              delay: Duration(milliseconds: index * 100),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: connection['profilePicture'] != null
                        ? NetworkImage(connection['profilePicture'])
                        : null,
                    child: connection['profilePicture'] == null
                        ? Text(connection['username'][0].toUpperCase())
                        : null,
                  ),
                  title: Text(connection['username']),
                  subtitle: Text(
                    connection['headline'] ?? 'LinkSphere User',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      networkProvider.disconnect(connection['connectedUserId']);
                    },
                    child: const Text('Disconnect'),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        if (networkProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (networkProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading suggestions',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => networkProvider.fetchSuggestions(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final suggestions = networkProvider.suggestions;
        if (suggestions == null || suggestions.isEmpty) {
          return Center(
            child: Text(
              'No suggestions available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return SlideInAnimation(
              delay: Duration(milliseconds: index * 100),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: suggestion['profilePicture'] != null
                        ? NetworkImage(suggestion['profilePicture'])
                        : null,
                    child: suggestion['profilePicture'] == null
                        ? Text(suggestion['username'][0].toUpperCase())
                        : null,
                  ),
                  title: Text(suggestion['username']),
                  subtitle: Text(
                    suggestion['headline'] ?? 'LinkSphere User',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      networkProvider.connect(suggestion['connectedUserId']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Connect'),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
