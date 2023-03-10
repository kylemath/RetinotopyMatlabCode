function img = PrettyPattern(lambda, sptfrq, phase, width)
%img = PrettyPattern(lambda, sptfrq, phase, width)
%
% Draws a pretty pattern stimulus.
%
% Parameters:
%   lambda :    Wavelength of the sinusoid
%   sptfrq :    Spatial frequency of checkers
%   phase :     Phase of the sinusoid
%   width :     Width of the image
%
% The function returns the new image.
%

%% Grating
% Parameters for all pixels
[X Y] = meshgrid(-width/2:width/2-1, -width/2:width/2-1);
[T R] = cart2pol(X,Y);

% Luminance modulation at each pixel
G = R .* (cos(2*pi .* (sind(sptfrq*X) + cosd(sptfrq*Y)) ./ lambda + phase));

%% Image matrix
img = uint8(G);


