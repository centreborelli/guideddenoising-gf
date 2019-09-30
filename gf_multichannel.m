function v = gf_multichannel(u, epsilon, radius)
% gf_multichannel is the Guided Filter for images with 1, 2 or 3 channels.
%
% v = gf_multichannel(u)
% v = gf_multichannel(u, epsilon, radius)
%
% This function uses "conv2" rather that "imboxfilt" for the box filter, so that
% it can be executed with Octave (imboxfilt is only in Matlab).
%
% Copyright (C) 2019, Charles Hessel <charles.hessel@cmla.ens-cachan.fr>
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
%
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

if ~exist('epsilon', 'var') || isempty(epsilon), epsilon = 0.004^2; end
if ~exist('radius', 'var')  || isempty(radius),  radius = 1;        end

switch size(u,3)
    case 1
        v = gf_gray(u, epsilon, radius);

    case 2
        v = gf_2chan(u, epsilon, radius);

    case 3
        v = gf_color(u, epsilon, radius);

    otherwise
        error('Only input images with 1, 2 of 3 channels are accepted.')
end


function R = gf_gray(I, epsilon, radius, G)

switch nargin
    case 3 % G = I
        I_mean = fmean(I   , radius);
        I_var  = fmean(I.^2, radius) - I_mean.^2;
        a      = I_var ./ (I_var + epsilon);
        b      = (1 - a) .* I_mean ;
        R      = fmean(a, radius) .* I + fmean(b, radius);

    case 4 % G \neq I
        I_mean = fmean(I   , radius);
        G_mean = fmean(G   , radius);
        G_var  = fmean(G.^2, radius) - G_mean.^2;
        IG_cov = fmean(I.*G, radius) - I_mean .* G_mean;
        a      = IG_cov ./ (G_var + epsilon);
        b      = I_mean - a .* G_mean;
        R      = fmean(a, radius) .* G + fmean(b, radius);

    otherwise
        error('Incorrect number of arguments.')
end


function R = gf_2chan(G, epsilon, radius)
% Beware: this function assume that the (2-channels) input is guided by itself.
% This means that each of the two input channels are filtered according to the
% full 2-channels image. This is more efficient than to filter each individual
% channel using a function with guide because we can factorize computations.

% mean vector and covariance matrix of "color" guide
Gm    = fmean(G, radius);
Gv_rr = fmean(G(:,:,1).^2, radius) - Gm(:,:,1).^2 + epsilon;
Gv_gg = fmean(G(:,:,2).^2, radius) - Gm(:,:,2).^2 + epsilon;
Gv_rg = fmean(G(:,:,1) .* G(:,:,2), radius) - Gm(:,:,1) .* Gm(:,:,2);

detS  = Gv_rr .* Gv_gg - Gv_rg.^2;

R = zeros(size(G));
for channel = 1:2
    Im = Gm(:,:,channel);
    switch channel
        case 1
            IGc_r = Gv_rr - epsilon;
            IGc_g = Gv_rg;
        case 2
            IGc_r = Gv_rg;
            IGc_g = Gv_gg - epsilon;
    end

    % solve the system and get vector of linear coefficients "a"
    detR = IGc_r .* Gv_gg - IGc_g .* Gv_rg;
    detG = Gv_rr .* IGc_g - Gv_rg .* IGc_r;

    a     = cat(3, detR./detS, detG./detS);
    b     = Im - sum(a .* Gm, 3);

    % compute output gray image
    R(:,:,channel) = sum(fmean(a, radius) .* G, 3) + fmean(b, radius);
end


function R = gf_color(G, epsilon, radius)
% Beware: this function assume that the (color) input is guided by itself.
% This means that each of the three input channels are filtered according to the
% full color image. This is more efficient than to filter each individual
% channel using a function with guide because we can factorize computations.

% mean vector and covariance matrix of color guide
Gm    = fmean(G, radius);
Gv_rr = fmean(G(:,:,1).^2, radius) - Gm(:,:,1).^2 + epsilon;
Gv_gg = fmean(G(:,:,2).^2, radius) - Gm(:,:,2).^2 + epsilon;
Gv_bb = fmean(G(:,:,3).^2, radius) - Gm(:,:,3).^2 + epsilon;
Gv_rg = fmean(G(:,:,1) .* G(:,:,2), radius) - Gm(:,:,1) .* Gm(:,:,2);
Gv_rb = fmean(G(:,:,1) .* G(:,:,3), radius) - Gm(:,:,1) .* Gm(:,:,3);
Gv_gb = fmean(G(:,:,2) .* G(:,:,3), radius) - Gm(:,:,2) .* Gm(:,:,3);
detS  = + Gv_rr .* (Gv_gg .* Gv_bb - Gv_gb .* Gv_gb ) ...
        - Gv_rg .* (Gv_rg .* Gv_bb - Gv_rb .* Gv_gb ) ...
        + Gv_rb .* (Gv_rg .* Gv_gb - Gv_rb .* Gv_gg ) ;

R = zeros(size(G));
for channel = 1:3
    Im = Gm(:,:,channel);
    switch channel
        case 1
            IGc_r = Gv_rr - epsilon; IGc_g = Gv_rg; IGc_b = Gv_rb;
        case 2
            IGc_r = Gv_rg; IGc_g = Gv_gg - epsilon; IGc_b = Gv_gb;
        case 3
            IGc_r = Gv_rb; IGc_g = Gv_gb; IGc_b = Gv_bb - epsilon;
    end

    % solve the system and get vector of linear coefficients "a"
    detR  = +IGc_r.*( Gv_gg.*Gv_bb - Gv_gb.*Gv_gb ) ...
            -Gv_rg.*( IGc_g.*Gv_bb - IGc_b.*Gv_gb ) ...
            +Gv_rb.*( IGc_g.*Gv_gb - IGc_b.*Gv_gg ) ;
    detG  = +Gv_rr.*( IGc_g.*Gv_bb - IGc_b.*Gv_gb ) ...
            -IGc_r.*( Gv_rg.*Gv_bb - Gv_rb.*Gv_gb ) ...
            +Gv_rb.*( Gv_rg.*IGc_b - Gv_rb.*IGc_g ) ;
    detB  = +Gv_rr.*( Gv_gg.*IGc_b - Gv_gb.*IGc_g ) ...
            -Gv_rg.*( Gv_rg.*IGc_b - Gv_rb.*IGc_g ) ...
            +IGc_r.*( Gv_rg.*Gv_gb - Gv_rb.*Gv_gg ) ;

    a     = cat(3, detR./detS, detG./detS, detB./detS);
    b     = Im - sum(a .* Gm, 3);

    % compute output gray image
    R(:,:,channel) = sum(fmean(a, radius) .* G, 3) + fmean(b, radius);
end


function v = fmean(u, radius)
% Local average with a window of size (2*radius+1)^2
% Matlab's function "imboxfilt" does not exist in Octave.
% In Octave, conv2 seems slightly faster than imfilter in the test I did.

kernel = ones(radius*2 + 1) / (radius*2 + 1)^2;
v = zeros(size(u));
for channel = 1:size(u,3)
    v(:, :, channel) = conv2(...
        padarray(u(:, :, channel), [radius radius], 'symmetric'), ...
        kernel, 'valid');
end
