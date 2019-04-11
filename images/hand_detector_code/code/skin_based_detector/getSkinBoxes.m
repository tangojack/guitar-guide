function getSkinBoxes(im, imgno)
% This function hypothesises the hand bounding boxes from the detected skin
% regions

uf = dir(sprintf('code/skin_based_detector/skinregions/%d_*.mat',imgno));
if(length(uf) == 0)
    return;
end
mask = false(size(im,1),size(im,2));
for j = 1:length(uf)
    load(sprintf('code/skin_based_detector/skinregions/%s',uf(j).name));
    mask = mask | mask2;
end


boxcount = 0;
newboxes = []; newboxes_area = []; newboxes_para = [];
[L, num] = bwlabel(mask);
for j = 1:num
    labelim = (L==j);
    regionprop = regionprops(labelim,'MajorAxisLength','MinorAxisLength','Extent');
    ratio = regionprop.MajorAxisLength / regionprop.MinorAxisLength;
    extent = regionprop.Extent;
    no_pixels = sum(labelim(:));
    if(no_pixels < 550)
        continue;
    end
    
    % check if it's a blob
    if((extent > 0.55) && (ratio <= 2.5)) %%0.7
        regionprop = regionprops(labelim,'BoundingBox');
        bb = regionprop.BoundingBox;
%        disp('Hand hypothesised');
        boxcount = boxcount + 1;
        newboxes(boxcount,:) = round(bb);
        newboxes_area(1,boxcount) = bb(3)*bb(4);
        newboxes_para(boxcount,:) = [extent ratio 0];
    else
        breakcount = 0;
        while(1==1)
            breakcount = breakcount + 1;
            
            %%% code for line fitting
            [H, theta, rho] = hough(labelim,'ThetaResolution',10,'RhoResolution',8);
            peaks = houghpeaks(H,100,'Threshold',max(H(:))*0.20);
            lines = houghlines(labelim,theta,rho,peaks,'FillGap',10,'MinLength',48); %50
            if(myIsField(lines,'point1'))
                score = zeros(length(lines),1);
                boundaryimg = bwperim(labelim);
                DT = bwdist(boundaryimg).*labelim;
                for k = 1:length(lines)
                    [score(k) newDT{k} box1{k} box2{k}]= rotateimage_and_line(DT,lines(k).theta,lines(k));
                end
                [maxval, maxindex] = max(score);
                
                if(maxval ~= 0)
                 %   li = lines(maxindex);
                    b1 = box1{maxindex};
                    b2 = box2{maxindex};
                    
                    %%%%
                    x1_1 = min([b1(1) b1(3) b1(5) b1(7)]);
                    y1_1 = min([b1(2) b1(4) b1(6) b1(8)]);
                    x2_1 = max([b1(1) b1(3) b1(5) b1(7)]);
                    y2_1 = max([b1(2) b1(4) b1(6) b1(8)]);
                    
                    x1_2 = min([b2(1) b2(3) b2(5) b2(7)]);
                    y1_2 = min([b2(2) b2(4) b2(6) b2(8)]);
                    x2_2 = max([b2(1) b2(3) b2(5) b2(7)]);
                    y2_2 = max([b2(2) b2(4) b2(6) b2(8)]);
                    
                    x1_1 = max(1,x1_1); y1_1 = max(1,y1_1); x1_2 = max(1,x1_2); y1_2 = max(1,y1_2);
                    x2_1 = min(x2_1, size(im,2)); y2_1 = min(y2_1, size(im,1)); x2_2 = min(x2_2, size(im,2)); y2_2 = min(y2_2, size(im,1));
                    
                    boxcount = boxcount + 1;
                    newboxes(boxcount,:) = round([x1_1 y1_1 (x2_1-x1_1+1) (y2_1-y1_1+1)]);
                    newboxes_area(1,boxcount) = newboxes(boxcount,3)*newboxes(boxcount,4);
                    newboxes_para(boxcount,:) = [extent ratio 1];
                    boxcount = boxcount + 1;
                    newboxes(boxcount,:) = round([x1_2 y1_2 (x2_2-x1_2+1) (y2_2-y1_2+1)]);
                    newboxes_area(1,boxcount) = newboxes(boxcount,3)*newboxes(boxcount,4);
                    newboxes_para(boxcount,:) = [extent ratio 1];
                    %%%%
                end
                labelim = labelim.*(newDT{maxindex}>0);
            else
                break;
            end
            if(breakcount > 10)
                break;
            end
        end
        %%%
    end
