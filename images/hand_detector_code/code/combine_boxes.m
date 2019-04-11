function [score_hand score_arm para_skin boxes boxtype] = combine_boxes(boxes_hand, boxes_arm, boxes_skin, boxes_skin_para, boxes_hand_all, boxes_arm_all,angle_hand_all,angle_arm_all,angle_hand,angle_arm,angle_skin)
% This function combines the hypotheses from shape, context and skin
% colour

boxes_hand = boxes_hand(:,[1:4 end]);
boxes_arm = boxes_arm(:,[1:4 end]);
boxes_skin = boxes_skin(:,[1:4 end]);
boxes_hand_all = boxes_hand_all(:,[1:4 end]);
boxes_arm_all = boxes_arm_all(:,[1:4 end]);

overlap = 0.5; %0.5
thresh_hand = -1.6302;
thresh_arm = -1.3241;
amargin = 90;

score_hand = []; score_arm = []; para_skin = [];
count = 0;

used_arm = zeros(size(boxes_arm,1),1);
used_skin = zeros(size(boxes_skin,1),1);

x1_hand = boxes_hand(:,1);
y1_hand = boxes_hand(:,2);
x2_hand = boxes_hand(:,3);
y2_hand = boxes_hand(:,4);
s_hand = boxes_hand(:,end);
w_hand = (x2_hand-x1_hand+1);
h_hand = (y2_hand-y1_hand+1);
area_hand = (x2_hand-x1_hand+1) .* (y2_hand-y1_hand+1);
rect_hand = [x1_hand y1_hand w_hand h_hand];

x1_hand_all = boxes_hand_all(:,1);
y1_hand_all = boxes_hand_all(:,2);
x2_hand_all = boxes_hand_all(:,3);
y2_hand_all = boxes_hand_all(:,4);
s_hand_all = boxes_hand_all(:,end);
w_hand_all = (x2_hand_all-x1_hand_all+1);
h_hand_all = (y2_hand_all-y1_hand_all+1);
area_hand_all = (x2_hand_all-x1_hand_all+1) .* (y2_hand_all-y1_hand_all+1);
rect_hand_all = [x1_hand_all y1_hand_all w_hand_all h_hand_all];

x1_arm = boxes_arm(:,1);
y1_arm = boxes_arm(:,2);
x2_arm = boxes_arm(:,3);
y2_arm = boxes_arm(:,4);
s_arm = boxes_arm(:,end);
w_arm = (x2_arm-x1_arm+1);
h_arm = (y2_arm-y1_arm+1);
area_arm = (x2_arm-x1_arm+1) .* (y2_arm-y1_arm+1);
rect_arm = [x1_arm y1_arm w_arm h_arm];

x1_arm_all = boxes_arm_all(:,1);
y1_arm_all = boxes_arm_all(:,2);
x2_arm_all = boxes_arm_all(:,3);
y2_arm_all = boxes_arm_all(:,4);
s_arm_all = boxes_arm_all(:,end);
w_arm_all = (x2_arm_all-x1_arm_all+1);
h_arm_all = (y2_arm_all-y1_arm_all+1);
area_arm_all = (x2_arm_all-x1_arm_all+1) .* (y2_arm_all-y1_arm_all+1);
rect_arm_all = [x1_arm_all y1_arm_all w_arm_all h_arm_all];

x1_skin = boxes_skin(:,1);
y1_skin = boxes_skin(:,2);
x2_skin = boxes_skin(:,3);
y2_skin = boxes_skin(:,4);
s_skin = boxes_skin(:,end);
w_skin = (x2_skin-x1_skin+1);
h_skin = (y2_skin-y1_skin+1);
area_skin = (x2_skin-x1_skin+1) .* (y2_skin-y1_skin+1);
rect_skin = [x1_skin y1_skin w_skin h_skin];

extent_skin = boxes_skin_para(:,1);
ratio_skin = boxes_skin_para(:,2);
type_skin = boxes_skin_para(:,3);

