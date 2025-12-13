# MATLAB License Plate Recognition System

![MATLAB](https://img.shields.io/badge/MATLAB-R2021a-orange.svg)
![GUI](https://img.shields.io/badge/Interface-GUI-blueviolet.svg)
![Status](https://img.shields.io/badge/Status-Active-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

## 📖 Overview

This repository hosts a complete **Automatic License Plate Recognition (ALPR)** system implemented in MATLAB.

Designed for the **CPS843** course project, the system features a user-friendly **Graphical User Interface (GUI)** to process vehicle images. It integrates a full computer vision pipeline—from raw image preprocessing (grayscale conversion, histogram analysis, edge detection) to character segmentation and template-based recognition—with specific optimization for **Ontario, Canada** license plates.

## ⚙️ Key Features

* **Interactive GUI**: User-friendly interface (`LicensePlateGUI`) for seamless image loading and analysis.
* **Advanced Preprocessing**:
    * **Histogram Analysis**: Evaluates illumination distribution for adaptive thresholding.
    * **Canny Edge Detection**: Extracts high-precision structural boundaries of the plates.
* **Robust Recognition**:
    * **Template Matching**: Correlation coefficient matching against a custom database (`templates_ontario`).
    * **Segmentation**: Vertical projection histograms for isolating individual characters.
* **Smart Post-processing**: Logic filters to refine OCR results and reduce false positives.

## 📂 Repository Structure

```text
CPS843-License-Plate-Recognition/
├── templates_multi/          # Template data for general license plates
├── templates_ontario/        # Specific templates for Ontario plates
├── test_images/              # Sample images for testing
├── imgfildata.mat            # Matfile containing image/template data
├── LicensePlateGUI.m         # [ENTRY POINT] Main GUI application script
├── load_multi_templates.m    # Helper script to load template databases
├── locate_plate.m            # Algorithm to isolate the plate region
├── preprocess_image.m        # Grayscale conversion & Canny edge detection
├── segment_characters.m      # Character segmentation logic
├── recognize_character_v2.m  # OCR core recognition algorithm
├── smart_postprocess.m       # Result refinement logic
└── README.md
