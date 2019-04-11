function demo
%This file presents the complete pipeline of the code

addpath('code/');
addpath('code/pff_code/');
addpath('code/pff_code/star-cascade');
addpath('code/skin_based_detector');
addpath('code/skin_based_detector/skindetector');

pca = 5;
thresh = -1;

fastflag = 1; % for faster cascaded version, else set it to 0.

%for hand shape model
load('trained_models/hand_shape_final.mat');
model.bboxpred = [];
if(fastflag)
    csc_shape_model = cascade_model(model,'shape',pca,thresh);
    shape_model = csc_shape_model;
else
    shape_model = model;
end
    
%for hand context model
load('trained_models/context_final.mat');
model.bboxpred = [];
if(fastflag)
    context_model = cascade_model(model,'shape',pca,thresh);
else
    context_model = model;
end
for i = 1:3
    disp(sprintf('Generating hypotheses for image (%d/3)', i));
    im = imread(sprintf('data/images/%d.jpg',i));
    
    disp('Running hand shape detector');
    [boxes, boxes_r, bboxes] = my_imgdetect_r(im, shape_model, shape_model.thresh, fastflag);
    if ~isempty(boxes)
        [boxes, bboxes] = clipboxes(im, boxes, bboxes);
        save(sprintf('code/pff_code/boxes/shape/%d.mat', i),'boxes', 'boxes_r');
    end
    
    disp('Running hand context detector');
    [boxes, boxes_r, bboxes] = my_imgdetect_r(im, context_model, context_model.thresh, fastflag);
    if ~isempty(boxes)
        [boxes, bboxes] = clipboxes(im, boxes, bboxes);
        save(sprintf('code/pff_code/boxes/context/%d.mat', i),'boxes', 'boxes_r');
    end
    
    disp('Getting skin regions');
    getSkinRegions(im, i);
    
    disp('Running skin based detector');
    getSkinBoxes(im, i);
end

disp('Writing the data in the test file for classification');
writetestfile;

disp('Classifying the hand proposals to get the new score');
classify;

disp('Postprocessing');
postprocess;

disp('Showing the results');
showresults;


