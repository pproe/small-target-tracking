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
            
            
        end     
    end
end

