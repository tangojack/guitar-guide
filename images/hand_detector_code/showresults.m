function showresults
%This function displays the top 2 results for the demo
uf = dir('data/images/*.jpg');
load('data/boxes_after_postprocessing.mat');
num_results = 2;
for i = 1:length(uf)
    im = imread(sprintf('data/images/%s', uf(i).name));
    imshow(im);
    boxes = boxes1{i};
    for j = 1:num_results
        rectangle('position',[boxes(j,1) boxes(j,2) (boxes(j,3) - boxes(j,1) + 1) (boxes(j,4) - boxes(j,2) + 1)], 'EdgeColor','r');
    end
    disp('Press any key to move onto the next image');
    pause;
end
disp('Done!');