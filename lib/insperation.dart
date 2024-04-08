import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_screen.dart';
import 'package:share/share.dart'; 
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class PortfolioPage extends StatelessWidget {
  final List<Map<String, dynamic>> images = [
    // Add your images and associated text here
    {'image': 'assets/1.png', 'text': 'redshift style Routermaster, Dripping & Splashing Watercolor, Flowerly, passion, intricate details pretty blonde girl, masterpiece, artwork by Carne Griffiths & Marc Allante, long shot view, HD'},
    {'image': 'assets/2.png', 'text': 'Cyberpunk style, a cat standing on a skateboard, wearing a backwards baseball cap and holding a boombox on its shoulder, confident expression, vibrant colors, graffiti-style background, edgy atmosphere, playful mood, intricate details, high-quality artwork masterful composition, wide-angle 8K resolution, Octane render, Ray-tracing, HDR10, portrait, cyberpunk mandalorian, futuristic, highly detailed, made with blender, 80s retro style drawning featuring synthetic wave against minimalist sunset with outline and dark background'},
    {'image': 'assets/3.png', 'text': 'Disorderly Chaos, (Barbaric Growth of Weird Magical Flowers), Artwork by Dale Chihuly'},
    {'image': 'assets/4.png', 'text': 'Hummingbird by Alex Grey, Lisa Frank, Frank Miller, Gustave Dore, Simon Stalenhag, professional, photo, bioluminescent, cinematic, HDR, Omnipresent, cosmic, infinite, ethereal, powerful, hyperrealism, Rough Neon, mystical'},
    {'image': 'assets/5.png', 'text': 'Tree of life growing in the forest with an owl graffiti art, splash art, street art, spray paint, oil gouache melting, acrylic, high contrast, colorful polychromatic, ultra detailed, ultra quality, CGSociety'},
    {'image': 'assets/6.png', 'text': 'high detailed professional upper body photo of a transparent porcelain android looking at viewer, with glowing backlit panels, anatomical plants, dark forest, night, darkness, grainy, shiny, intricate plant details, with vibrant colors, colorful plumage, bold colors, flora, contrasting shadows , realistic, photographic'},
    {'image': 'assets/7.png', 'text': 'Cityscape, night, hard light, rain, nostalgic, low fi, woman 1950 style,'},
    {'image': 'assets/8.png', 'text': 'Documentary-style photography of a bustling marketplace in Marrakech, with spices and textiles'},
  ];

  @override
  Widget build(BuildContext context) {
    return MainScreen(
      body: Scaffold(
        appBar: AppBar(
          title: const Text('Get Inspired'),
        ),
        body: GridView.builder(
  itemCount: images.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2, // Adjust number of images per row
    crossAxisSpacing: 10, // Add horizontal spacing
    mainAxisSpacing: 10, // Add vertical spacing
  ),
  itemBuilder: (context, index) {
    return Padding(
      padding: const EdgeInsets.all(8.0), // Add padding around each image
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10), // Add rounded corners
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
                opacity: animation,
                child: ImageDetailPage(image: images[index]),
              ),
              transitionDuration: const Duration(milliseconds: 500), // Adjust transition duration
            ),
          ),
          child: Image.asset(images[index]['image']),
        ),
      ),
    );
  },
),
      ),
    );
  }
}

class ImageDetailPage extends StatelessWidget {
  final Map<String, dynamic> image;

  const ImageDetailPage({super.key, required this.image});

  Future<void> shareImage() async {
    try {
      final ByteData bytes = await rootBundle.load(image['image']);
      final Directory tempDir = await getTemporaryDirectory();
      final File file = await File('${tempDir.path}/${image['image'].split("/").last}').writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));

      Share.shareFiles([file.path], text: 'Check out this prompt from PixelCraft: ${image['text']}');
    } catch (e) {
      if (kDebugMode) {
        print('error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Detail'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0), // Add 8 pixels of padding on all sides
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0), // Add rounded corners with a radius of 8 pixels
                child: Image.asset(image['image']),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0), // Add 16 pixels of padding on all sides
              child: Container(
                padding: const EdgeInsets.all(16.0), // Add 16 pixels of padding on all sides
                decoration: BoxDecoration(
                  color: Colors.grey, // Set the background color to grey
                  borderRadius: BorderRadius.circular(8.0), // Add rounded corners with a radius of 8 pixels
                  border: Border.all(color: Colors.black, width: 1.0), // Add a black border with a width of 1 pixel
                ),
                child: Text(
                  image['text'],
                  style: const TextStyle(color: Colors.white), // Set the text color to white
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: image['text']));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: const Text('Copy Prompt'),
            ),
            ElevatedButton(
              onPressed: shareImage,
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }
}