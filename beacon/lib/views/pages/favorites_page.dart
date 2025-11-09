import 'package:beacon/views/mobile/auth_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = authService.value.currentuser;
    if (user == null) {
      return const Center(child: Text('Sign in to view favorites'));
    }

    // Listen to favorites for the current user
    final favsStream = FirebaseDatabase.instance
        .ref('userFavorites/${user.uid}')
        .onValue;

    return StreamBuilder<DatabaseEvent>(
      stream: favsStream,
      builder: (context, favSnap) {
        if (favSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        final favMap = favSnap.data?.snapshot.value as Map?;
        if (favMap == null || favMap.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 80),
              Icon(Icons.star_border, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Center(
                child: Text('No favorites yet'),
              ),
            ],
          );
        }
        final favoriteIds = favMap.keys.map((k) => k.toString()).toSet();

        // Stream all beacons, filter to favorites
        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('beacons').onValue,
          builder: (context, beaconSnap) {
            if (beaconSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            final data = beaconSnap.data?.snapshot.value as Map?;
            if (data == null) {
              return const Center(child: Text('No beacons available'));
            }
            final items = data.entries
                .where((e) => favoriteIds.contains(e.key.toString()))
                .map((e) {
              final m = Map<String, dynamic>.from(e.value as Map);
              m['id'] = e.key.toString();
              return m;
            }).toList();

            if (items.isEmpty) {
              return const Center(child: Text('No current beacons in favorites'));
            }

            items.sort((a, b) {
              final at = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bt = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bt.compareTo(at);
            });

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final b = items[i];
                final name = (b['name'] ?? 'Untitled').toString();
                final category = (b['category'] ?? 'Uncategorized').toString();
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.wifi_rounded),
                    title: Text(name),
                    subtitle: Text(category),
                    trailing: const Icon(Icons.star, color: Colors.amber),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
