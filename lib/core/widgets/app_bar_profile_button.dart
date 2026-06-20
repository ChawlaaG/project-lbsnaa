
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/user_provider.dart';
import '../../features/profile/screens/profile_screen.dart';

class AppBarProfileButton extends ConsumerWidget {
  const AppBarProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.amber,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade800,
            foregroundImage: user.avatarUrl != null 
                ? NetworkImage(user.avatarUrl!) 
                : const NetworkImage('https://api.dicebear.com/9.x/bottts/png?seed=Cadet&backgroundColor=1E293B'),
            onForegroundImageError: (_, __) {},
            child: const Icon(Icons.person, size: 20, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
