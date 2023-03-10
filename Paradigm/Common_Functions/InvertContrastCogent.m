function imgOut = InvertContrastCogent(imgIn)
%imgOut = InvertContrastCogent(imgIn)
%
% Inverts the contrast of a greyscale image.
%

imgOut = abs(imgIn-1);
