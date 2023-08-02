import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellProduct extends StatefulWidget {
  const SellProduct({Key? key}) : super(key: key);

  @override
  State<SellProduct> createState() => _SellProductState();
}

class _SellProductState extends State<SellProduct> {
  GlobalKey<FormState> key = GlobalKey();
  CollectionReference _reference = FirebaseFirestore.instance.collection('marketplace');
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _itemDescriptionController = TextEditingController();
  TextEditingController _itemPriceController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser!;
  XFile? _selectedImage; // Temporary variable to hold the selected image
  String imageUrl = ''; // Firebase Storage URL of the uploaded image

  // Add the list of categories
  List<String> categories = ['Trading Cards', 'Tickets', 'Plants', 'Other'];
  String? selectedCategory; // Variable to hold the selected category

  bool _isSubmitting = false; // Flag to indicate whether product is being submitted or not

  void _pickImageFromGallery() async {
    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = pickedImage;
    });
  }

  void _submitProduct() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload an image')));
      return;
    }

    if (!key.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter all fields')));
      return;
    }

    if (selectedCategory == null || selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a category')));
      return;
    }

    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirImages = referenceRoot.child('images');
    Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

    try {
      setState(() {
        _isSubmitting = true; // Set the flag to true when submitting
      });

      await referenceImageToUpload.putFile(File(_selectedImage!.path));
      imageUrl = await referenceImageToUpload.getDownloadURL();

      String itemName = _itemNameController.text;
      String itemDescription = _itemDescriptionController.text;
      double priceAsDouble = double.parse(_itemPriceController.text);
      String formattedPrice = priceAsDouble.toStringAsFixed(2);
      String sellerName = user.displayName.toString();
      String sellerEmail = user.email.toString(); // Get the user's email address
      Timestamp timestamps = Timestamp.now();
      String uid = user.uid;

      Map<String, dynamic> dataToSend = {
        'name': itemName,
        'description': itemDescription,
        'price': formattedPrice, // Store the formatted price
        'image': imageUrl,
        'seller': sellerName,
        'sellerEmail': sellerEmail, // Add the user's email address to the data
        'timestamp': timestamps, // Add the timestamp to the data
        'category': selectedCategory, // Add the selected category to the data
        'uid': uid,
      };
      await _reference.add(dataToSend);

      // Clear the input fields after successful submission
      _itemNameController.clear();
      _itemDescriptionController.clear();
      _itemPriceController.clear();
      setState(() {
        _selectedImage = null;
        selectedCategory = null; // Reset the selected category
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green, // Customize the background color
          behavior: SnackBarBehavior.floating, // Make it look more modern with floating behavior
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Rounded corners
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white), // Success icon
              SizedBox(width: 8),
              Text(
                'Product submitted successfully!',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          duration: Duration(seconds: 3), // Set the duration for how long the pop-up should be visible
        ),
      );
    } catch (error) {
      // Handle error
      print('Error uploading image: $error');
    }
    finally {
      setState(() {
        _isSubmitting = false; // Set the flag back to false when submission is complete
      });
    }
  }

  String? validatePrice(String value) {
    // Check if the price has one decimal place and add a 0 to the end
    if (value.split('.').length == 2 && value.split('.')[1].length == 1) {
      value += '0';
    }
    // Check if the price does not have any decimal points and add '.00' to the end
    if (value.split('.').length == 1) {
      value += '.00';
    }

    try {
      double price = double.parse(value);
      if (price < 0) {
        return 'Price must be greater than or equal to 0';
      }
      if (value.split('.').length != 2 || value.split('.')[1].length != 2) {
        return 'Price must have two decimal places';
      }
    } catch (e) {
      return 'Please enter a valid price';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sell Product"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _itemNameController,
                  decoration: InputDecoration(labelText: 'Item Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the item name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _itemDescriptionController,
                  decoration: InputDecoration(labelText: 'Item Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the item description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _itemPriceController,
                  decoration: InputDecoration(
                    labelText: 'Item Price',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the item price';
                    }
                    return validatePrice(value); // Validate price using the custom function
                  },
                ),
                SizedBox(height: 16),

                // Add the dropdown field for selecting the category
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  onChanged: (newValue) {
                    setState(() {
                      selectedCategory = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),
                _selectedImage == null
                    ? ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: Icon(Icons.camera),
                        label: Text('Add Image'),
                      )
                    : Container(
                        width: 300,
                        height: 300,
                        child: Stack(
                          children: [
                            Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: ElevatedButton(
                                onPressed: _pickImageFromGallery,
                                child: Icon(Icons.camera),
                              ),
                            ),
                          ],
                        ),
                      ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProduct, // Disable the button while submitting
                  child: _isSubmitting
                      ? CircularProgressIndicator() // Show the circular loading indicator while submitting
                      : Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
