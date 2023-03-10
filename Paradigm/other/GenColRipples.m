width = 760;  % Height of the screen 
fringe = 12;  % Width of the ramped fringe
width = width - fringe;
Phases = 0:15:355;

Stim = zeros(width, width, length(Phases));
[X Y] = meshgrid([-width/2:-1 1:width/2], [-width/2:-1 1:width/2]);
[T R] = cart2pol(X,Y);
circap = ones(width, width);
circap(R > width/2-fringe) = 1;
alphas = linspace(1, 0, fringe);
for f = 1:fringe
    circap(R > width/2-fringe+f) = alphas(f);
end
circap(R > width/2) = 0;

f = 1;
for pha = Phases
    img = double(PrettyPattern(sin(pha/180*pi)/4+1/2, 4, pha, width));
    img(img > 0) = 255;
    img = img - 127;
    img = uint8(img .* circap + 127);
    Stim(:,:,f) = img;
    f = f + 1;
end
StimFrames = 4;

Stimulus = zeros([size(Stim,1) size(Stim,2) 3 size(Stim,3)]);
frames = size(Stim,3);
Stimulus(:,:,1,:) = Stim;
Stimulus(:,:,2,:) = Stim(:,:,[frames/2+1:frames 1:frames/2]);
Stimulus(:,:,3,:) = Stim(:,:,[frames*(3/4)+1:frames 1:frames*(3/4)]);

save('ColRipples', 'Stimulus', 'StimFrames');

