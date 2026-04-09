import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/util/app_constants.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';

class NotificationScreen extends StatefulWidget {
  final Function(bool) onNotificationUpdate;

  const NotificationScreen({super.key, required this.onNotificationUpdate});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(AppConstants.notifications),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];
        setState(() {
          notifications = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        widget.onNotificationUpdate(notifications.isNotEmpty);
      }
    } catch (e) {
      debugPrint('Notification fetch error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String? _imageUrl(dynamic image) {
    if (image is String && image.isNotEmpty) return image;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchNotifications,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? const Center(child: Text('No notifications'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final imgUrl = _imageUrl(n['image']);
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imgUrl != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(10)),
                                child: CachedNetworkImage(
                                  imageUrl: imgUrl,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n['message'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    n['sent_at_human'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
