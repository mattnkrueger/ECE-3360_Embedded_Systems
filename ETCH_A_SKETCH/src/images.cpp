#include "images.h"

// Current image index
int currentImageIndex = 0;

// Map character to RGB565 color
uint16_t getColorForChar(char c, MatrixPanel_I2S_DMA* display) {
  switch (c) {
    case 'g': return display->color565(0, 255, 0);     // green
    case 'y': return display->color565(255, 255, 0);   // yellow
    case 'w': return display->color565(255, 255, 255); // white
    case 'b': return display->color565(0, 0, 0);       // black
    case 'r': return display->color565(255, 0, 0);     // red
    case 'l': return display->color565(0, 0, 255);     // blue
    case 'o': return display->color565(255, 165, 0);   // orange
    case 'p': return display->color565(128, 0, 128);   // purple
    case 'G': return display->color565(128,128,128);   //Gray
    case 'B': return display->color565(0, 0, 255);     //Blue
    default:  return display->color565(0, 0, 0);       // default to black
  }
}

// Define a struct to hold image data
struct ImageData {
  const char** rows;
  int rowCount;
  const char* name;
};

// Packers logo data - defined here first
const char* packers_logo[] = {
  "bbbbbbbbyyyyyyyyyyyyybbbbbbb",     //line 1
  "bbbbbbyygggggggggggggyybbbbb",     //line 2
  "bbbbyygggwwwwwwwwwwwgggyybbb",     //line 3
  "bbbygggwwwwwwwwwwwwwwwgggybb",     //line 4
  "bbyggwwwwwwwwwwwwwwwwwwwggyb",     //line 5
  "byggwwwwwwgggggggwwwwwwwwggy",     //line 6
  "yggwwwwwwggggggggggwwwwwwwgy",     //line 7
  "ygwwwwwwgggggggggggggggggggy",     //line 8
  "ygwwwwwwgggggggggggggggggggy",     //line 9
  "ygwwwwwwgggggggggggggggggggy",     //line 10
  "ygwwwwwwgggwwwwwwwwwwwwwwwgy",     //line 11
  "ygwwwwwwggggwwwwwwwwwwwwwwgy",     //line 12
  "bygwwwwwwwggggggggwwwwwwwggy",     //line 13
  "byggwwwwwwwwwwwwwwwwwwwwggyb",     //line 14
  "bbyggwwwwwwwwwwwwwwwwwwggybb",     //line 15
  "bbbygggwwwwwwwwwwwwwwgggybbb",     //line 16
  "bbbbyyggggwwwwwwwwggggyybbbb",     //line 17
  "bbbbbbyyyggggggggggyyybbbbbb",     //line 18
  "bbbbbbbbbyyyyyyyyyybbbbbbbbb"      //line 19
};

// Custom logo data - defined here first
const char* Iowa_logo[] = {
  "bbbbbbbbbbbbbbbbbbbb", // line 1
  "bbbbbbbbbbbbbbbbbbbb", // line 2
  "bbbbbbbbbbbbbbbbbbbb", // line 3
  "bbbbbbbbbbbbbbbbbbbb", // line 4
  "bbbbbyyyyyyyyybbbbbb", // line 5
  "bbbyyyyyyyyyyyyybbbb", // line 6
  "bbyyyyyyyyyyyyyybbbb", // line 7
  "byyyyyyyybyyybyybbbb", // line 8
  "byyyyyybbbyyybbbbybb", // line 9
  "bbyyyybyybbbbbbbyyyb", // line 10
  "byyyyybyyyyyybbyyyyb", // line 11
  "bbyyybbbyyyyybyyyyyb", // line 12
  "byyybbbyyyyybbbbbyyb", // line 13
  "bbybbbyyyyyybbybbbyb", // line 14
  "bbbbbbyyyyybbbyybbbb", // line 15
  "bbbbbbbyybbbbbbbbbbb", // line 16
  "bbbbbbbbbbbbbbbbbbbb", // line 17
  "bbbbbbbbbbbbbbbbbbbb", // line 18
  "bbbbbbbbbbbbbbbbbbbb", // line 19
  "bbbbbbbbbbbbbbbbbbbb"  // line 20
};

