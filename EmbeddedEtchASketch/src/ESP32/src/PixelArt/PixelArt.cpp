/**
 * @file PixelArt.cpp
 * @author Matt Krueger & Sage Marks
 * @brief pixel art slideshow
 * @version 0.1
 * @date May 7th, 2025
 * 
 * @copyright Copyright (c) 2025
 * 
 * Implementation of the pixel art slideshow. Images are hardcoded - very tedius process - and displayed in slideshow fashion: 
 * - up arrow: go forward
 * - down arrow: go backwards
 * - hold home: exit to home as usual
 * 
 * Currently there are 
 * 
 */

#include "PixelArt/PixelArt.h"

// current image index
int currentImageIndex = 0;

// map character to RGB565 color
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
    case 'G': return display->color565(128,128,128);   // gray
    case 'B': return display->color565(0, 0, 255);     // blue
    default:  return display->color565(0, 0, 0);       // default to black
  }
}

// define a struct to hold image data
struct ImageData {
  const char** rows;
  int rowCount;
  const char* name;
};

// Green Bay Packers
const char* packers_logo[] = {
  "bbbbbbbbyyyyyyyyyyyyybbbbbbb",     
  "bbbbbbyygggggggggggggyybbbbb",     
  "bbbbyygggwwwwwwwwwwwgggyybbb",     
  "bbbygggwwwwwwwwwwwwwwwgggybb",     
  "bbyggwwwwwwwwwwwwwwwwwwwggyb",     
  "byggwwwwwwgggggggwwwwwwwwggy",     
  "yggwwwwwwggggggggggwwwwwwwgy",     
  "ygwwwwwwgggggggggggggggggggy",     
  "ygwwwwwwgggggggggggggggggggy",     
  "ygwwwwwwgggggggggggggggggggy",     
  "ygwwwwwwgggwwwwwwwwwwwwwwwgy",     
  "ygwwwwwwggggwwwwwwwwwwwwwwgy",     
  "bygwwwwwwwggggggggwwwwwwwggy",     
  "byggwwwwwwwwwwwwwwwwwwwwggyb",     
  "bbyggwwwwwwwwwwwwwwwwwwggybb",     
  "bbbygggwwwwwwwwwwwwwwgggybbb",     
  "bbbbyyggggwwwwwwwwggggyybbbb",     
  "bbbbbbyyyggggggggggyyybbbbbb",     
  "bbbbbbbbbyyyyyyyyyybbbbbbbbb"      
};

// Iowa Hawkeye
const char* Iowa_logo[] = {
  "bbbbbbbbbbbbbbbbbbbb", 
  "bbbbbbbbbbbbbbbbbbbb", 
  "bbbbbbbbbbbbbbbbbbbb", 
  "bbbbbbbbbbbbbbbbbbbb", 
  "bbbbbyyyyyyyyybbbbbb", 
  "bbbyyyyyyyyyyyyybbbb", 
  "bbyyyyyyyyyyyyyybbbb", 
  "byyyyyyyybyyybyybbbb", 
  "byyyyyybbbyyybbbbybb", 
  "bbyyyybyybbbbbbbyyyb", 
  "byyyyybyyyyyybbyyyyb", 
  "bbyyybbbyyyyybyyyyyb", 
  "byyybbbyyyyybbbbbyyb", 
  "bbybbbyyyyyybbybbbyb", 
  "bbbbbbyyyyybbbyybbbb", 
  "bbbbbbbyybbbbbbbbbbb", 
  "bbbbbbbbbbbbbbbbbbbb", 
  "bbbbbbbbbbbbbbbbbbbb", 
  "bbbbbbbbbbbbbbbbbbbb", 
  "bbbbbbbbbbbbbbbbbbbb"  
};

