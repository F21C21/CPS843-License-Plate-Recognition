# MATLAB License Plate Recognition System

![MATLAB](https://img.shields.io/badge/MATLAB-R2021a-orange.svg)
![GUI](https://img.shields.io/badge/Interface-GUI-blueviolet.svg)
![Status](https://img.shields.io/badge/Status-Active-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

## Overview

This repository hosts a complete Automatic License Plate Recognition (ALPR) system implemented in MATLAB.

Designed for the CPS843 course project, the system provides a GUI-based pipeline for vehicle image processing, including preprocessing, license plate localization, character segmentation, and template-based recognition optimized for Ontario, Canada license plates.

## Key Features

- Interactive GUI (LicensePlateGUI)
- Histogram-based illumination analysis
- Canny edge detection for plate boundary extraction
- Template matching using correlation coefficients
- Vertical projection–based character segmentation
- Post-processing logic to reduce false positives

## Repository Structure

```text
CPS843-License-Plate-Recognition/
├── templates_multi/
├── templates_ontario/
├── test_images/
├── imgfildata.mat
├── LicensePlateGUI.m
├── load_multi_templates.m
├── locate_plate.m
├── preprocess_image.m
├── segment_characters.m
├── recognize_character_v2.m
├── smart_postprocess.m
└── README.md
```

## Getting Started

Prerequisites

MATLAB R2018b or newer (R2021a recommended)  
Image Processing Toolbox

Installation

git clone https://github.com/F21C21/CPS843-License-Plate-Recognition.git  
cd CPS843-License-Plate-Recognition

Running the Application

>> LicensePlateGUI

Do not run recognize_character_v2.m directly.  
This function must be called from the GUI pipeline.

## Processing Workflow

1. Load an image from the test_images folder.
2. Preprocess the image (grayscale, histogram equalization, edge detection).
3. Localize the license plate region.
4. Segment individual characters.
5. Perform template-based recognition.
6. Display the recognized license plate string.

## Visualization

Output | Description  
Original Image | Raw vehicle image  
Edge Map | Canny edge detection result  
Final Result | Recognized license plate text

## License

This project is licensed under the MIT License.

Maintained by FC.