// Heart pattern data - defined here first
const char* charmander[] = {
"wwwwwwwwwwwwwwwwwwwwwww",  // line 1
"wwwwwbbbbwwwwwwwwwbwwww",  // line 2
"wwwwboooobwwwwwwwbrbwww",  // line 3
"wwwboooooobwwwwwwbrrbww",  // line 4
"wwwboooooobwwwwwwbrrbww",  // line 5
"wwbooowbooobwwwwbrrorbw",  // line 6
"wboooobbooobwwwwbroyrbw",  // line 7
"wboooobboooobwwwbryyrbw",  // line 8
"wboooooooooobwwwwbybbww",  // line 9
"wwboooooooooobwwwbobwww",  // line 10
"wwwbbooooooooobwboobwww",  // line 11
"wwwwwbbboobooobboobwwww",  // line 12
"wwwwwwbyyboooooboobwwww",  // line 13
"wwwwwwbyyybbooobobwwwww",  // line 14
"wwwwwbwbyyyoooobbwwwwww",  // line 15
"wwwwwwbbbyyooobbwwwwwww",  // line 16
"wwwwwwwwwbbbobbwwwwwwww",  // line 17
"wwwwwwwwwwbwowbwwwwwwww",  // line 18
"wwwwwwwwwwwbbbwwwwwwwww",  // line 19
"wwwwwwwwwwwwwwwwwwwwwww"  // line 20
};

const char* r2d2[] = {
"wwwwwwwwwwwwwwwwwwwwwwwww",
"wwwwwwwwwwbbbbwwwwwwwwwww",
"wwwwwwwwbbGBBGbbwwwwwwwww",
"wwwwwwwbBGBwbBGBbwwwwwwww",
"wwwwwwbBGGBbbBGGBbwwwwwww",
"wwwwwwbGGGBBBBGGGbwwwwwww",
"wwwwwbGBBGGGGGGGGGbwwwwww",
"wwwwwbGGGGBGBBBGbGbwwwwww",
"wwwwwbGBBGBGBrBGbGbwwwwww",
"wwwwwbbbbbbbbbbbbbbwwwwww",
"wwbbbbwwwwwwwwwwwwbbbwwww",
"wwbwwbGGGwBBBBwGGGbwwbwww",
"wwbwwbGwGwwwwwwGwGbwwbwww",
"wwbwwbGwGwBBBBwGwGbwwbwww",
"wwbbbbGwGwwwwwwGwGbbbbwww",
"wwwbwbGwGwBGGBwGwGbwbwwww",
"wwwbwbGwGwBGGBwGwGbwbwwww",
"wwwbwbGwGwwwwwwGwGbwbwwww",
"wwwbwbGGGwBBBBwGGGbwbwwww",
"wwwbwbwwGwBGbBwGwwbwbwwww",
"wwwbbbwwGwBbGBwGwwbbbwwww",
"wwbwGbwwGwBBBBwGwwbGwbwww",
"wwbwGbbbbbbbbbbbbbbGwbwww",
"wbwwwbwwwbwGGwbwwwbwwwbww",
"wbwwwbwwbwGwwGwbwwbwwwbww",
"wbbbbbwwbbbbbbbbwwbbbbbww",
"wwwwwwwwwwwwwwwwwwwwwwwww",
};

const char* lebron[] = {
  "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
    "wwwwwwwwwwwwwwwwwwwwbbbwwwwwwwwwwwwwwwwwwwww",
    "wwwwwwwwwwwwwwwbbwwbbbbbwwwbbwwwwwwwwwwwwwww",
    "wwwwwbbbbbbwwwwbbbbbbbbbbbbbbwwwwbbbbbbwwwww",
    "wwwwwbbbbbbwwwwbbbbbbbbbbbbbbwwwwbbbbbbwwwww",
    "wwwwwbbbbbbwwwwwwwwwwwwwwwwwwwwwwbbbbbbwwwww",
    "wwwwwbbbbbbwwwwbbbbbbwbbbbbbbwwwwbbbbbbwwwww",
    "wwwwwbbbbbbbwwbbbbbbbwbbbbbbbbwwbbbbbbbwwwww",
    "wwwwwbbbbbbbbbbbbbbbbwbbbbbbbbbbbbbbbbbwwwww",
    "wwwwwbbbbbbbbbbbbbbbbwbbbbbbbbbbbbbbbbbwwwww",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
    "wwwwbwwwwwbbbbbwbbbbbwwbbbbbwbbbbbwbbbbbwwww",
    "wwwwbwwwwwbwwwbwbwwwbwwbwwwbwbwwwbwwwbwwwwww",
    "wwwwbwwwwwbwwwwwbwwwwwwbwwwbwbwwwbwwwbwwwwww",
    "wwwwbwwwwwbbbbwwbwwbbbwbwwwbwbbbbbwwwbwwwwww",
    "wwwwbwwwwwbwwwwwbwwwbwwbwwwbwbwwwbwwwbwwwwww",
    "wwwwbwwwwwbwwwbwbwwwbwwbwwwbwbwwwbwwwbwwwwww",
    "wwwwbbbbbwbbbbbwbbbbbwwbbbbbwbwwwbwwwbwwwwww",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww"
};

