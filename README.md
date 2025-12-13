# MATLAB License Plate Recognition System

![MATLAB](https://img.shields.io/badge/MATLAB-R2021a-orange.svg)
![GUI](https://img.shields.io/badge/Interface-GUI-blueviolet.svg)
![Status](https://img.shields.io/badge/Status-Active-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

---

## 📖 Overview

This repository hosts a complete **Automatic License Plate Recognition (ALPR)** system implemented in **MATLAB**.

Designed for the **CPS843** course project, the system features a user-friendly **Graphical User Interface (GUI)** to process vehicle images. It integrates a full computer vision pipeline—from raw image preprocessing (grayscale conversion, histogram analysis, edge detection) to character segmentation and template-based recognition—with specific optimization for **Ontario, Canada** license plates.

---

## ⚙️ Key Features

- **Interactive GUI**  
  User-friendly interface (`LicensePlateGUI`) for seamless image loading and analysis.

- **Advanced Preprocessing**
  - **Histogram Analysis**: Evaluates illumination distribution for adaptive thresholding.
  - **Canny Edge Detection**: Extracts high-precision structural boundaries of license plates.

- **Robust Recognition**
  - **Template Matching**: Correlation coefficient matching against a custom database (`templates_ontario`).
  - **Character Segmentation**: Vertical projection histograms for isolating individual characters.

- **Smart Post-processing**
  - Logic filters to refine OCR results and reduce false positives.

---

## 📂 Repository Structure

```text
CPS843-License-Plate-Recognition/
├── templates_multi/          # Template data for general license plates
├── templates_ontario/        # Specific templates for Ontario plates
├── test_images/              # Sample images for testing
├── imgfildata.mat            # MAT-file containing image/template data
├── LicensePlateGUI.m         # [ENTRY POINT] Main GUI application script
├── load_multi_templates.m    # Helper script to load template databases
├── locate_plate.m            # Algorithm to isolate the plate region
├── preprocess_image.m        # Grayscale conversion & Canny edge detection
├── segment_characters.m      # Character segmentation logic
├── recognize_character_v2.m  # OCR core recognition algorithm
├── smart_postprocess.m       # Result refinement logic
└── README.md
🚀 Getting Started
Prerequisites
MATLAB R2018b or newer (R2021a recommended)

Image Processing Toolbox

Installation & Usage
1. Clone the Repository
bash
复制代码
git clone https://github.com/F21C21/CPS843-License-Plate-Recognition.git
cd CPS843-License-Plate-Recognition
2. Prepare the Environment
Ensure the following folders are located in the same directory as the MATLAB scripts:

templates_ontario/

templates_multi/

3. Run the Application
Open MATLAB and execute:

matlab
复制代码
>> LicensePlateGUI
Note
Do not run recognize_character_v2.m directly.
This function requires inputs passed from the main GUI pipeline.

4. Process an Image
Click "Load Image" in the GUI.

Select a sample image from the test_images/ folder.

The system will display:

The Edge Map

The final recognized license plate string

⚙️ Technical Details
Preprocessing (preprocess_image.m)
The raw image undergoes:

Grayscale Conversion

Histogram Equalization to normalize brightness

Canny Edge Detection to generate a binary contour map

This step effectively separates license plate boundaries from the vehicle body.

Segmentation & Recognition Pipeline
Localization (locate_plate.m)
Identifies the rectangular plate region using edge density and aspect ratio constraints.

Segmentation (segment_characters.m)
Splits the plate into individual characters using vertical projection profiles.

Recognition (recognize_character_v2.m)
Matches segmented characters against stored templates using 2D correlation.

📊 Visualization
The GUI provides real-time visual feedback throughout the recognition process:

View	Description
Original Image	Raw input loaded from the test set
Edge Map	Output of the Canny operator highlighting structural features
Final Result	Recognized alphanumeric string displayed in the GUI

📝 License
Distributed under the MIT License.
See LICENSE for more information.

Maintained by FC.
