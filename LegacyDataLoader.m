classdef LegacyDataLoader
   
    
    properties 
    type          % 'car', 'plane'.. input as strings
    scene         % 001, 002...
    gt_regions     % gt regions ([x y w h] shape)
    image         % image data
    frame_range   % format [2, 5]
    interval
    
    % Candidate small objects detection
    diff          % diff of frame pixels
    mean_diff     % mean of diff in frame pixels
    th
    outlier 
    and_output
    before_growing
    
    % Candidate match discrimination
    
    hblob_area
    hblob_centroid
    hblob_bbox

    output_regions % each line has shape [x y w h]
    track_states %holds an array of tracker objects per image
    end
    
    methods
        
        function obj = LegacyDataLoader(type,scene,frame_range)
            % Construct an instance of this class
            % e.g. car05_7_11=DataLoader('car', 5, [7, 11]);
            obj.type=type;
            b=sprintf('%03d',scene);
            obj.scene=b;
            obj.frame_range=frame_range;
            obj.interval=obj.frame_range(1,2)-obj.frame_range(1,1)+1;
            obj.image={};
            number=obj.frame_range(1,1);
            for i=1:obj.interval
                im_name=append(sprintf('%06d',number),'.jpg');
                f2=fullfile('VISO', 'mot',obj.type,obj.scene,'img',im_name);
                obj.image{i}=rgb2gray(imread(f2));
                number=number+1;
            end
            f1=fullfile('VISO','mot',obj.type,obj.scene,'gt','gt.txt');
            candidate_data = readmatrix(f1);

            obj.gt_regions = {};

            % Setup Iterators for loop
            lastframe = 1;
            frame_regions = [];
            i=1;

            while i <= size(candidate_data, 1)

                frame = candidate_data(i, 1);
                region = candidate_data(i, 3:6);
                i = i + 1;

                if(frame == lastframe)
                    frame_regions = [frame_regions; region];
                else
                    obj.gt_regions{lastframe} = frame_regions;
                    frame_regions = region;
                    lastframe = frame;
                end        
            end
            
            % Add final region 
            obj.gt_regions{lastframe} = frame_regions;
            
            
            % Candidate small objects detection
         
            obj.diff={};
            for i=1:(obj.interval-1)
                obj.diff{i}=abs(obj.image{i+1}-obj.image{i});
            end
            
            obj.mean_diff=[];
            for i=1:(obj.interval-1)
                obj.mean_diff(i)=mean(obj.diff{i},'all');
            end
            
            obj.th=[];
            for i=1:(obj.interval-1)
                obj.th(i)= -log(0.05)* obj.mean_diff(i);
            end
            
            obj.outlier={};
            for i=1:(obj.interval-1)
                obj.outlier{i}= obj.diff{i}>obj.th(i);
            end 
            
            % e.g. imshow(car05_7_11.and_output{2}) to see the output
            obj.and_output={};
            for i=1:(obj.interval-2)
                obj.and_output{i}=bitand(obj.outlier{i}, obj.outlier{i+1});
            end

            obj.before_growing = obj.and_output;

            %% Candidate match discrimination

            %% Region Growing
            
            hblob=vision.BlobAnalysis('MinimumBlobArea',4,'MaximumCount',200);
            obj.hblob_area={};
            obj.hblob_centroid={};
            obj.hblob_bbox={};

            % Get area, centroid and bounding box info from binary image
            for i=1:(obj.interval-2)
                [area,centroid,bbox] = hblob(obj.and_output{i});
                obj.hblob_area{i}=area;
                obj.hblob_centroid{i}=int16(centroid);
                obj.hblob_bbox{i}=bbox;
            end
            % shape=insertShape(car05_7_11.image{2},'rectangle',bbox, 'Linewidth',10);
            
            for a=1:(obj.interval-2) % Repeat for each image
                for b=1:size(obj.hblob_centroid{a},1)  % Repeat for each blob detected
                    mask=zeros(11,11); % Create 11x11 array of 0
                    
                    % Create separate 11x11 2d array to store pixel
                    % intensity of pixels surrounding centroid in 11x11
                    for ii=1:11         % Repeat block for each pixel in 
                        for jj=1:11     % 11x11 square around centroid

                               if (obj.hblob_centroid{a}(b,2)+(ii-6))>=1 ...                            % If pixel y value is greater than 1
                                   && (obj.hblob_centroid{a}(b,2)+(ii-6))<=size(obj.image{a+1},1) ...   % And less than the height of image;
                                   && (obj.hblob_centroid{a}(b,1)+(jj-6))>=1 ...                        % And pixel x value is greater than 1
                                   && (obj.hblob_centroid{a}(b,1)+(jj-6))<=size(obj.image{a+1},2)       % And less than the width of image;
                                  % x,y coordinate is
                                  % actually the opposite for some reason
                                  % get the grayscale values within the window
                   
                                        mask(ii,jj)=obj.image{a+2}(obj.hblob_centroid{a}(b,2)+(ii-6), ...
                                            obj.hblob_centroid{a}(b,1)+(jj-6));     % Add pixel to the mask 
                               end
                        end
                    end

                    mask_binary=zeros(11,11);

                    % Iterate over pixels in 11x11 block and set binary
                    % mask values
                    for ii=1:11
                        for jj=1:11
                             if (obj.hblob_centroid{a}(b,2) + (ii-6)) >= 1 ...
                                 && (obj.hblob_centroid{a}(b,2) + (ii-6)) <= size(obj.image{a+1},1) ...
                                 && (obj.hblob_centroid{a}(b,1) + (jj-6)) >= 1 ... 
                                 && (obj.hblob_centroid{a}(b,1) + (jj-6)) <= size(obj.image{a+1},2)

                                 mask_binary(ii,jj) = obj.and_output{a}(obj.hblob_centroid{a}(b,2) + (ii-6), obj.hblob_centroid{a}(b,1) + (jj-6));
                             end
                        end
                    end
                    
                    % Mask values to only include cluster values when
                    % calculating mean and std
                    cluster_locations = mask_binary == 1;

                    masked_vals = mask(cluster_locations);
                    
                    mask_mean = mean(masked_vals,'all');       % Find mean of pixel values in 11x11 block
                    mask_std = std(masked_vals, 1, 'all');       % Find STD of pixel values in 11x11 block
                    mask_population_std = mask_std/sqrt(size(masked_vals, 1)); % Get standard deviation of total population

                    th = norminv([0.005 0.995],mask_mean,mask_population_std);           % need to have a look
                    th = uint8(th);
                    
                    %if(~isnan(cluster_locations) && a == 7)
                        % mask(cluster_locations)
                       % mask_mean, mask_std
                        % cluster_locations
                       % th
                    %end
                    
                    % grow the region of object clusters in and_put images
                    % I have tested with examples, it seems the growing
                    % region of one cluster is unexpectedly large, I suspect that is because the th region computed above is too wide
                    % in my understanding the th region should be around [200 256]
                    for ii=1:11
                        for jj=1:11
                            if (obj.hblob_centroid{a}(b,2)+(ii-6))>=1 ...
                                && (obj.hblob_centroid{a}(b,2) + (ii-6)) <= size(obj.image{a+1},1) ...
                                && (obj.hblob_centroid{a}(b,1) + (jj-6)) >= 1 ...
                                && (obj.hblob_centroid{a}(b,1) + (jj-6)) <= size(obj.image{a+1},2)
                                
                                % If pixel is within confidence interval
                                % and not included in detection mask
                                if mask(ii,jj) > th(1,1) ...
                                    && mask(ii,jj) < th(1,2)
                                    
                                    % Set mask value to 1
                                    obj.and_output{a}(obj.hblob_centroid{a}(b,2)+(ii-6), obj.hblob_centroid{a}(b,1)+(jj-6)) = 1;
                                end
                            end
                        end
                    end
                end 
            end

            %% Morphological Cues
            % Recalculate Blobs after region growing step

            mc_hblob=vision.BlobAnalysis('MinimumBlobArea',4,'MaximumCount',200, ...
                'MajorAxisLengthOutputPort', true, 'EccentricityOutputPort', true, ...
                'ExtentOutputPort', true);

            obj.output_regions = {};

            extent_th = [0, 0.7];
            eccentricity_th = [0.5, 1];
            majoraxis_th = [0, 20];
            area_th = [10, 70];

            % Get area, centroid and bounding box info from binary image
            for i = 1:(obj.interval-2)
                [area,centroid,bbox, majoraxis, eccentricity, EXTENT] = mc_hblob(obj.and_output{i});

                regions = [];
                
                % If cues are within thresholds, add to output regions
                for j = 1:size(centroid, 1)
                    if area(j) >= area_th(1) && area(j) <= area_th(2) ...
                        && EXTENT(j) >= extent_th(1) && EXTENT(j) <= extent_th(2) ...
                        && majoraxis(j) >= majoraxis_th(1) && majoraxis(j) <= majoraxis_th(2) ...
                        && eccentricity(j) >= eccentricity_th(1) && eccentricity(j) <= eccentricity_th(2)
                        
                        regions = [regions; bbox(j, :)];
                    end
                end
                obj.output_regions{i} = regions;
            end

            obj.track_states = [];
            %get tracking information 
            for i=1:(obj.interval -2)
                trackerArray = [];
                if i>1 
                    trackerArray = obj.track_states(i-1);
                end
                obj.track_states(i) = trackingAlgorithm(obj.output_regions{i},trackerArray);
            end





            % Plot values for blobs in interval 5

%             figure('Name', 'Extent');
%             ex_hist = histogram(mc_hblob_extent{5})
%             title('Extent')
%             figure('Name', 'Eccentricity');
%             ec_hist = histogram(mc_hblob_eccentricity{5})
%             title('Eccentricity')
%             figure('Name', 'Major Axis Length')
%             maj_hist = histogram(mc_hblob_majoraxis{5})
%             title('Major Axis Length')
%             figure('Name', 'Area');
%             area_hist = histogram(mc_hblob_area{5})
%             title('Area')
        end     
    end
end

