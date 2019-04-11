function [ap1, boxes1] = postprocess
% Post-process the detection results

load('data/attributes.mat');

load('data/boxes_before_postprocessing.mat');

load('data/boxtype.mat');

count_all = 0;

uf = dir('data/images/*.jpg');
num_images = length(uf);

for i = 1:num_images
    labels = [];
    index = i;
    imgno = i;
    load(sprintf('data/segments/%d.mat',imgno));
    im = imread(sprintf('data/images/%d.jpg',imgno));
    
    no_labels = max(labels(:));
    check_labels = zeros(no_labels,1);
    area_labels = zeros(no_labels,1);
    for j = 1:no_labels
        imlabel = (labels == j);
        regionprop = regionprops(imlabel,'Extent','BoundingBox','ConvexArea','Eccentricity','MajorAxisLength','MinorAxisLength');
        ratiohw = regionprop.BoundingBox(4) / regionprop.BoundingBox(3);
        ratio = regionprop.MajorAxisLength / regionprop.MinorAxisLength;
        fillingprop = regionprop.Extent;
        areaprop = regionprop.ConvexArea / (regionprop.BoundingBox(3)*regionprop.BoundingBox(4));
        eccentricity = regionprop.Eccentricity;
        regionprop_valid = (((fillingprop >= 0.45) && (areaprop >=0.65)) && ~((ratiohw < 0.55) || (ratiohw > 1.80))) ;
        %regionprop_valid = (ratio < 2.5);
        if(regionprop_valid)
            check_labels(j) = 1;
        end
        area_labels(j) = sum(sum(imlabel));
        bounding_box{j} = regionprop.BoundingBox;
        minoraxislength{j} = regionprop.MinorAxisLength;
    end
    
    box = boxes1{index};
    if(length(box) == 0)
        continue;
    end
    [val sortI] = sort(-box(:,end));
    val = -val;
    box = box(sortI,:);
    used_seg = zeros(no_labels,1);
    box_seg = cell(no_labels,1);
    for j = 1:size(box,1)%min(size(box,1),5)
        x1 = box(j,1); x1 = max(x1,1);
        y1 = box(j,2); y1 = max(y1,1);
        x2 = box(j,3); x2 = min(x2,size(im,2));
        y2 = box(j,4); y2 = min(y2,size(im,1));
        y1_new = round(y1+0.25*(y2-y1+1)); y2_new = round(y2-0.25*(y2-y1+1)); x1_new = round(x1+0.25*(x2-x1+1)); x2_new = round(x2-0.25*(x2-x1+1));
        patch_segment = labels(y1:y2,x1:x2);
        area_segment = (y2-y1+1)*(x2-x1+1);
        values_patch_segment = unique(labels(y1_new:y2_new,x1_new:x2_new));
        for index_patch_segment = 1:length(values_patch_segment)
            val_patch_segment = values_patch_segment(index_patch_segment);
            if((val_patch_segment == 0))
                continue;
            end
            no_elements = sum(sum(patch_segment == val_patch_segment));
            fraction_area_occupied_by_elements = no_elements / area_segment;
            fraction_area_element_inside_box = no_elements / area_labels(val_patch_segment);
            if(check_labels(val_patch_segment) ~= 0)
                if(((fraction_area_occupied_by_elements > 0.25) && (fraction_area_element_inside_box > 0.80)))  %0.3195
                    if(~used_seg(val_patch_segment))
                        used_seg(val_patch_segment) = 1;
                        box(j,[1:4]) = round(bounding_box{val_patch_segment});
                        box(j,3) = box(j,3) + box(j,1) + 6; box(j,3) = min(box(j,3),size(im,2));
                        box(j,4) = box(j,4) + box(j,2) + 6; box(j,4) = min(box(j,4),size(im,1));
                        box(j,1) = max(box(j,1)-6,1);
                        box(j,2) = max(box(j,2)-6,1);
                        box_seg{val_patch_segment} = box(j,[1:4 end]);
                    else
                        box(j,end) = -Inf;
                    end
                end
            else
                if(fraction_area_occupied_by_elements > 0.305) %% 0.35
                    box_t = [box(j,[1:4 end]); box_seg{val_patch_segment}];
                    I = nms_mod(box_t,0.4);
                    box_seg{val_patch_segment} = box_t(I,:);
                    if(~used_seg(val_patch_segment) || sum(I == 1))
                        used_seg(val_patch_segment) = 1;
                    else
                        box(j,end) = -Inf;
                    end
                end
            end
        end
    end
    
    btype = boxtype{i};
    score_hand = score_hand_mat(count_all+1:count_all+length(btype));
    score_arm = score_arm_mat(count_all+1:count_all+length(btype));
    sfraction = sfraction_mat(count_all+1:count_all+length(btype));
    score_hand = score_hand(sortI);
    score_arm = score_arm(sortI);
    sfraction = sfraction(sortI);
    I_hand = find(btype == 1);
    I_arm = find(btype == 2);
    I_skin = find(btype == 3);
    hand_boxes = box(I_hand,:);
    arm_boxes = box(I_arm,:);
    skin_boxes = box(I_skin,:);
    
    btype_hand = btype(I_hand);
    btype_arm = btype(I_arm);
    btype_skin = btype(I_skin);
    
    I = nms_mod(hand_boxes,0.95); %%0.95 %% 0.99
    I_hand = I_hand(I);
    btype_hand = btype_hand(I);
    I_new = [I_hand I_arm I_skin];
    score{i} = [score_hand(I_new)' score_arm(I_new)' sfraction(I_new)'];
    hand_boxes = hand_boxes(I,:);
    box = [hand_boxes; arm_boxes; skin_boxes];
    boxtype{i} = [btype_hand btype_arm btype_skin];
    count_all = count_all + length(btype);
    boxes1{index} = box;
    
    %%% code to remove boxes overlaping faces
    load(sprintf('data/faceboxes/%d.mat',imgno));
    if(length(facebox) ~= 0)
        boxes_det = boxes1{i}(:,1:4);
        boxes_det(:,3) = (boxes_det(:,3)-boxes_det(:,1)+1);
        boxes_det(:,4) = (boxes_det(:,4)-boxes_det(:,2)+1);
        facebox = facebox';
        facebox = facebox(:,[1 3 2 4]);
        facebox(:,3) = (facebox(:,3)-facebox(:,1)+1);
        facebox(:,4) = (facebox(:,4)-facebox(:,2)+1);
        areaint = rectint(boxes_det,facebox);
        boxes_det_area = (boxes_det(:,3)).*(boxes_det(:,4));
        boxes_det_area = repmat(boxes_det_area,[1, size(areaint,2)]);
        facebox_area = (facebox(:,3)).*(facebox(:,4));
        facebox_area = facebox_area';
        facebox_area = repmat(facebox_area,[size(areaint,1) 1]);
        areauni = boxes_det_area + facebox_area - areaint;
        overlapscore = areaint ./ areauni;
        if(size(overlapscore,2) > 1)
            maxoverlapscore = max(overlapscore');
        else
            maxoverlapscore = overlapscore;
        end
        I = find(maxoverlapscore > 0.20); %%0.7
        for j = 1:length(I)
            boxes1{i}(I(j),end) = -Inf;
        end
    end
    
    [trash box_index] = sort(-boxes1{index}(:,end));
    boxes1{index} = boxes1{index}(box_index,:);
    
end

save('data/boxes_after_postprocessing.mat','boxes1');
