function [hist, binC] = imageTrilinearHistVotingFast(im,quan,weights)
% labImageTrilinearHistVotingFast(im,quan,weight)
% im - input image in Lab color space
% dims - quantization in L a b dimensions
% weight - for each pixel in the corresponding image <0-1>

% !!!image's channels must be scaled accross interval <0,255> !!!
  if ~isfloat(im)
    error('im - must be floating point array use double(im) ');
  end
  siz = size(im);
  if numel(siz) ~= 3 || siz(3) ~= 3
    error('input image must be 3 channel image');
  end
  if isscalar(quan)
    quan = [quan quan quan];
  end
  if numel(quan) ~= 3
    error('bins - incorrect size');
  end

  N = siz(1)*siz(2); % n of pixels
  
  im = reshape(im,N,siz(3));
  
  if nargin == 3
    weights = reshape(weights,N,size(weights,3));
    [hist, binC] = triLinearVoting(im,quan,weights);
  else
    [hist binC] = triLinearVoting(im,quan);
  end
end