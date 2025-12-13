# CPS843-License-Plate-Recognition
A MATLAB-based Automatic Number Plate Recognition (ANPR) system featuring a custom GUI. Optimized for North American (Ontario) license plates using a hybrid approach of template matching and structural feature analysis.
MATLAB License Plate Edge Detection and Analysis
Overview
This project implements a MATLAB script for the preprocessing and feature extraction of license plate images. The workflow focuses on grayscale conversion, pixel intensity analysis through histograms, and structural feature extraction using the Canny edge detection algorithm. This process serves as the foundational stage for character segmentation and recognition.

Features
Grayscale Conversion: Transforms raw RGB images into grayscale to reduce computational complexity.

Histogram Analysis: Generates gray-level histograms to visualize the distribution of pixel intensities, aiding in contrast and exposure assessment.

Edge Detection: Applies the Canny operator to detect high-frequency components, effectively outlining character boundaries and plate edges.

Requirements
MATLAB (R2018b or later recommended)

Image Processing Toolbox

File Structure
Plaintext

.
├── main.m           # Primary processing script
├── plate_image.jpg  # Input image file
└── README.md        # Project documentation
Algorithm Description
Preprocessing: The script imports the source image and converts it from the RGB color space to grayscale using the standard luminosity function.

Statistical Analysis: It computes the frequency of each gray level (0-255) and plots the histogram. This step is crucial for determining if dynamic thresholding is required.

Feature Extraction: The script utilizes the Canny edge detector. This method finds the intensity gradients in the image, suppresses non-maximum pixels, and uses hysteresis thresholding to link edges.

Usage
Ensure the input image is located in the root directory.

Open the main script in MATLAB.

Execute the code.

The program will generate two figure windows: one displaying the intensity histogram and another showing the binary edge map.

Code Overview
The core logic relies on the following MATLAB functions:

Matlab

% Convert to grayscale
I_gray = rgb2gray(I);

% Generate Histogram
imhist(I_gray);

% Apply Canny Edge Detection
BW = edge(I_gray, 'canny');
