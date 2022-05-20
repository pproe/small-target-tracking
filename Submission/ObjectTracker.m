classdef ObjectTracker
    %   Object Tracker      Performs object tracking functionality

    properties
        dataLoader      % DataLoader object for loading images
        interval        % Number of frames to be considered
        gtRegions       % Ground Truth Regions from VISO dataset

    end

    properties (Constant)
        % Morphological Cue Thresholds [min, max]
        extent_th = [0, 0.7];
        eccentricity_th = [0.5, 1];
        majoraxis_th = [0, 20];
        area_th = [10, 70];
    end

    methods
        function obj = ObjectTracker(dataLoader)
            % Constructor for Object Tracker
            %       Must be provided with a valid dataLoader class for
            %       access to images & data files

            obj.dataLoader = dataLoader;
            obj.interval = dataLoader.interval;
            obj.gtRegions = dataLoader.getRegions();
            
        end

        function r = trackObjects(obj)
            % Detects and Tracks objects

            % Primary function for operation of the tracking algorithm

            % Performs Candidate Detection and Tracking for all frames within frame
            % range

            % Input: for each frame index n from 1 to N-1, this step takes as input a binary image representing
            % candidate small objects, as well as the state of the tracker (the Kalman state vectors for each tracks,
            % and the corresponding covariances estimates) from the previous frame.

            % Ouput: Sequence of images to display all tracked objects

            % Populate outlier pixels
            outliers{obj.interval - 1} = [];
            for i = 1:(obj.interval - 1)

                % Load images to find outlier pixels
                thisImage = obj.dataLoader.loadImage(i);
                nextImage = obj.dataLoader.loadImage(i+1);

                outliers{i} = obj.extractOutlier(thisImage, nextImage);
            end

            % Calculate the output of the bit-and operation for all frames
            frameBinary{obj.interval - 2} = [];
            for i = 1:(obj.interval - 2)
                frameBinary{i} = bitand(outliers{i}, outliers{i+1});
            end

            % Perform Region Growing
            afterRegionGrowing{obj.interval - 2} = [];
            for i = 1:(obj.interval - 2)
                thisFrame = obj.dataLoader.loadImage(i+2);
                afterRegionGrowing{i} = obj.regionGrowing(frameBinary{i}, thisFrame);
            end

            % Filter Morphological CuesafterRegionGrowing{obj.interval - 2} = [];
            regions{obj.interval - 2} = [];
            for i = 1:(obj.interval - 2)
                regions{i} = obj.morphologicalCues(afterRegionGrowing{i});
            end

            % trackStates = [];
            % get tracking information for each image
