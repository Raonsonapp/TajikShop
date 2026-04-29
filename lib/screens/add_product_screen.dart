import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ImagePicker picker = ImagePicker();
  List<File> images = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  String category = "Категория";
  String condition = "Нав";

  // 📸 pick from gallery
  Future pickFromGallery() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        images.add(File(picked.path));
      });
    }
  }

  // 📷 pick from camera
  Future pickFromCamera() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        images.add(File(picked.path));
      });
    }
  }

  // 📦 choose source
  void showPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("Камера"),
            onTap: () {
              Navigator.pop(context);
              pickFromCamera();
            },
          ),
          ListTile(
            title: const Text("Галерея"),
            onTap: () {
              Navigator.pop(context);
              pickFromGallery();
            },
          ),
        ],
      ),
    );
  }

  // 📤 submit (ҳоло танҳо print)
  void submit() {
    print(titleController.text);
    print(priceController.text);
    print(descController.text);
    print(images.length);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Эълон нашр шуд ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),

      appBar: AppBar(
        title: const Text("Эълон додан"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text("Черновик", style: TextStyle(color: Colors.green)),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("1. Расмҳо"),
            const SizedBox(height: 8),

            // 📸 Upload box
            GestureDetector(
              onTap: showPicker,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text("Расм илова кунед"),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 🖼 Preview images
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              images.removeAt(index);
                            });
                          },
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 🧾 Title
            const Text("Номи маҳсулот"),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "Номро ворид кунед",
              ),
            ),

            const SizedBox(height: 10),

            // 💰 Price
            const Text("Нарх"),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Масалан: 350",
              ),
            ),

            const SizedBox(height: 10),

            // 📝 Description
            const Text("Тавсиф"),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Тавсифи кӯтоҳ...",
              ),
            ),

            const SizedBox(height: 20),

            // 🔘 Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(14),
                ),
                child: const Text("Нашр кардан"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
