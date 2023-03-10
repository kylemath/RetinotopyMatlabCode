function rori = RandOri(m, n)
%rori = RandOri([m, n])
%
% Returns a m x n matrix of random orientations between 1-360 degrees (integers only).
% Uses the rand function so rand must be set up.
%
% Parameters:
%   m :  Rows (optional, default = 1)
%   n :  Columns (optional, default = 1)
%   

if nargin < 1
    m = 1; n = 1;
elseif nargin < 2
    n = 1;
end

rori = ceil(rand(m,n)*360);