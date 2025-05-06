# Yeah this is beyond my paygrade, there is something cool behind the scenes with some repurposed I2C (S sound) to free the CPU usage, but it is going over my head. Here are the important functions for our usage:
 
## Important Functions:
### Basic Drawing Functions:
- `drawPixel(x, y, color)` - Draw individual pixels
- `fillRect(x, y, width, height, color)` - Fill rectangles for board squares
- `drawRect(x, y, width, height, color)` - Draw outlines
- `fillScreen(color)` - Clear the entire board

### Color Functions:
- `color565(r, g, b)` - Convert RGB values to 16-bit color format
- `color444(r, g, b)` - Simplified color definition with 4-bit per channel

### Text Drawing (for labels/coordinates):
- `setCursor(x, y)` - Set text position
- `setTextColor(color)` - Set text color
- `setTextSize(size)` - Set text size
- `print("text")` - Print text at cursor position

### Brightness Control:
- `setBrightness(value)` or `setBrightness8(value)` - Adjust display brightness