end
if(length(newboxes) > 0)
    % getting the corresponding bounding box from the hand shape
    % detector
    load(sprintf('code/pff_code/boxes/shape/%d.mat',imgno));
    boxes_I = boxes(:,1:4); boxes_I_withconfvalue = boxes(:,[1:4 end]);
    boxes_I(:,3) = (boxes_I(:,3)-boxes_I(:,1)+1);
    boxes_I(:,4) = (boxes_I(:,4)-boxes_I(:,2)+1);
    areaint = rectint(boxes_I,newboxes);
    newboxes_area = repmat(newboxes_area,[size(areaint,1) 1]);
    %%% to get area of union
    boxes_I_area = boxes_I(:,3).*boxes_I(:,4);
    boxes_I_area = repmat(boxes_I_area,[1, size(areaint,2)]);
    areauni = boxes_I_area + newboxes_area - areaint;
    overlapscore = areaint ./ areauni;
    %%%
    
    [maxvalue maxindex] = max(overlapscore);
    boxes_r_new = boxes_r(maxindex,:);
    clear boxes_new;
    for j = 1:length(maxindex)
        boxes_new(j,:) = boxes_I_withconfvalue(maxindex(j),:); %%%
    end
    
    I = nms(boxes_new,0.5);%%%
    boxes_new = boxes_new(I,:);%%%
    boxes_r_new = boxes_r_new(I,:);
    
    newboxes_para = newboxes_para(I,:);
    save(sprintf('code/skin_based_detector/boxes/%d.mat',imgno),'newboxes_para','boxes_new','boxes_r_new');
end


function [xnew,ynew] = rotatepoint(x,y,theta)
%%% function to rotate the point by an angle theta in anticlockwise direction
theta_radian = -theta*pi/180;
xnew = x*cos(theta_radian)-y*sin(theta_radian);
ynew = x*sin(theta_radian)+y*cos(theta_radian);

function [score, imori, box1, box2] = rotateimage_and_line(newdist,thetavalue,lines)
%%% function to rotate the image such that the line is
%%% vertical and then to hypothesise boxes at ends of the line

%%% swap point1 and point2 if point2(2) < point1(2)
if(lines.point2(2) < lines.point1(2))
    temp = lines.point1;
    lines.point1 = lines.point2;
    lines.point2 = temp;
end

height_image = size(newdist,1);
width_image = size(newdist,2);

padx = 0;
pady = 0;

if(height_image < width_image)
    pady = round((width_image-height_image)*0.5);
elseif(width_image < height_image)
    padx = round((height_image-width_image)*0.5);
end

newdist = padarray(newdist,[pady padx],0);
lines.point1(1) = lines.point1(1) + padx; lines.point1(2) = lines.point1(2) + pady;
lines.point2(1) = lines.point2(1) + padx; lines.point2(2) = lines.point2(2) + pady;

imr = imrotate(newdist, thetavalue, 'bilinear','crop');

center_of_image = [size(imr,2)/2 size(imr,1)/2];

centeredline.point1 = lines.point1 - center_of_image;
centeredline.point2 = lines.point2 - center_of_image;

[newpoint1(1) newpoint1(2)] = rotatepoint(centeredline.point1(1),centeredline.point1(2),thetavalue);

newpoint1 = newpoint1 + center_of_image;

[newpoint2(1) newpoint2(2)] = rotatepoint(centeredline.point2(1),centeredline.point2(2),thetavalue);

newpoint2 = newpoint2 + center_of_image;

newpoint1 = floor(newpoint1);
newpoint2 = floor(newpoint2);

BW = poly2mask([newpoint1(1) newpoint1(1)+1 newpoint1(1)+1 newpoint1(1) newpoint1(1)],[newpoint1(2) newpoint1(2) newpoint2(2) newpoint2(2) newpoint1(2)],size(newdist,1),size(newdist,2));

