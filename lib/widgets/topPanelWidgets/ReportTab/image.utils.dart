import 'package:image/image.dart' as img;

/// Converts Arabic text into an image.
img.Image generateArabicTextImage(String text) {
  // Create a blank white image
  final image = img.Image(width: 380, height: 100);
  img.fill(image, color: img.ColorRgb8(255, 255, 255)); // White background

  // Load built-in font
  final font = img.arial24; // Change to arial14 or arial48 if needed

  // Draw the Arabic text onto the image
  img.drawString(
      image,
      10 as String,
      font: font,); // Black text

  return image;
}
