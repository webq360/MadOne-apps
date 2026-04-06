// ignore_for_file: use_build_context_synchronously, avoid_print, unused_local_variable, prefer_conditional_assignment

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omnicare_app/ui/network_checker_screen/network_checker_screen.dart';
import 'package:omnicare_app/ui/screens/account_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _image;
  TextEditingController pharmacyNameController = TextEditingController();
  TextEditingController ownerNameController = TextEditingController();
  TextEditingController drugLicenseController = TextEditingController();
  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController zoneController = TextEditingController();
  TextEditingController shippingAddressController = TextEditingController();
  List<Zone> zones = [];
  Zone? selectedZone;
  String? selectedZoneName;
  String storeName = '';
  String emailAddress = ''; // Added email address
  String pharmacyName = '';
  bool isLoading = false;
  // Declare a variable to store the fetched data
  Map<String, dynamic>? fetchedData; // Added pharmacy name
  Future<void> _pickImageFromGallery() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

// Replace the _captureImage method with the following
  Future<void> _captureImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch user profile information
    fetchUserProfile();
    _checkNetworkAndLoggedIn();
    // Fetch available zones
    fetchZones().then((fetchedZones) {
      setState(() {
        zones = fetchedZones;
      });
    });
  }

  Future<void> fetchUserProfile() async {
    if (!mounted) return;
    try {
      await fetchStoreName();
      await fetchAdditionalUserProfile();
      if (!mounted) return;

      setState(() {
        pharmacyNameController.text = pharmacyName;
        ownerNameController.text = fetchedData?['pharmacy']['owner_name'] ?? '';
        drugLicenseController.text =
            fetchedData?['pharmacy']['drag_license'] ?? '';
        mobileNumberController.text = fetchedData?['pharmacy']['mobile'] ?? '';
        if (fetchedData?['pharmacy']['zone'] != null) {
          selectedZone = Zone.fromJson(fetchedData?['pharmacy']['zone']);
          selectedZoneName = selectedZone?.zoneName;
          zoneController.text = selectedZoneName ?? '';
        }
        shippingAddressController.text =
            fetchedData?['pharmacy']['store_address'] ?? '';
        if (fetchedData?['pharmacy']['store_image'] != null) {
          String storeImageUrl = fetchedData?['pharmacy']['store_image'];
          _setImageFromUrl(storeImageUrl);
        }
      });
    } catch (error) {
      print('Error during additional user profile fetch: $error');
    }
  }

  Future<void> _setImageFromUrl(String imageUrl) async {
    if (imageUrl.startsWith('http')) {
      // If the image URL is a remote URL, download and set the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Directory appDirectory = await getApplicationDocumentsDirectory();
        final String localImagePath = '${appDirectory.path}/store_image.jpg';
        final File localImage = File(localImagePath);
        await localImage.writeAsBytes(response.bodyBytes);
        setState(() {
          _image = localImage;
        });
      } else {
        print('Failed to download store image: ${response.statusCode}');
      }
    } else {
      // If the image URL is a local file path, set the image directly
      setState(() {
        _image = File(imageUrl);
      });
    }
  }

  // Fetch additional user profile information (pharmacy name, email address, etc.)
  Future<void> fetchAdditionalUserProfile() async {
    try {
      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        print('Authorization token is missing.');
        return;
      }
      final response = await http.get(
        Uri.parse('https://stage.medone.primeharvestbd.com/api/profile'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      print(
          'Fetch Additional User Profile status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        fetchedData = json.decode(response.body);
        print('Fetched Additional User Profile: $fetchedData');
        setState(() {
          emailAddress = fetchedData?['user']['email'] ?? '';
          pharmacyName = fetchedData?['pharmacy']['store_name'] ?? '';
        });
      } else if (response.statusCode == 401) {
        await _handleTokenRefresh(fetchAdditionalUserProfile);
      } else {
        print(
            'Failed to fetch additional user profile. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error during additional user profile fetch: $error');
    }
  }

  Future<void> fetchStoreName() async {
    try {
      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        // Handle the case where the authorization token is not available
        print('Authorization token is missing.');
        return;
      }
      final response = await http.get(
        Uri.parse('https://stage.medone.primeharvestbd.com/api/profile'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      print('Fetch Store Name status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> fetchedData = json.decode(response.body);
        print('Fetched Store Name: ${fetchedData['pharmacy']['store_name']}');
        setState(() {
          storeName = fetchedData['pharmacy']['store_name'] ?? '';
        });
      } else if (response.statusCode == 401) {
        // Token expired, attempt token refresh
        await _handleTokenRefresh(fetchStoreName);
      } else {
        // Handle API error
        print(
            'Failed to fetch store name. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network errors or unexpected situations
      print('Error during store name fetch: $error');
    }
  }

  // Function to handle token refresh
  Future<void> _handleTokenRefresh(Function onRefreshComplete) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? refreshToken = prefs.getString('refreshToken');
    if (refreshToken != null) {
      final String? newAccessToken = await _refreshToken(refreshToken);
      if (newAccessToken != null) {
        // Save the new access token
        prefs.setString('accessToken', newAccessToken);
        // Retry the original function after token refresh
        await onRefreshComplete();
      } else {
        // If refresh token is not available or refresh fails, show an error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Function to get the current access token
  Future<String?> _getAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  // Function to refresh the access token
  Future<String?> _refreshToken(String refreshToken) async {
    const String apiUrl = 'https://stage.medone.primeharvestbd.com/api/refresh';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'refresh_token': refreshToken,
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> authorization =
            responseData['authorization'];
        return authorization['token'];
      } else {
        return null;
      }
    } catch (error) {
      print('Error during token refresh: $error');
      return null;
    }
  }

  Future<List<Zone>> fetchZones() async {
    final response = await http
        .get(Uri.parse('https://stage.medone.primeharvestbd.com/api/zones'));
    if (response.statusCode == 200) {
      Iterable data = json.decode(response.body)['zones'];
      // Use a set to ensure unique zones based on their ID
      Set<int> uniqueZoneIds = Set();
      List<Zone> uniqueZones = [];
      for (var model in data) {
        Zone zone = Zone.fromJson(model);
        // Check if the zone ID is not already in the set
        if (uniqueZoneIds.add(zone.id)) {
          uniqueZones.add(zone);
        }
      }
      return uniqueZones;
    } else {
      throw Exception('Failed to load zones');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final String? authToken = await _getAccessToken();

        if (authToken == null) {
          print('Authorization token is missing.');
          return;
        }

        // Pharmacy ID (assuming it's available in fetchedData)
        int pharmacyId = fetchedData?['pharmacy']['id'] ?? 0;
        // Find the selected zone and get its ID
        int? selectedZoneId;
        if (selectedZone != null) {
          selectedZoneId = selectedZone!.id;
        }
        // Check if store_name and zone_id are present
        if (pharmacyNameController.text.isEmpty || selectedZoneId == null) {
          print('Store name and zone are required.');
          return;
        }
        // API endpoint for updating pharmacy information
        final String apiUrl =
            'https://stage.medone.primeharvestbd.com/api/pharmacy/update/$pharmacyId';
        // Construct the request headers with the authorization token
        Map<String, String> headers = {
          'Authorization': 'Bearer $authToken',
        };

        // Construct the request body as multipart
        var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
          ..headers.addAll(headers)
          ..fields['store_name'] = pharmacyNameController.text
          ..fields['zone_id'] = selectedZoneId.toString()
          ..fields['owner_name'] = ownerNameController.text
          ..fields['drag_license'] = drugLicenseController.text
          ..fields['mobile'] = mobileNumberController.text
          ..fields['store_address'] = shippingAddressController.text;

        // Add image file if available
        if (_image != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'store_image',
            _image!.path,
            contentType: MediaType('image', '*'),
          ));
        }

        // Show the circular progress indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AbsorbPointer(
              absorbing: true,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        );

        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        Navigator.pop(context);
        print(
            'Update Pharmacy Information status code: ${response.statusCode}');
        if (response.statusCode == 200) {
          print('Pharmacy information updated successfully.');
          // Call fetchUserProfile to update the displayed information
          await fetchUserProfile();
          // Update the pharmacyName variable with the latest value
          setState(() {
            pharmacyName = pharmacyNameController.text;
            // Reset the image variable if no image is uploaded
            if (_image == null) {
              _image = null;
            }
          });
        } else if (response.statusCode == 401) {
          await _handleTokenRefresh(() => _submitForm());
        } else {
          print(
              'Failed to update pharmacy information. Status code: ${response.statusCode}');
        }
      } catch (error) {
        print('Error during pharmacy information update: $error');
      }
    }
  }

  Future<void> _checkNetworkAndLoggedIn() async {
    bool hasNetwork = await checkNetwork();
    bool userLoggedIn = await isLoggedIn();
    if (hasNetwork && userLoggedIn) {
      // Fetch user profile information only if the user is logged in and network is available
      fetchUserProfile();
      fetchZones().then((fetchedZones) {
        setState(() {
          zones = fetchedZones;
        });
      });
    } else {
      Get.to(() => const NetworkCheckScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ColorPalette.primaryColor,
          leading: IconButton(
            onPressed: () {
              Get.offAll(const AccountScreen());
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await fetchStoreName();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xffB7D4FF),
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30.r,
                            child: _image == null
                                ? (fetchedData?['pharmacy']['store_image'] !=
                                        null
                                    ? Image.network(
                                        fetchedData?['pharmacy']['store_image'],
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.image,
                                        size: 40, color: Colors.white))
                                : CircleAvatar(
                                    backgroundImage: FileImage(_image!),
                                    radius: 30.r,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 0,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      ListTile(
                                        leading:
                                            const Icon(Icons.photo_library),
                                        title:
                                            const Text('Choose from Gallery'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImageFromGallery();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text('Take a Picture'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _captureImage();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Icon(
                              Icons.edit,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Text('$storeName'),
                    Text(
                      '$emailAddress',
                      style: const TextStyle(color: Colors.green),
                    ),
                    SizedBox(
                      height: 15.h,
                    ),
                    TextFormField(
                      controller: pharmacyNameController..text = pharmacyName,
                      decoration: const InputDecoration(
                        labelText: 'Pharmacy Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Pharmacy Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15.h),
                    TextFormField(
                      controller: ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    TextFormField(
                      controller: drugLicenseController,
                      decoration: const InputDecoration(
                        labelText: 'Drug License',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    TextFormField(
                      controller: mobileNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Mobile Number cannot be empty';
                        } else if (value.length != 11) {
                          return 'Mobile Number should be 11 digits';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 15.h),
                    DropdownButtonFormField<String>(
                      value: selectedZoneName,
                      items: zones.map((Zone zone) {
                        return DropdownMenuItem<String>(
                          value: zone.zoneName,
                          child: Text(zone.zoneName),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedZoneName = value;
                          selectedZone = zones
                              .firstWhere((zone) => zone.zoneName == value);
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Zone',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Zone cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15.h),
                    TextFormField(
                      controller: shippingAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Shipping Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Container(
                      width: 100.0,
                      height: 40.0,
                      child: MaterialButton(
                        onPressed: () {
                          // Handle the submit button press
                          if (_formKey.currentState!.validate()) {
                            _submitForm();
                          }
                        },
                        color: ColorPalette.primaryColor,
                        child: const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Zone {
  final int id;
  final String zoneName;
  final String zoneZipCode;
  Zone({required this.id, required this.zoneName, required this.zoneZipCode});
  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as int,
      zoneName: json['zone_name'] as String,
      zoneZipCode: json['zone_zip_code'] as String,
    );
  }
}
