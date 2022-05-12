classdef object_tracker
    %   Object Tracker      Performs object tracking functionality

    properties
        dataLoader
    end

    methods
        function obj = object_tracker(dataLoader)
            % Constructor for Object Tracker
            %       Must be provided with a valid dataLoader class for 
            %       access to images & data files
            obj.dataLoader = dataLoader;
        end

        function r = trackObjects(obj)
            % Detects and Tracks objects 

            % Primary function for operation of the tracking algorithm

            % Performs Candidate Detection and Tracking for all frames within frame
            % range

            % Input: for each frame index n from 1 to N-1, this step takes as input a binary image representing
            % candidate small objects, as well as the state of the tracker (the Kalman state vectors for each tracks,
            % and the corresponding covariances estimates) from the previous frame.

            % Ouput: a series of tracks, each made up of a Kalman state vector representing the position, speed
            % and acceleration of the tracked small objects.
            
        end

        function r = detectCandidates(obj, prevFrame, frame, nextFrame)
            % Candidate Detection 
            % Detects the candidates within a single frame

            % a) Inter-Frames Difference

            % b) Thresholding

            % c) Candidates Extraction
            
        end

        function r = discriminateCandidates(obj,prevFrame, frame, nextFrame)
            % Candidate Discrimination
            % Performs Discrimination of candidates within a single frame
            
            % a) Region Growing

            % b) Detect False-Positives (Using Morphological Cues)

        end
    end
end





