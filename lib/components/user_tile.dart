import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String? latestMessage;
  final String? profilePictureUrl;
  final void Function()? onTap;

  const UserTile({
    super.key,
    required this.text,
    this.latestMessage,
    this.profilePictureUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(30),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 25),
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: profilePictureUrl != null && profilePictureUrl!.startsWith('http')
                    ? Image.network(
                        profilePictureUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Log error if image fails to load
                          print("Error loading image: $error");
                          return Image.asset(
                            'assets/images/defaultpic.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        profilePictureUrl ?? 'assets/images/defaultpic.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // User details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User name
                  Text(
                    text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  // Latest message
                  Text(
                    latestMessage ?? 'Start a conversation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
