function classify
% Classify the boxes whose features are written in test.txt

system('code/svm_light/svm_classify code/svm_light/test.txt code/svm_light/model code/svm_light/predictions'); %% for three features

%%% getting results
load('data/boxes.mat');
load('code/svm_light/predictions');
uf = dir('data/images/*.jpg');
num_images = length(uf);
startindex = 0;
for i = 1:num_images
    no_boxes = size(boxes1{i},1);
    if(no_boxes == 0)
        continue;
    end
    boxes1{i}(:,end) = predictions(startindex+1:startindex+no_boxes);
    startindex = startindex + no_boxes;
end

save('data/boxes_before_postprocessing.mat','boxes1');