score = sum(sum(BW.*imr)); %/(newpoint2(2)-newpoint1(2));

if(score == 0)
    imori = zeros((size(newdist,1)-2*pady),(size(newdist,2)-2*padx));
    box1 = []; box2 = [];
    return;
end

if(newpoint2(2) > size(imr,1))
    newpoint2(2) = size(imr,1);
end

if(newpoint1(2) < 1)
    newpoint1(2) = 1;
end

maxwidthcount = 0;
for heightindex = newpoint1(2):newpoint2(2)
    widthcount = 0;
    for widthindex = newpoint1(1):-1:1
        if(imr(heightindex,widthindex) == 0)
            break;
        end
        imr(heightindex,widthindex) = 0;
        widthcount = widthcount + 1;
    end
    for widthindex = newpoint1(1)+1:size(imr,2)
        if(imr(heightindex,widthindex) == 0)
            break;
        end
        imr(heightindex,widthindex) = 0;
        widthcount = widthcount + 1;
    end
    if((heightindex - newpoint1(2)) < 50) %%%% to scan first 50 pixels only
        maxwidthcount = max(maxwidthcount, widthcount);
    end
end

width = round(1.25*maxwidthcount); %%1
width = max(width, 40); %%% putting constraint on width of the box
height = round(width*1.5);
b1 = [(newpoint1(1) - round(0.5*width)) (newpoint1(2)) (newpoint1(1) + round(0.5*width)) (newpoint1(2)+height)]; %[x1 y1 x2 y2];
b2 = [(newpoint2(1) - round(0.5*width)) (newpoint2(2)-height+1) (newpoint2(1) + round(0.5*width)) (newpoint2(2))];
b1(1) = b1(1) - center_of_image(1); b1(2) = b1(2) - center_of_image(2); b1(3) = b1(3) - center_of_image(1); b1(4) = b1(4) - center_of_image(2);
b2(1) = b2(1) - center_of_image(1); b2(2) = b2(2) - center_of_image(2); b2(3) = b2(3) - center_of_image(1); b2(4) = b2(4) - center_of_image(2);

[box1(1) box1(2)] = rotatepoint(b1(1),b1(2),-thetavalue);
[box1(3) box1(4)] = rotatepoint(b1(3),b1(2),-thetavalue);
[box1(5) box1(6)] = rotatepoint(b1(3),b1(4),-thetavalue);
[box1(7) box1(8)] = rotatepoint(b1(1),b1(4),-thetavalue);

[box2(1) box2(2)] = rotatepoint(b2(1),b2(2),-thetavalue);
[box2(3) box2(4)] = rotatepoint(b2(3),b2(2),-thetavalue);
[box2(5) box2(6)] = rotatepoint(b2(3),b2(4),-thetavalue);
[box2(7) box2(8)] = rotatepoint(b2(1),b2(4),-thetavalue);

box1(1) = box1(1) + center_of_image(1); box1(2) = box1(2) + center_of_image(2); box1(3) = box1(3) + center_of_image(1); box1(4) = box1(4) + center_of_image(2);
box1(5) = box1(5) + center_of_image(1); box1(6) = box1(6) + center_of_image(2); box1(7) = box1(7) + center_of_image(1); box1(8) = box1(8) + center_of_image(2);
box2(1) = box2(1) + center_of_image(1); box2(2) = box2(2) + center_of_image(2); box2(3) = box2(3) + center_of_image(1); box2(4) = box2(4) + center_of_image(2);
box2(5) = box2(5) + center_of_image(1); box2(6) = box2(6) + center_of_image(2); box2(7) = box2(7) + center_of_image(1); box2(8) = box2(8) + center_of_image(2);

box1 = box1 - [padx pady padx pady padx pady padx pady];
box2 = box2 - [padx pady padx pady padx pady padx pady];

imori = imrotate(imr,-thetavalue,'bilinear','crop');
imori = imori(pady+1:size(imori,1)-pady,padx+1:size(imori,2)-padx);
