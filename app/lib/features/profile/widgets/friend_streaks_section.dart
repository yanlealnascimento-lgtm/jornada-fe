import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FriendStreak {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int streakDays;

  const FriendStreak({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.streakDays,
  });
}

class FriendStreaksSection extends StatelessWidget {
  final List<FriendStreak> friends;
  final VoidCallback onAddFriend;

  const FriendStreaksSection({
    super.key,
    required this.friends,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OFENSIVAS DOS AMIGOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ...friends.map((f) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _FriendStreakAvatar(friend: f),
                  )),
              ...List.generate(
                (5 - friends.length).clamp(0, 5),
                (_) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: onAddFriend,
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                              width: 2,
                            ),
                            color: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
                          ),
                          child: Icon(Icons.add_rounded,
                              color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFFD1D5DB),
                              size: 22),
                        ),
                        const SizedBox(height: 4),
                        Text('Adicionar',
                            style: TextStyle(fontSize: 9,
                              color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFFD1D5DB))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendStreakAvatar extends StatelessWidget {
  final FriendStreak friend;

  const _FriendStreakAvatar({required this.friend});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: friend.streakDays > 0
                      ? const Color(0xFFFF6B35)
                      : (isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB)),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: friend.avatarUrl != null
                    ? Image.network(friend.avatarUrl!, fit: BoxFit.cover,
                        width: 52, height: 52,
                        errorBuilder: (_, __, ___) => _initial(isDark))
                    : _initial(isDark),
              ),
            ),
            if (friend.streakDays > 0)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${friend.streakDays}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          friend.name.split(' ').first,
          style: TextStyle(fontSize: 10,
            color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _initial(bool isDark) {
    return ColoredBox(
      color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEBF5FF),
      child: Center(
        child: Text(
          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A90E2),
          ),
        ),
      ),
    );
  }
}
