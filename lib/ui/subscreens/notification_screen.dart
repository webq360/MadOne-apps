import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:omnicare_app/Model/notification_model.dart';
import 'package:omnicare_app/ui/screens/shimmer_widget.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:http/http.dart' as http;

class NotificationScreen extends StatefulWidget {
  final Function(bool) onNotificationUpdate;

   const NotificationScreen({Key? key, required this.onNotificationUpdate});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<NotificationModel> notifications = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }
  Future<void> fetchNotifications() async {
    final url = Uri.parse('https://app.omnicare.com.bd/api/settings');
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> siteSettings = jsonData['site_settigs'];
        if (siteSettings.isNotEmpty) {
          notifications.clear(); // Clear previous notifications
          final notificationMap = siteSettings[0];
          final List<String?> notificationTexts = [
            notificationMap['notification_text_1'],
            notificationMap['notification_text_2'],
            notificationMap['notification_text_3'],
            notificationMap['notification_text_4'],
            notificationMap['notification_text_5'],
          ];
          notifications.addAll(notificationTexts
              .where((text) => text != null)
              .map((text) => NotificationModel(text!, false)));
          widget.onNotificationUpdate(true); // Mark as unread initially
        } else {
          notifications = []; // No notifications available
        }
      } else {
        notifications = []; // Failed to fetch notifications
      }
    } catch (error) {
      notifications = []; // Error fetching notifications
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchNotifications();
        },
        child: SingleChildScrollView(
          child: isLoading
              ? const ShimmerWidget()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: notifications
                .map((notification) => Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blue[50],
              ),
              child: Text(
                notification.text, // Accessing the text property of NotificationModel
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ))
                .toList(),
          ),
          ),
        ),
    );
  }
}