// Charamander Pokemon
const char* charmander[] = {
"wwwwwwwwwwwwwwwwwwwwwww", 
"wwwwwbbbbwwwwwwwwwbwwww", 
"wwwwboooobwwwwwwwbrbwww", 
"wwwboooooobwwwwwwbrrbww", 
"wwwboooooobwwwwwwbrrbww", 
"wwbooowbooobwwwwbrrorbw", 
"wboooobbooobwwwwbroyrbw", 
"wboooobboooobwwwbryyrbw", 
"wboooooooooobwwwwbybbww", 
"wwboooooooooobwwwbobwww", 
"wwwbbooooooooobwboobwww", 
"wwwwwbbboobooobboobwwww", 
"wwwwwwbyyboooooboobwwww", 
"wwwwwwbyyybbooobobwwwww", 
"wwwwwbwbyyyoooobbwwwwww", 
"wwwwwwbbbyyooobbwwwwwww", 
"wwwwwwwwwbbbobbwwwwwwww", 
"wwwwwwwwwwbwowbwwwwwwww", 
"wwwwwwwwwwwbbbwwwwwwwww", 
"wwwwwwwwwwwwwwwwwwwwwww"  
};

// R2-D2 
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

// Lebron James Logo
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

// Beer Pint
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

// define image structs
const ImageData allImages[] = {
  {packers_logo, sizeof(packers_logo) / sizeof(packers_logo[0]), "Packers Logo"},
  {Iowa_logo, sizeof(Iowa_logo) / sizeof(Iowa_logo[0]), "Iowa Logo"},
  {charmander, sizeof(charmander) / sizeof(charmander[0]), "Charmander"},
  {r2d2, sizeof(r2d2) / sizeof(r2d2[0]), "R2D2"},
  {lebron, sizeof(lebron) / sizeof(lebron[0]), "lebron"},
  {beer, sizeof(beer)/ sizeof(beer[0]), "beer"}
};

// number of available images
const int numImages = sizeof(allImages) / sizeof(allImages[0]);

/**
 * @brief Get the Current Image Index object
 * 
 * @return int index of current image
 */
int getCurrentImageIndex() {
  return currentImageIndex;
}

/**
 * @brief calculate the next image
 * 
 */
void nextImage() {
  currentImageIndex = (currentImageIndex + 1) % numImages;
}

/**
 * @brief calculate the previous image
 * 
 */
void prevImage() {
  currentImageIndex = (currentImageIndex - 1 + numImages) % numImages;
}

/**
 * @brief Draw the current image selected by the user
 * 
 * Most images are scaled by 2. This is not a standard size, but
 * because all of the pixel arts are very small (process took so long, so we keep thing small... 
 * there is definitely a better way, or this is an opportunity for us to create a application to convert to pixel art for
 *  small LED displays - most online tools are for large images)
 * 
 * The current pixel art image is sourced, then magnified before displaying it to the screen
 * 
 * @param display 
 */
void drawCurrentImage(MatrixPanel_I2S_DMA* display) {
  // get current image data
  const ImageData& currentImage = allImages[currentImageIndex];
  const char** rows = currentImage.rows;
  int rowCount = currentImage.rowCount;
  
  // calculate column count (width) from the first row
  int colCount = strlen(rows[0]);
  
  // scale factor
  int scaleFactor = 2;

  // lebron image has scale factor of 1
  if (currentImageIndex == 4) {
    scaleFactor = 1;
  }
  // calculate offsets to center the image on the display
  int xOffset = (64 - (colCount * scaleFactor)) / 2;
  int yOffset = (64 - (rowCount * scaleFactor)) / 2;

  // clear the display first
  display->fillScreen(display->color565(0, 0, 0));
  
  // draw the image with scaling (no text displayed)
  for (int y = 0; y < rowCount; y++) {
    for (int x = 0; x < colCount; x++) {
      char pixelChar = rows[y][x];
      uint16_t color = getColorForChar(pixelChar, display);
      
      // draw a scaled block for each original pixel
      for (int sy = 0; sy < scaleFactor; sy++) {
        for (int sx = 0; sx < scaleFactor; sx++) {

          // determine the location using the scale factor
          int displayX = (x * scaleFactor) + sx + xOffset;
          int displayY = (y * scaleFactor) + sy + yOffset;

          // draw the pixel & continue
          display->drawPixel(displayX, displayY, color);
        }
      }
    }
  }
}

/**
 * @brief deprecated driver
 * 
 * @param display matrix object
 */
void drawLogo(MatrixPanel_I2S_DMA* display) {
  drawCurrentImage(display);
}