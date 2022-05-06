classdef DataLoader

  % Data Loader class that allows the parsing of the VISO data

  properties
    folder
    nameTemplate
    frameRange
  end

  methods

    % Constructor     Creates instance of DataLoader class
    % 
    %   folder        indicates location of images and gt data
    %                 (e.g. 'VISO/mot/car/001')     
    %   nameTemplate  pattern for generating image file names
    %                 (e.g. "%06d.jpg" for the VISO dataset)
    %   frameRange    range of images as 2-element array (e.g. [start, end])
    function obj = DataLoader(folder, nameTemplate, frameRange)

      if ~exist(folder, 'dir')
        error('Folder does not exist.')
      end

      folderContent = dir([folder '/img/*'])

      if ~exist('frameRange','var')
        % frameRange does not exist, so default to all frames
        numImages = size(folderContent, 1)
        obj.frameRange = [1 numImages]
      else
        obj.frameRange = frameRange;
      end

      obj.folder = folder;
      obj.nameTemplate = nameTemplate;
      
    end
  end
end