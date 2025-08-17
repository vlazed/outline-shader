# Outline Comparisons

I will refer to the Roberts Cross depth, normal, and luminance buffer method as the Outline method.

If necessary, I will also add more comparisons.

### Outline settings
![](/media/outline_settings.png)

## In-game

| Sobel (Threshold = 0.58) | Outline |
|:-------:|:-------:|
|![](/media/sobel_threshold_058.png)|![](/media/outline.png)|

## Post-Processing (using GIMP)

For the outline shader, only the outlines were rendered out using Debug mode. The outlines are keyed out, and applied to a Soft Lamps render 

| Cartoon filter | Roberts Cross | Outline |
|:----------------:|:---------------:|:---------:|
|![](/media/outline_test3.png)|![](/media/outline_test2.png)|![](/media/outline_test.png)|

## Appendix

Name    | Key                      | Bounce                      | Rimlight 1                | Rimlight 2                | Outline
---     | ---                      | ---                         | ---                       | ---                       | ---
Renders | ![](/media/pass/key.png) | ![](/media/pass/bounce.png) | ![](/media/pass/rim1.png) | ![](/media/pass/rim2.png) | ![](/media/pass/outline.png)