areaint_hand_arm = rectint(rect_hand,rect_arm);
area_hand_arm = repmat(area_hand,[1, size(areaint_hand_arm,2)]);
area_arm_hand = repmat(area_arm',[size(areaint_hand_arm,1) 1]);
areauni_hand_arm = area_hand_arm + area_arm_hand - areaint_hand_arm;
ovscore_hand_arm = areaint_hand_arm ./ areauni_hand_arm;

areaint_hand_skin = rectint(rect_hand,rect_skin);
area_hand_skin = repmat(area_hand,[1, size(areaint_hand_skin,2)]);
area_skin_hand = repmat(area_skin',[size(areaint_hand_skin,1) 1]);
areauni_hand_skin = area_hand_skin + area_skin_hand - areaint_hand_skin;
ovscore_hand_skin = areaint_hand_skin ./ areauni_hand_skin;
if(size(ovscore_hand_skin,2) > 1)
    [maxval_hand_skin maxind_hand_skin] = max(ovscore_hand_skin');
else
    maxval_hand_skin = ovscore_hand_skin;
    maxind_hand_skin = ones(size(maxval_hand_skin));
end

for i = 1:size(ovscore_hand_arm,1)
    count = count + 1;
    score_hand(count) = s_hand(i);
    boxes(count,:) = boxes_hand(i,:);
    boxtype(count) = 1;
    
    angle_h = angle_hand(i);
    lb = angle_h - amargin;
    ub = angle_h + amargin;
    if(lb < -180)
       lb = lb + 360;
    end
    if(ub > 180)
       ub = ub - 360;
    end
    if(ub > lb)
       I_angle = find((angle_arm > lb) & (angle_arm < ub));
    else
       I_angle = find((angle_arm > lb) | (angle_arm < ub));
    end    
    I = find(ovscore_hand_arm(i,I_angle) >= overlap);
    I = I_angle(I);
    
    %I = find(ovscore_hand_arm(i,:) >= overlap);
    
    if(length(I) > 0)
        [maxvalue I_new] = max(s_arm(I)); %%% for maxpooling
        score_arm(count) = s_arm(I(I_new));
        used_arm(I(I_new)) = 1;
    else
        %score_arm(count) = thresh_arm;
        areaint_hand_arm_all = rectint(rect_hand(i,:), rect_arm_all);
        area_hand_arm_all = repmat(area_hand(i),[1, size(areaint_hand_arm_all,2)]);
        area_arm_all_hand = area_arm_all';
        areauni_hand_arm_all = area_hand_arm_all + area_arm_all_hand - areaint_hand_arm_all;
        ovscore_hand_arm_all = areaint_hand_arm_all ./ areauni_hand_arm_all;
        
        if(ub > lb)
            I_angle = find((angle_arm_all > lb) & (angle_arm_all < ub));
        else
            I_angle = find((angle_arm_all > lb) | (angle_arm_all < ub));
        end
        I = find(ovscore_hand_arm_all(I_angle) >= overlap*1.8);
        I = I_angle(I);
        
        %I = find(ovscore_hand_arm_all >= overlap*1.5);
        if(length(I) > 0)
            [maxvalue I_new] = max(s_arm_all(I));
            score_arm(count) = maxvalue;
        else
            score_arm(count) = thresh_arm;
        end
    end
    if((length(maxval_hand_skin) > 0) && (maxval_hand_skin(i) > 0.7))
        para_skin(count,:) = [1 extent_skin(maxind_hand_skin(i)) ratio_skin(maxind_hand_skin(i)) type_skin(maxind_hand_skin(i))];
        used_skin(maxind_hand_skin(i)) = 1;
    else
        para_skin(count,:) = [0 0 0 0];
    end
end

areaint_skin_arm = rectint(rect_skin,rect_arm);
area_skin_arm = repmat(area_skin,[1, size(areaint_skin_arm,2)]);
area_arm_skin = repmat(area_arm',[size(areaint_skin_arm,1) 1]);
areauni_skin_arm = area_skin_arm + area_arm_skin - areaint_skin_arm;
ovscore_skin_arm = areaint_skin_arm ./ areauni_skin_arm;

for i = 1:length(used_skin)
    if(used_skin(i))
    
    else
        count = count + 1;
        score_hand(count) = s_skin(i);
        boxes(count,:) = boxes_skin(i,:);
        boxtype(count) = 3;
        para_skin(count,:) = [1 extent_skin(i) ratio_skin(i) type_skin(i)];
        
        angle_s = angle_skin(i);
        lb = angle_s - amargin;
        ub = angle_s + amargin;
        if(lb < -180)
            lb = lb + 360;
        end
        if(ub > 180)
            ub = ub - 360;
        end
        if(ub > lb)
            I_angle = find((angle_arm > lb) & (angle_arm < ub));
        else
            I_angle = find((angle_arm > lb) | (angle_arm < ub));
        end
        I = find(ovscore_skin_arm(i,I_angle) >= overlap);
        I = I_angle(I);
        
        %I = find(ovscore_skin_arm(i,:) >= overlap);
        if(length(I) > 0)
            [maxvalue I_new] = max(s_arm(I)); %%% for maxpooling
            score_arm(count) = s_arm(I(I_new));
            used_arm(I(I_new)) = 1;
        else
            %score_arm(count) = thresh_arm;
            areaint_skin_arm_all = rectint(rect_skin(i,:), rect_arm_all);
            area_skin_arm_all = repmat(area_skin(i),[1, size(areaint_skin_arm_all,2)]);
            area_arm_all_skin = area_arm_all';
            areauni_skin_arm_all = area_skin_arm_all + area_arm_all_skin - areaint_skin_arm_all;
            ovscore_skin_arm_all = areaint_skin_arm_all ./ areauni_skin_arm_all;
            
            if(ub > lb)
                I_angle = find((angle_arm_all > lb) & (angle_arm_all < ub));
            else
                I_angle = find((angle_arm_all > lb) | (angle_arm_all < ub));
            end
            I = find(ovscore_skin_arm_all(I_angle) >= overlap*1.8);
            I = I_angle(I);
            
            if(length(I) > 0)
                [maxvalue I_new] = max(s_arm_all(I));
                score_arm(count) = maxvalue;
            else
                score_arm(count) = thresh_arm;
            end
        end
    end
end

for i = 1:length(used_arm)
    if(used_arm(i))
        
    else
        count = count + 1;
        %score_hand(count) = thresh_hand;
        areaint_arm_hand_all = rectint(rect_arm(i,:), rect_hand_all);
        area_arm_hand_all = repmat(area_arm(i),[1, size(areaint_arm_hand_all,2)]);
        area_hand_all_arm = area_hand_all';
        areauni_arm_hand_all = area_arm_hand_all + area_hand_all_arm - areaint_arm_hand_all;
        ovscore_arm_hand_all = areaint_arm_hand_all ./ areauni_arm_hand_all;
        
        angle_a = angle_arm(i);
        lb = angle_a - amargin;
        ub = angle_a + amargin;
        if(lb < -180)
            lb = lb + 360;
        end
        if(ub > 180)
            ub = ub - 360;
        end
        if(ub > lb)
            I_angle = find((angle_hand_all > lb) & (angle_hand_all < ub));
        else
            I_angle = find((angle_hand_all > lb) | (angle_hand_all < ub));
        end
        I = find(ovscore_arm_hand_all(I_angle) >= overlap*1.8);
        I = I_angle(I);
        
       % I = find(ovscore_arm_hand_all >= overlap*1.5);
        if(length(I) > 0)
            [maxvalue I_new] = max(s_hand_all(I));
            score_hand(count) = maxvalue;
        else
            score_hand(count) = thresh_hand;
        end
        score_arm(count) = s_arm(i);
        boxes(count,:) = boxes_arm(i,:);
        boxtype(count) = 2;
        para_skin(count,:) = [0 0 0 0];
    end
end
  