width = 760;  % Height of the screen 
fringe = 12;  % Width of the ramped fringe
width = width - fringe;

img = double(RadialCheckerBoard([width/2 0], [-180 180], [7 5]));
[X Y] = meshgrid([-width/2:-1 1:width/2], [-width/2:-1 1:width/2]);
[T R] = cart2pol(X,Y);
circap = ones(width, width);
circap(R > width/2-fringe) = 1;
alphas = linspace(1, 0, fringe);
for f = 1:fringe
    circap(R > width/2-fringe+f) = alphas(f);
end
circap(R > width/2) = 0;
img = img - 127;
img = uint8(img .* circap + 127);
Stimulus = img;
Stimulus(:,:,2) = InvertContrast(img);
StimFrames = 8;

save('Checkerboard', 'Stimulus', 'StimFrames');
