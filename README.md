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

🚀 Getting StartedPrerequisitesMATLAB (R2018b or newer recommended)Image Processing ToolboxInstallation & UsageClone the repositoryBashgit clone [https://github.com/F21C21/CPS843-License-Plate-Recognition.git](https://github.com/F21C21/CPS843-License-Plate-Recognition.git)
cd CPS843-License-Plate-Recognition
Prepare EnvironmentEnsure the templates_ontario and templates_multi folders are in the same directory as the scripts.Run the ApplicationOpen MATLAB and run the main GUI file:Matlab>> LicensePlateGUI
> Note: Do not run recognize_character_v2.m directly, as it requires inputs passed from the main GUI pipeline.Process an ImageClick "Load Image" in the GUI.Select a sample from the test_images/ folder.The system will display the Edge Map and the final recognized text string.⚙️ Technical DetailsPreprocessing (preprocess_image.m)The raw image undergoes Grayscale Conversion followed by Histogram Equalization to normalize brightness. Canny Edge Detection is then applied to generate a binary map of significant contours, effectively separating the plate boundaries from the vehicle body.Segmentation & RecognitionLocalization (locate_plate.m): Identifies the rectangular plate region based on edge density and aspect ratio constraints.Segmentation (segment_characters.m): Splits the plate into individual characters using vertical projection profiles.Recognition (recognize_character_v2.m): Compares segmented characters against the loaded templates using 2D correlation.📊 VisualizationThe GUI provides visual feedback for the recognition process:ViewDescriptionOriginal ImageThe raw input loaded from the test set.Edge MapOutput of the Canny operator, highlighting structural features.Final ResultThe recognized alphanumeric string overlaid on the interface.📝 LicenseDistributed under the MIT License. See LICENSE for more information.Maintained by FC.
