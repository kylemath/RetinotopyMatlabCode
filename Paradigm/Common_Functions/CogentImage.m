function ImgCogent = CogentImage(Img8bit)
%ImgCogent = CogentImage(Img8bit)
% Converts the 8 bit image (0-255) into a cogent image (0-1).
%

ImgCogent = (double(Img8bit)+1)/256;
