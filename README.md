# Outline Shader <!-- omit from toc -->

Add customizable cartoony outlines to your GMod scene

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

[![Preview](https://img.youtube.com/vi/pENsg6CckkU/0.jpg)](https://www.youtube.com/watch?v=pENsg6CckkU)

This adds a shader which outlines the world. You can find this addon in the Post Process Tab > Shaders > Outline (vlazed)

### Features

- **Colorable edges**
- **Luminance, normal, and depth buffer edge detection**
- **Debug mode (which can also be used to render an outline pass)** 

See a [comparison!](/COMPARISON.md)

### Requirements

- [GShader Library](https://steamcommunity.com/sharedfiles/filedetails/?id=3542644649) for _rt_NormalsTangents normal buffer and _rt_ResolvedFullFrameDepth depth buffers. Both are critical in the edge detection algorithm

Once you subscribe to the above addon, you need to enable it. This is also found in the same location as the Outline shader, as "GShader library".

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