function getSkinRegions(im, imnumber)
% This function saves the probabilistic map for skin pixels for a given
% image

% getting initial skin mask
skinprob = computeSkinProbability(double(im));
normaliseskinprob = normalise(skinprob) > 0.5;

imhsv = rgb2hsv(double(im));
imhsv(:,:,[1:2]) = imhsv(:,:,[1:2])*255;

load(sprintf('data/faceboxes/%d.mat',imnumber));


for i = 1:size(facebox,2)
    
    disp(sprintf('Detecting skin for facebox %d/%d', i, size(facebox,2)));
    
    facemask = getfacemask(im,facebox(:,i));
    
    [dist_fg, dist_bg] = compute_posterior(facemask,imhsv,normaliseskinprob);
    
    newmask = getposteriormask(dist_fg,dist_bg,facemask);
    
    [dist_fg, dist_bg] = compute_posterior(newmask,imhsv,normaliseskinprob);
    
    mask2 = getposteriormask(dist_fg,dist_bg,facemask);
    
    % saves one skin mask for every detected face
    save(sprintf('code/skin_based_detector/skinregions/%d_%d.mat',imnumber,i),'dist_fg','dist_bg','facemask','newmask','mask2');
end

function newmask = getposteriormask(dist_fg,dist_bg,facemask)
dist_fg = dist_fg - min(min(dist_fg));
dist_fg = dist_fg / max(max(dist_fg));
dist_bg = dist_bg - min(min(dist_bg));
dist_bg = dist_bg / max(max(dist_bg));
    
dist = dist_fg./(dist_fg+dist_bg);
dist = dist-min(min(dist));
dist = dist/max(max(dist));
    
I = isnan(dist);
Inew = find(I>0);
dist(Inew) = 0;

thresh = 0.5;

dist1 = bwareaopen(dist>thresh,350);
removed = (dist>thresh) - dist1;
dist = dist.*(1-removed);

count = 0;
while(1==1)
    count = count + 1;
    newdist = dist;
    for row = 2:size(newdist,1)-1
        for column = 2:size(newdist,2)-1
            datum_pixel = newdist(row,column);
            maxvalue = max(max(newdist(row-1:row+1,column-1:column+1)));
            if((datum_pixel > 0.50) & (datum_pixel <= 0.70) & (maxvalue > 0.70))  %0.4 %0.7 %0.7
                newdist(row,column) = maxvalue;
            end
        end
    end
    diff = newdist - dist;
    dist = newdist;
    if((sum(diff(:)) == 0) || (count == 20))
        break;
    end
end
thresh = 0.70; %%
newmask = bwareaopen(dist>thresh,350);


function [dist_fg, dist_bg] = compute_posterior(facemask,imhsv,skinprob)

BWparts = double(facemask);
windoww = 1; %25
windowh = 1; %15
BWhead = BWparts;
headhist = imageTrilinearHistVotingFast(imhsv,[24 4 4],BWhead); %[32 4 4]
headhist(1) = 0;
headhist = headhist/sum(headhist(:));
BWbg = double(1-BWhead);
bghist = imageTrilinearHistVotingFast(imhsv,[24 4 4],BWbg);
secondmax = max(bghist(2:end));
if(bghist(1) > secondmax)
    bghist(1) = secondmax;
end
bghist = bghist/sum(bghist(:));

for index1 = 1:1:floor(size(imhsv,1)/windowh)*windowh
    for index2 = 1:1:floor(size(imhsv,2)/windoww)*windoww
        imh = double(imhsv(index1:index1+windowh-1,index2:index2+windoww-1,:));
        mask = ones(size(imh,1), size(imh,2));
        imhist = imageTrilinearHistVotingFast(imh,[24 4 4],mask); %[32 4 4]
        imhist = imhist/max(imhist(:));
        dist_fg(index1:index1+windowh-1,index2:index2+windoww-1) = sum(min(imhist,headhist));
        dist_bg(index1:index1+windowh-1,index2:index2+windoww-1) = sum(min(imhist,bghist));
    end
end


function mask = getfacemask(im,facebox)
imhsv = rgb2hsv(double(im));
imhsv(:,:,[1:2]) = imhsv(:,:,[1:2])*255;

skinprob = computeSkinProbability(double(im)); % estimating skin pixels within the face bounding box using a global skin detector
normaliseskinprob = normalise(skinprob);

faceskinprob = zeros([size(im,1) size(im,2)]);
faceskinprob(facebox(3):facebox(4),facebox(1):facebox(2)) = 1;
faceskinprob = faceskinprob.*normaliseskinprob;
facesegment = faceskinprob(facebox(3):facebox(4),facebox(1):facebox(2));
meanvalue = mean(facesegment(:));
%mask = faceskinprob > meanvalue;

newskinprob = normaliseskinprob > meanvalue;

BWparts_rect = zeros([size(im,1) size(im,2)]);
BWparts_rect(facebox(3):facebox(4),facebox(1):facebox(2)) = 1;
BWparts = BWparts_rect.*newskinprob;

BWhead = BWparts;
BWhead = BWhead/max(BWhead(:));
headhist = imageTrilinearHistVotingFast(imhsv,[32 4 4],BWhead);

BWbg = 1-BWhead;             %%
tempbg = zeros([size(im,1) size(im,2)]);     %%

facebox_old = facebox;
facebox_height = (facebox(4)-facebox(3)+1); facebox_width = (facebox(2)-facebox(1)+1);
facebox(3) = facebox(3) - round(0.25*facebox_height); facebox(4) = facebox(4) + round(0.25*facebox_height);
facebox(1) = facebox(1) - round(0.25*facebox_width); facebox(2) = facebox(2) + round(0.25*facebox_width);
facebox = max(facebox,1); facebox(2) = min(facebox(2),size(im,2)); facebox(4) = min(facebox(4),size(im,1));

tempbg(facebox(3):facebox(4),facebox(1):facebox(2)) = 1;  %%
BWbg = BWbg.*tempbg;         %%

bgheadhist = imageTrilinearHistVotingFast(imhsv,[32 4 4],BWbg);
headhist = headhist/sum(headhist(:));
bgheadhist = bgheadhist/sum(bgheadhist(:));
dist_fg = zeros([size(im,1) size(im,2)]);
dist_bg = zeros([size(im,1) size(im,2)]);
for index1 = facebox_old(3):facebox_old(4)
    for index2 = facebox_old(1):facebox_old(2)
        imh = double(imhsv(index1,index2,:));
        mask = 1;
        imhist = imageTrilinearHistVotingFast(imh,[32 4 4],mask);
        imhist = imhist/max(imhist(:));
        dist_fg(index1,index2) = sum(min(imhist,headhist));
        dist_bg(index1,index2) = sum(min(imhist,bgheadhist));
    end
end

dist = dist_fg./(dist_fg+1*dist_bg);

dist = dist-min(min(dist));
dist = dist/max(max(dist));

I = find(BWparts(:) > 0);
meanvalue_new = mean(dist(I));
mask = dist>meanvalue_new;


