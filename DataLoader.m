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
                f2=fullfile('mot',obj.type,obj.scene,'img',im_name);
                obj.image{i}=rgb2gray(imread(f2));
                number=number+1;
            end
            f1=fullfile('mot',obj.type,obj.scene,'gt','gt.txt');
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
                
            % Candidate match discrimination
            
            hblob=vision.BlobAnalysis('MinimumBlobArea',4,'MaximumCount',200);
            obj.hblob_area={};
            obj.hblob_centroid={};
            obj.hblob_bbox={};
            for i=1:(obj.interval-2)
                [area,centroid,bbox] = hblob(obj.and_output{i});
                obj.hblob_area{i}=area;
                obj.hblob_centroid{i}=int16(centroid);
                obj.hblob_bbox{i}=bbox;
            end
      %      shape=insertShape(car05_7_11.image{2},'rectangle',bbox, 'Linewidth',10);
            
            for a=1:(obj.interval-2)  % and_output image
                for b=1:size(obj.hblob_centroid{a},1)  % clusters inside
                    mask=zeros(11,11);
                    for ii=1:11
                        for jj=1:11
                               if (obj.hblob_centroid{a}(b,2)+(ii-6))>=1 && (obj.hblob_centroid{a}(b,2)+(ii-6))<=size(obj.image{a+1},1) && (obj.hblob_centroid{a}(b,1)+(jj-6))>=1 && (obj.hblob_centroid{a}(b,1)+(jj-6))<=size(obj.image{a+1},2)
                                  % x,y coordination is
                                  % actually the opposite for some reason
                                  % get the grayscale values within the window
                   
                                        mask(ii,jj)=obj.image{a+1}(obj.hblob_centroid{a}(b,2)+(ii-6), obj.hblob_centroid{a}(b,1)+(jj-6));
                               end
                        end
                    end
                    mask_mean=mean(mask,'all');
                    mask_std= std(mask,1, 'all');
                    th= norminv([0.005 0.995],mask_mean,mask_std); % need to have a look
                    th=int8(th);
                    
                    mask_binary=zeros(11,11);
                    for ii=1:11
                        for jj=1:1
                             if (obj.hblob_centroid{a}(b,2)+(ii-6))>=1 && (obj.hblob_centroid{a}(b,2)+(ii-6))<=size(obj.image{a+1},1) && (obj.hblob_centroid{a}(b,1)+(jj-6))>=1 && (obj.hblob_centroid{a}(b,1)+(jj-6))<=size(obj.image{a+1},2)
                                 mask_binary(ii,jj)=obj.and_output{a}(obj.hblob_centroid{a}(b,2)+(ii-6), obj.hblob_centroid{a}(b,1)+(jj-6));
                             end
                        end
                    end
                    
                    % grow the region of object clusters in and_put images
                    % I have tested with examples, it seems the growing
                    % region of one cluster is unexpectedly large, I suspect that is because the th region computed above is too wide
                    % in my understanding the th region should be around [200 256]
                    for ii=1:11
                        for jj=1:11
                            if (obj.hblob_centroid{a}(b,2)+(ii-6))>=1 && (obj.hblob_centroid{a}(b,2)+(ii-6))<=size(obj.image{a+1},1) && (obj.hblob_centroid{a}(b,1)+(jj-6))>=1 && (obj.hblob_centroid{a}(b,1)+(jj-6))<=size(obj.image{a+1},2)
                                if mask(ii,jj)>= th(1,1) && mask(ii,jj)<=th(1,2) && mask_binary(ii,jj)~=1
                                    obj.and_output{a}(obj.hblob_centroid{a}(b,2)+(ii-6), obj.hblob_centroid{a}(b,1)+(jj-6))= 1;
                                elseif mask_binary(ii,jj)==1
                                    obj.and_output{a}(obj.hblob_centroid{a}(b,2)+(ii-6), obj.hblob_centroid{a}(b,1)+(jj-6))= 1;
                                end
                            end
                              
                        end
                    end
                end 
            end
        end     
    end
end

