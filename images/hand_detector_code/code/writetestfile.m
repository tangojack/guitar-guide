function writetestfile
% This function combines the hypotheses proposed using shape, context and
% skin colour and writes the test file for SVM classification

%It's better to initialize for better speed
uf = dir('data/images/*.jpg');
num_images = length(uf);
score_hand = cell(num_images,1); score_arm = cell(num_images,1); para_skin = cell(num_images,1); labels = cell(num_images,1); sfraction = cell(num_images,1); sbox = cell(num_images,1); boxtype = cell(num_images,1);

for i = 1:num_images
    disp(i);
    imgno = i;
    im = imread(sprintf('data/images/%d.jpg',imgno));
    
    load(sprintf('code/pff_code/boxes/shape/%d.mat',i)); 
    if(length(boxes) == 0)
        continue;
    end
    boxes_hand_all = boxes; 
    angle_hand_all = 180*atan2(boxes_r(:,2)-boxes_r(:,4),boxes_r(:,3)-boxes_r(:,1))/ pi; 
    [boxes trash] = clipboxes(im,boxes);
    I = nms(boxes,0.5); 
    boxes_hand = boxes(I,:); 
    angle_hand = angle_hand_all(I);
    
    load(sprintf('code/pff_code/boxes/context/%d.mat',i)); 
    boxes_arm_all = boxes; 
    angle_arm_all = 180*atan2(boxes_r(:,2)-boxes_r(:,4),boxes_r(:,3)-boxes_r(:,1))/ pi; 
    [boxes trash] = clipboxes(im,boxes); 
    I = nms(boxes,0.5); 
    angle_arm = angle_arm_all(I);
    boxes_arm = boxes(I,:);
    clear boxes boxes_r;
    
    load(sprintf('code/skin_based_detector/boxes/%d.mat',i)); 
    boxes_skin = boxes_new; 
    angle_skin = 180*atan2(boxes_r_new(:,2)-boxes_r_new(:,4),boxes_r_new(:,3)-boxes_r_new(:,1))/ pi; 
    boxes_skin_para = newboxes_para;
    clear boxes_new newboxes_para boxes_r_new;
    
    [score_hand{i} score_arm{i} para_skin{i} boxes boxtype{i}] = combine_boxes(boxes_hand,boxes_arm,boxes_skin,boxes_skin_para,boxes_hand_all,boxes_arm_all,angle_hand_all,angle_arm_all,angle_hand,angle_arm,angle_skin);
    
    boxes = max(boxes,1);
    boxes(:,3) = min(boxes(:,3),size(im,2));
    boxes(:,4) = min(boxes(:,4),size(im,1));
    
    %%% computing skin fraction
    skinprob = computeSkinProbability(double(im));
    normaliseskinprob = normalise(skinprob);
    skinmask = (normaliseskinprob > 0.64);
    skinmask = bwareaopen(skinmask,100);
    seg = load(sprintf('data/segments/%d.mat',imgno));
    clear skinfraction sizebox;
    
    for j = 1:size(boxes,1)
        skinbox = skinmask(boxes(j,2):boxes(j,4),boxes(j,1):boxes(j,3));
        skinfraction(j) = sum(skinbox(:))/length(skinbox(:));
        sizebox(j) = length(skinbox(:));
        box = boxes(j,[1:4]);
        box = max(box,1);
        box(3) = min(box(3),size(im,2));
        box(4) = min(box(4),size(im,1));
        box_new = [round(box(1)+0.25*(box(3)-box(1)+1)) round(box(2)+0.25*(box(4)-box(2)+1)) round(box(3)-0.25*(box(3)-box(1)+1)) round(box(4)-0.25*(box(4)-box(2)+1))];
        labels_rect = seg.labels(box_new(2):box_new(4),box_new(1):box_new(3));
        mode_label = mode(labels_rect(:));
        mode_label_mask = zeros(size(labels_rect,1),size(labels_rect,2));
        I = find(labels_rect == mode_label);
        mode_label_mask(I) = 1;
        skinmask_rect = skinmask(box_new(2):box_new(4),box_new(1):box_new(3));
        skinmask_rect = skinmask_rect .* mode_label_mask;
        skinfraction(j) = sum(skinmask_rect(:)) / sum(mode_label_mask(:));
    end
    %skinfraction = (skinfraction > 0.3);
    sfraction{i} = skinfraction;
    sbox{i} = sizebox;

    
    score = score_hand{i} + 0.35*score_arm{i}+ skinfraction*0.5; %% 0.35 0.5
    boxes(:,end) = score;
    boxes1{i} = boxes;
    
    labels{i} = zeros(1,size(boxes,1));
end
score_hand_mat = cell2mat(score_hand');
score_arm_mat = cell2mat(score_arm');
para_skin_mat = cell2mat(para_skin);
labels_mat = cell2mat(labels');
sfraction_mat = cell2mat(sfraction');
sbox_mat = cell2mat(sbox');

para_skin_mat = para_skin_mat(:,1:4);

save('data/boxes.mat','boxes1');

save('data/boxtype.mat','boxtype');

save('data/attributes.mat','score_hand_mat','score_arm_mat','para_skin_mat','labels_mat','sfraction_mat','sbox_mat');

%%% trace normalization
deno_hand = 253.67;
deno_arm = 172.38;
deno_sfraction = 81.61;

score_hand_mat = score_hand_mat ./ deno_hand;
score_arm_mat = score_arm_mat ./ deno_arm;
sfraction_mat = sfraction_mat ./ deno_sfraction;
%%%

%%% writing into the file
fid = fopen('code/svm_light/test.txt','w');
for i = 1:length(labels_mat)
    fprintf(fid,'%d',labels_mat(i));
    fprintf(fid,' 1:%f',score_hand_mat(i));
    fprintf(fid,' 2:%f',score_arm_mat(i));
    fprintf(fid,' 3:%f',sfraction_mat(i));
    fprintf(fid,'\n');
end
fclose(fid);