const char* beer[] = {
    "wwwwwwwwwwwwwwwwwwwwwww",
    "wwwwwbbbbbbbwbwwwwwwwww",
    "wwwwbwwGwwwwbwbwwwwwwww",
    "wwwbwwwwwwGwwwbwwwwwwww",
    "wwwbwGwwGwwbbwwbbwwwwww",
    "wwwbwwwbbbbyybbwwbwwwww",
    "wwwbGwbyyyyyybGGGwbwwww",
    "wwwwbbyoyyyyybGbGwbwwww",
    "wwwwbyooyyyyybbwbwbwwww",
    "wwwwbyyyyyyyobwwbwbwwww",
    "wwwwbyyyyyyyobwwbwbwwww",
    "wwwwbyyyyyyoobbwbwbwwww",
    "wwwwbyyyyyyoobwbGwbwwww",
    "wwwwbyyyyyyyobwGGbwwwww",
    "wwwwboyyyyyyybGGbwwwwww",
    "wwwwboyyyyyyybbbwwwwwww",
    "wwwbwboyyyyyybwwwwwwwww",
    "wwwbwGbbbbbbbGbwwwwwwww",
    "wwwwbwGGwwwwGwbwwwwwwww",
    "wwwwwwbbwwwwwbbwwwwwwww",
    "wwwwwwwbbbbbwwwwwwwwwww",
    "wwwwwwwwwwwwwwwwwwwwwww"
};

// Collection of all images - use after the image data is defined
const ImageData allImages[] = {
  {packers_logo, sizeof(packers_logo) / sizeof(packers_logo[0]), "Packers Logo"},
  {Iowa_logo, sizeof(Iowa_logo) / sizeof(Iowa_logo[0]), "Iowa Logo"},
  {charmander, sizeof(charmander) / sizeof(charmander[0]), "Charmander"},
  {r2d2, sizeof(r2d2) / sizeof(r2d2[0]), "R2D2"},
  {lebron, sizeof(lebron) / sizeof(lebron[0]), "lebron"},
  {beer, sizeof(beer)/ sizeof(beer[0]), "beer"}
};

// Number of available images
const int numImages = sizeof(allImages) / sizeof(allImages[0]);

// Function to get current image index
int getCurrentImageIndex() {
  return currentImageIndex;
}

// Function to move to next image
void nextImage() {
  currentImageIndex = (currentImageIndex + 1) % numImages;
}

// Function to move to previous image
void prevImage() {
  currentImageIndex = (currentImageIndex - 1 + numImages) % numImages;
}

// Function to draw the current image
void drawCurrentImage(MatrixPanel_I2S_DMA* display) {
  // Get current image data
  const ImageData& currentImage = allImages[currentImageIndex];
  const char** rows = currentImage.rows;
  int rowCount = currentImage.rowCount;
  
  // Calculate column count (width) from the first row
  int colCount = strlen(rows[0]);
  
  // Scale factor (adjust if needed)
  int scaleFactor = 2;

  //Lebron image has scale factor of 1
  if (currentImageIndex == 4) {
    scaleFactor = 1;
  }
  // Calculate offsets to center the image on the display
  int xOffset = (64 - (colCount * scaleFactor)) / 2;
  int yOffset = (64 - (rowCount * scaleFactor)) / 2;

  // Clear the display first
  display->fillScreen(display->color565(0, 0, 0));
  
  // Draw the image with scaling (no text displayed)
  for (int y = 0; y < rowCount; y++) {
    for (int x = 0; x < colCount; x++) {
      char pixelChar = rows[y][x];
      uint16_t color = getColorForChar(pixelChar, display);
      
      // Draw a scaled block for each original pixel
      for (int sy = 0; sy < scaleFactor; sy++) {
        for (int sx = 0; sx < scaleFactor; sx++) {
          // Apply offsets to center the scaled image
          int displayX = (x * scaleFactor) + sx + xOffset;
          int displayY = (y * scaleFactor) + sy + yOffset;
          // Draw the actual pixels
          display->drawPixel(displayX, displayY, color);
        }
      }
    }
  }
}

// Legacy function for backward compatibility
void drawLogo(MatrixPanel_I2S_DMA* display) {
  drawCurrentImage(display);
}