%             ta = TrackerAlgorithm();
%             for i=1:(obj.interval - 2)
%                 trackerArray = [];
%                 if i>1 
%                     trackerArray = trackStates(i-1);
%                 end
% 
%                 trackStates(i) = ta.trackingAlgorithm(regions{i}, trackerArray);
%             end 

            % Process Output

            imageSequence = {};

            % Load all images
            for i=2:(obj.interval - 2)
                fh = figure('Visible','Off');
                image = obj.dataLoader.loadImage(i);
                imshow(image, 'Border', 'tight');

                for j=1:(size(regions{i-1}, 1))
                    hold on
                    rectangle('Position', regions{i-1}(j, :), 'EdgeColor','r');
                end
                
                frm = getframe(fh);

                imageSequence{i-1} = frm;
            end

            % Return Output
            r = cell2mat(imageSequence);
            
        end

        function r = extractOutlier(~, frame, nextFrame)
            % Detection process to extract outlier pixels of two frames

            % a) Inter-Frames Difference

            diff = abs(nextFrame - frame);
            mean_diff = mean(diff, 'all');

            % b) Thresholding
            th = -log(0.05) * mean_diff;
            outlier = diff > th;

            r = outlier;
        end

        function r = regionGrowing(~, frameBinary, frame)

            % Extract blobs from binary image
            blob = vision.BlobAnalysis('MinimumBlobArea',4,'MaximumCount', 200);
            [~, centroid, ~] = blob(frameBinary);
            centroid = int16(centroid);
            output = frameBinary;

            for blobIdx = 1:size(centroid,1)  % Repeat for each blob detected
                mask=zeros(11,11); % Create 11x11 array of 0

                % Create separate 11x11 2d array to store pixel
                % intensity of pixels surrounding centroid in 11x11
                for ii=1:11         % Repeat block for each pixel in
                    for jj=1:11     % 11x11 square around centroid

                        if (centroid(blobIdx,2)+(ii-6))>=1 ...                            % If pixel y value is greater than 1
                                && (centroid(blobIdx,2)+(ii-6))<=size(frame,1) ...   % And less than the height of image;
                                && (centroid(blobIdx,1)+(jj-6))>=1 ...                        % And pixel x value is greater than 1
                                && (centroid(blobIdx,1)+(jj-6))<=size(frame,2)       % And less than the width of image;
                            % x,y coordinate is
                            % actually the opposite for some reason
                            % get the grayscale values within the window

                            mask(ii,jj)=frame(centroid(blobIdx,2)+(ii-6), ...
                                centroid(blobIdx,1)+(jj-6));     % Add pixel to the mask
                        end
                    end
                end

                mask_binary=zeros(11,11);

                % Iterate over pixels in 11x11 block and set binary
                % mask values
                for ii=1:11
                    for jj=1:11
                        if (centroid(blobIdx,2) + (ii-6)) >= 1 ...
                                && (centroid(blobIdx,2) + (ii-6)) <= size(frameBinary,1) ...
                                && (centroid(blobIdx,1) + (jj-6)) >= 1 ...
                                && (centroid(blobIdx,1) + (jj-6)) <= size(frameBinary,2)

                            mask_binary(ii,jj) = frameBinary(centroid(blobIdx,2) + (ii-6), centroid(blobIdx,1) + (jj-6));
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

                % grow the region of object clusters in and_put images
                % I have tested with examples, it seems the growing
                % region of one cluster is unexpectedly large, I suspect that is because the th region computed above is too wide
                % in my understanding the th region should be around [200 256]

                for ii=1:11
                    for jj=1:11
                        if (centroid(blobIdx,2)+(ii-6))>=1 ...
                                && (centroid(blobIdx,2) + (ii-6)) <= size(frame,1) ...
                                && (centroid(blobIdx,1) + (jj-6)) >= 1 ...
                                && (centroid(blobIdx,1) + (jj-6)) <= size(frame,2)

                            % If pixel is within confidence interval
                            % and not included in detection mask
                            if mask(ii,jj) > th(1,1) && mask(ii,jj) < th(1,2)

                                % Set mask value to 1
                                output(centroid(blobIdx,2)+(ii-6), centroid(blobIdx,1)+(jj-6)) = 1;
                            end
                        end
                    end
                end
            end

            r = output;
        end

        function r = morphologicalCues(~, frameBinary)
            % Perform Filtering of Morphological Cues

            blob=vision.BlobAnalysis('MinimumBlobArea',4,'MaximumCount',200, ...
                'MajorAxisLengthOutputPort', true, 'EccentricityOutputPort', true, ...
                'ExtentOutputPort', true);

            [area,centroid,bbox, majoraxis, eccentricity, EXTENT] = blob(frameBinary);

            regions = [];

            % If cues are within thresholds, add to output regions
            for j = 1:size(centroid, 1)
                if area(j) >= ObjectTracker.area_th(1) && area(j) <= ObjectTracker.area_th(2) ...
                        && EXTENT(j) >= ObjectTracker.extent_th(1) && EXTENT(j) <= ObjectTracker.extent_th(2) ...
                        && majoraxis(j) >= ObjectTracker.majoraxis_th(1) && majoraxis(j) <= ObjectTracker.majoraxis_th(2) ...
                        && eccentricity(j) >= ObjectTracker.eccentricity_th(1) && eccentricity(j) <= ObjectTracker.eccentricity_th(2)

                    regions = [regions; bbox(j, :)];
                end
            end

            r = regions;
        end
    end
end





