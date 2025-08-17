# Outline Shader <!-- omit from toc -->

Add customizable cartoony outlines to your scene

## Table of Contents <!-- omit from toc -->

- [Description](#description)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Rational](#rational)
  - [Remarks](#remarks)
- [Disclaimer](#disclaimer)
- [Pull Requests](#pull-requests)
- [Credits](#credits)

## Description

This adds a shader which outlines the world.

### Features

- **Colorable edges**
- **Luminance, normal, and depth buffer edge detection**
- **Debug mode (which can also be used to render an outline pass)** 

### Requirements

- [GShader Library](https://steamcommunity.com/sharedfiles/filedetails/?id=3542644649) for the world normal texture

### Rational

To achieve a cartoony style in GMod, the artist must either use the built-in Sobel shader, or a screenspace edge detection post-processing effect in an application of their choosing. However, GMod's Sobel shader lacks much customizability in terms of the strength of the outline and the thresholding, and the edge detection effect has only the luminance of the image to determine an edge, with the tradeoff being customizability.

This outline shader attempts to achieve a similar level of customizability directly in GMod. It does this by using the depth buffer, normal buffer, and frame buffer (for luminance) to properly draw outlines

### Remarks

This shader is adapted from the following edge detection implementations:

- https://roystan.net/articles/outline-shader/
- https://ameye.dev/notes/edge-detection-outlines/

The shader was built off the first bulletpoint. For additional features, I have implemented the "fading edges from depth" and "luminance" edge detection from the second bulletpoint. Both algorithms use Roberts Cross as the edge detection algorithm.

## Disclaimer

## Pull Requests

When making a pull request, make sure to confine to the style seen throughout. Try to add types for new functions or data structures. I used the default [StyLua](https://github.com/JohnnyMorganz/StyLua) formatting style.

## Credits

- The following websites for the edge detection shaders
  - [Roystan's Unity Outline Shader](https://roystan.net/articles/outline-shader/)
  - [Alexander Amereye's Unity Outline Shader](https://ameye.dev/notes/edge-detection-outlines/)
- [Evgeny Akabenko for the GShader Library](https://steamcommunity.com/sharedfiles/filedetails/?id=3542644649)