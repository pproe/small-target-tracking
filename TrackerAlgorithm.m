
function ta = trackingAlgorithm(centroids, trackerArray)

    detections = GetDetectionCoords(centroids);
    processedTracks = trackingAlgorithmSub(detections,trackerArray);
    trackerArray = processedTracks;
    ta = trackerArray;

end


function tas = trackingAlgorithmSub(detections,tracks)
    
    [assignments,unassignedTracks, unassignedDetections] = MatchDetectionsAndTracks(detections,tracks);
    %match tracks to detections and return matches or unassigned tracks /
    %detections

    tracksFinal = AddTracks(unassignedDetections,detections);
    %add any unassigned detections to track list
    
    updatedTracks = UpdateTracks(assignments,detections,tracks);
    %update tracks with new detection info

    tracksFinal = [tracksFinal; updatedTracks];
    %put it all in the one array 

    tas = tracksFinal;

end

function ut = UpdateTracks(assignments, detections, tracks)
    
    updatedTracks = [];
    for i= 1: size(assignments,1)
        %followed process for Kalman Filter Update section

        innovation = detections(assignments(i,2)) - HMatrix * tracks(assignments(i,1)).vector;
        %calculate innovation

        covInnovation = HMatrix * tracks(assignments(i,1)).covariance * transpose(HMatrix) + RMatrix;
        %calculate covariance innovation

        optimalKalman = tracks(assignments(i,1)).covariance * transpose(HMatrix) * inv(covInnovation);
        %calculate optimal kalman

        newTrack = Tracker();
        newTrack.vector = tracks(assignments(i,1)).vector + optimalKalman * innovation;
        newTrack.covariance = (eye(6,6) - optimalKalman * HMatrix) * tracks(assignments(i,1)).covariance;
        %create a new track and calculate new vector and covariance

        updatedTracks = [updatedTracks; newTrack];
        %add to updatedTracks

    end 
    ut = updatedTracks;
    
end


function at = AddTracks(unassignedDetections, detections)
    
    tracks = [];
    if size(unassignedDetections,1) > size(unassignedDetections,2)
        unassignedDetections = transpose(unassignedDetections);
        %sometimes unassignedDetections is returned as a vector so needs to
        %be converted to a matrix
    end

    if size(unassignedDetections,1) >0 
        for i = 1: size(unassignedDetections,2)
            newVect = [detections(unassignedDetections(i),1); detections(unassignedDetections(i),2); 0;  0;  0; 0];
            newTrack = Tracker();
            newTrack.vector = newVect;
            newTrack.covariance = QMatrix;
            %create new track for all unassigned detections

            tracks = [tracks; newTrack];
        end
    end 
    
    at = tracks;

end 


function [a,ut,ud] = MatchDetectionsAndTracks(detections,tracks)
    
    %detectionsCoords = GetDetectionCoords(detections);
    if size(tracks,1) ==0 
         a = [];
         ut = [];
         ud = 1:length(detectionsCoords);
         %if there's no tracks, all the detections are unassigned
    else
    
        trackCoords = GetTrackCoords(tracks);
        %extract the coords from tracks
        cost = zeros(size(trackCoords,1),size(detectionsCoords,1));
        for i = 1:size(trackCoords, 1)
          diff = detectionsCoords - repmat(trackCoords(i,:),[size(detectionsCoords,1),1]);
          cost(i, :) = sqrt(sum(diff .^ 2,2));
        end
        %calculate cost matrix

        [a,ut,ud] = assignDetectionsToTracks(cost,0.2);
        %use Matlab function to assign detections to tracks
    end

end

function gdc = GetDetectionCoords(detections)
    %if centroids are in different format, have the extraction process here
    detectionCoords = [];
    for i = 1: length(detections)
        newval = [detections(i,1), detections(i,2)];
        detectionCoords = [detectionCoords; newval];
    end
    gdc= detectionCoords;
end 


function gtc = GetTrackCoords(tracks)
    trackCoords = [];
    for i= 1: length(tracks)
        newval=[tracks(i).vector(1), tracks(i).vector(2)];
      trackCoords = [trackCoords; newval];
    end
    %get the coordinates out the track vectors
    gtc = trackCoords;
end


function hm = HMatrix
    hm = [1 0 0 0 0 0; 0 1 0 0 0 0];
end 

function rm = RMatrix
    rm = [1 0; 0 1]; % needs some fields calculated
end 

function fm = FMatrix
    fm = [1 0 1 0 0.5 0; 0 1 0 1 0 0.5; 0 0 1 0 1 0; 0 0 0 1 0 1; 0 0 0 0 1 0; 0 0 0 0 0 1];
end

function qm = QMatrix
    qm = [1 0 0 0 0 0; 0 1 0 0 0 0; 0 0 1 0 0 0; 0 0 0 1 0 0; 0 0 0 0 1 0; 0 0 0 0 0 1]; % needs fields calculated 
end