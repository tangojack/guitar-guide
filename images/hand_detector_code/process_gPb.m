function process_gPb
% This function generates super-pixels using globalPb code from Berkeley group and saves
% the results

uf = dir('data/images/*.jpg');

mkdir('data/temp');

addpath('code/globalPb'); % change this if globalPb is installed at a different location
num_images = length(uf);
for i = 1:num_images
    disp(i);
    rsz = 1.0;
    imgFile = uf(i).name;
    outFile = sprintf('data/temp/%d.mat', i);

    [gPb_orient, gPb_thin, textons] = globalPb(imgFile, outFile, rsz);

    % for regions
    ucm = contours2ucm(gPb_orient);

    load(sprintf('gPb_output/%d.mat',i));
    k = 64; %100
    bdry = (ucm >= k);
    labels = bwlabel(ucm <= k);
    save(sprintf('data/segments/%d.mat',i),'labels');
end