classdef data_loader

  % Data Loader class that allows the parsing of the VISO data

  properties
    folder          % Folder path that contains VISO dataset
    nameTemplate    % string to specify filename format (see sprintf())
    frameRange      % 2-element array indicating start & end of frames
  end

  methods

    % Constructor     Creates instance of DataLoader class
    % 
    %   folder        indicates location of images and gt data
    %                 (e.g. 'VISO/mot/car/001')     
    %   nameTemplate  pattern for generating image file names
    %                 (e.g. "%06d.jpg" for the VISO dataset)
    %   frameRange    range of images as 2-element array (e.g. [start, end])
    function obj = data_loader(folder, nameTemplate, frameRange)

      if ~exist(folder, 'dir')
        error('Folder does not exist.')
      end

      folderContent = dir(strcat(folder,'/img/'));

      if ~exist('frameRange','var')
        % frameRange does not exist, so default to all frames
        numImages = size(folderContent, 1);
        obj.frameRange = [1 numImages-2]; % Discount '.' and '..' directories
      else
        obj.frameRange = frameRange;
      end

      obj.folder = folder;
      obj.nameTemplate = nameTemplate;
      
    end

    % Load Image        Returns image from source folder
    %
    %   imgNumber       The number in the sequence of images 
    %                   (From start of frameRange as imgNumber = 1)
    function r = loadImage(obj, imgNumber)

        if(imgNumber < 1)
            error('Image Number not in frame range: Too Low')
        end

        if(imgNumber > obj.frameRange(2)-obj.frameRange(1)+1)
            error('Image Number not in frame range: Too High')
        end
    
        imgNumber = imgNumber + obj.frameRange(1) - 1;
        imgFileName = sprintf(obj.nameTemplate, imgNumber);
        imgFileLocation = strcat(obj.folder, '/img/', imgFileName);

        % Returns image
        r = imread(imgFileLocation);
    end

    % Get Regions       Returns matrix of regions of object locations
    function r = getRegions(obj)
        dataFileLocation = strcat(obj.folder, '/gt/gt.txt');
        r = readmatrix(dataFileLocation, Range='A:F');
    end

  end
end