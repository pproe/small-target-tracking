classdef DataLoader
   
    
    properties 
    type          % 'car', 'plane'.. input as strings
    scene         % 001, 002...
    candidate     % gt file info
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
    end
    
    methods
        
        function obj = DataLoader(type,scene,frame_range)
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
            obj.candidate=csvread(f1);
            
            
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
                    
                    mask_mean = mean(mask(cluster_locations),'all');         % Find mean of pixel values in 11x11 block
                    mask_std = std(mask(cluster_locations), 1, 'all');       % Find STD of pixel values in 11x11 block

                    th= norminv([0.005 0.995],mask_mean,mask_std);           % need to have a look
                    th=uint8(th);
                    
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
            mc_hblob_area = {};
            mc_hblob_centroid = {};
            mc_hblob_bbox = {};
            mc_hblob_majoraxis = {};
            mc_hblob_eccentricity = {};
            mc_hblob_extent = {};

            % Get area, centroid and bounding box info from binary image
            for i=1:(obj.interval-2)
                [area,centroid,bbox, majoraxis, eccentricity, EXTENT] = mc_hblob(obj.and_output{i});
                mc_hblob_area{i} = area;
                mc_hblob_centroid{i} = int16(centroid);
                mc_hblob_bbox{i} = bbox;
                mc_hblob_majoraxis{i} = majoraxis;
                mc_hblob_eccentricity{i} = eccentricity;
                mc_hblob_extent{i} = EXTENT;
            end

            % Plot values for blobs in interval 5

            figure('Name', 'Extent');
            ex_hist = histogram(mc_hblob_extent{5})
            title('Extent')
            figure('Name', 'Eccentricity');
            ec_hist = histogram(mc_hblob_eccentricity{5})
            title('Eccentricity')
            figure('Name', 'Major Axis Length')
            maj_hist = histogram(mc_hblob_majoraxis{5})
            title('Major Axis Length')
            figure('Name', 'Area');
            area_hist = histogram(mc_hblob_area{5})
            title('Area')



        end     
    end
end

