classdef ObjectTrackerGUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        F1Score                       matlab.ui.control.Label
        F1ScoreforWholeSequenceLabel  matlab.ui.control.Label
        AverageRecall                 matlab.ui.control.Label
        AverageRecallforWholeSequenceLabel  matlab.ui.control.Label
        AveragePrecision              matlab.ui.control.Label
        AveragePrecisionforWholeSequenceLabel  matlab.ui.control.Label
        SwitchedGTObjects             matlab.ui.control.Label
        TracksthatSwitchedGTObjectsLabel  matlab.ui.control.Label
        NotMatched                    matlab.ui.control.Label
        ProportionofGTobjectsnotmatchedLabel  matlab.ui.control.Label
        ParameterPanel                matlab.ui.container.Panel
        ImageNameTemplateInput        matlab.ui.control.EditField
        ImageNameTemplateLabel        matlab.ui.control.Label
        StartButton                   matlab.ui.control.Button
        GTLocationInput               matlab.ui.control.EditField
        SelectFileButton              matlab.ui.control.Button
        GroundTruthLocationLabel      matlab.ui.control.Label
        InheritFromSourceButton       matlab.ui.control.StateButton
        SelectFolderButton            matlab.ui.control.Button
        EndLabel                      matlab.ui.control.Label
        FrameRangeEnd                 matlab.ui.control.NumericEditField
        StartLabel                    matlab.ui.control.Label
        FrameRangeStart               matlab.ui.control.NumericEditField
        FrameRangeLabel               matlab.ui.control.Label
        FolderLocationInput           matlab.ui.control.EditField
        ImageSourceLocationLabel      matlab.ui.control.Label
        OriginalImplementationLabel   matlab.ui.control.Label
        SmallObjectTrackinginSatelliteImagesLabel  matlab.ui.control.Label
        AverageRecallAxes             matlab.ui.control.UIAxes
        AveragePrecisionAxes          matlab.ui.control.UIAxes
        MovingObjectsAxes             matlab.ui.control.UIAxes
    end



    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: InheritFromSourceButton
        function InheritFromSourceButtonValueChanged(app, event)
            app.FrameRangeStart.Enable = ~app.InheritFromSourceButton.Value;
            app.FrameRangeEnd.Enable = ~app.InheritFromSourceButton.Value;
        end

        % Button pushed function: SelectFolderButton
        function SelectFolderButtonPushed(app, event)
            % Get file and path using ui component
            path = uigetdir();
            app.FolderLocationInput.Value = path;
        end

        % Button pushed function: SelectFileButton
        function SelectFileButtonPushed(app, event)
            [file, path] = uigetfile({'*.txt'});

            % Read image from file location
            app.GTLocationInput.Value = strcat(path,file);
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            fig = uifigure;
            d = uiprogressdlg(fig,'Title','Loading...',...
                'Indeterminate','on');
            drawnow
    
            % Parse frame range
            if app.InheritFromSourceButton.Value
                dataLoader = DataLoader(app.FolderLocationInput.Value, app.ImageNameTemplateInput.Value);
            else
                frameRange = [app.FrameRangeStart.Value, app.FrameRangeEnd.Value];
                dataLoader = DataLoader(app.FolderLocationInput.Value, app.ImageNameTemplateInput.Value, frameRange);
            end

            tracker = ObjectTracker(dataLoader);

            imageSequence = tracker.trackObjects();

            close(d);

            

            implay(imageSequence);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 676 692];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create MovingObjectsAxes
            app.MovingObjectsAxes = uiaxes(app.GridLayout);
            title(app.MovingObjectsAxes, 'Moving Objects Detected per Frame')
            xlabel(app.MovingObjectsAxes, 'Image Sequence Number')
            ylabel(app.MovingObjectsAxes, 'Moving Objects')
            zlabel(app.MovingObjectsAxes, 'Z')
            app.MovingObjectsAxes.Layout.Row = [11 15];
            app.MovingObjectsAxes.Layout.Column = [1 8];

            % Create AveragePrecisionAxes
            app.AveragePrecisionAxes = uiaxes(app.GridLayout);
            title(app.AveragePrecisionAxes, 'Average Precision by Frame')
            xlabel(app.AveragePrecisionAxes, 'Image Sequence Number')
            ylabel(app.AveragePrecisionAxes, 'Precision')
            zlabel(app.AveragePrecisionAxes, 'Z')
            app.AveragePrecisionAxes.Layout.Row = [16 20];
            app.AveragePrecisionAxes.Layout.Column = [1 8];

            % Create AverageRecallAxes
            app.AverageRecallAxes = uiaxes(app.GridLayout);
            title(app.AverageRecallAxes, 'Average Recall by Frame')
            xlabel(app.AverageRecallAxes, 'Image Sequence Number')
            ylabel(app.AverageRecallAxes, 'Recall')
            zlabel(app.AverageRecallAxes, 'Z')
            app.AverageRecallAxes.Layout.Row = [21 25];
            app.AverageRecallAxes.Layout.Column = [1 8];

            % Create SmallObjectTrackinginSatelliteImagesLabel
            app.SmallObjectTrackinginSatelliteImagesLabel = uilabel(app.GridLayout);
            app.SmallObjectTrackinginSatelliteImagesLabel.HorizontalAlignment = 'center';
            app.SmallObjectTrackinginSatelliteImagesLabel.FontSize = 16;
            app.SmallObjectTrackinginSatelliteImagesLabel.FontWeight = 'bold';
            app.SmallObjectTrackinginSatelliteImagesLabel.Layout.Row = [1 2];
            app.SmallObjectTrackinginSatelliteImagesLabel.Layout.Column = [4 9];
            app.SmallObjectTrackinginSatelliteImagesLabel.Text = 'Small Object Tracking in Satellite Images';

            % Create OriginalImplementationLabel
            app.OriginalImplementationLabel = uilabel(app.GridLayout);
            app.OriginalImplementationLabel.HorizontalAlignment = 'right';
            app.OriginalImplementationLabel.FontSize = 10;
            app.OriginalImplementationLabel.Layout.Row = [2 3];
            app.OriginalImplementationLabel.Layout.Column = [1 12];
            app.OriginalImplementationLabel.Text = {'Original Implementation: "Needles in a Haystack: Tracking City-Scale Moving Vehicles From Continuously Moving Satellite" by Wei et al.'; 'Implemented by Eamon Gu, Josh Radich & Patrick Roe, University of WA'};

            % Create ParameterPanel
            app.ParameterPanel = uipanel(app.GridLayout);
            app.ParameterPanel.Title = 'File Selection & Hyper-Parameter Tuning';
            app.ParameterPanel.Layout.Row = [4 10];
            app.ParameterPanel.Layout.Column = [2 11];
            app.ParameterPanel.FontWeight = 'bold';
            app.ParameterPanel.FontSize = 14;

            % Create ImageSourceLocationLabel
            app.ImageSourceLocationLabel = uilabel(app.ParameterPanel);
            app.ImageSourceLocationLabel.FontWeight = 'bold';
            app.ImageSourceLocationLabel.Position = [10 131 143 17];
            app.ImageSourceLocationLabel.Text = 'Image Source Location';

            % Create FolderLocationInput
            app.FolderLocationInput = uieditfield(app.ParameterPanel, 'text');
            app.FolderLocationInput.HorizontalAlignment = 'right';
            app.FolderLocationInput.Tooltip = {'indicates location of images and gt data (e.g. ''VISO/mot/car/001'')'};
            app.FolderLocationInput.Position = [279 129 246 22];

            % Create FrameRangeLabel
            app.FrameRangeLabel = uilabel(app.ParameterPanel);
            app.FrameRangeLabel.FontWeight = 'bold';
            app.FrameRangeLabel.Position = [10 53 82 22];
            app.FrameRangeLabel.Text = 'Frame Range';

            % Create FrameRangeStart
            app.FrameRangeStart = uieditfield(app.ParameterPanel, 'numeric');
            app.FrameRangeStart.Limits = [0 Inf];
            app.FrameRangeStart.RoundFractionalValues = 'on';
            app.FrameRangeStart.FontSize = 10;
            app.FrameRangeStart.Tooltip = {'First frame of image sequence to be processed'};
            app.FrameRangeStart.Position = [351 53 37 22];

            % Create StartLabel
            app.StartLabel = uilabel(app.ParameterPanel);
            app.StartLabel.FontSize = 10;
            app.StartLabel.Position = [351 71 27 22];
            app.StartLabel.Text = 'Start';

            % Create FrameRangeEnd
            app.FrameRangeEnd = uieditfield(app.ParameterPanel, 'numeric');
            app.FrameRangeEnd.Limits = [0 Inf];
            app.FrameRangeEnd.RoundFractionalValues = 'on';
            app.FrameRangeEnd.FontSize = 10;
            app.FrameRangeEnd.Tooltip = {'Last frame of image sequence to be processed.'};
            app.FrameRangeEnd.Position = [403 53 39 22];

            % Create EndLabel
            app.EndLabel = uilabel(app.ParameterPanel);
            app.EndLabel.FontSize = 10;
            app.EndLabel.Position = [403 71 25 22];
            app.EndLabel.Text = 'End';

            % Create SelectFolderButton
            app.SelectFolderButton = uibutton(app.ParameterPanel, 'push');
            app.SelectFolderButton.ButtonPushedFcn = createCallbackFcn(app, @SelectFolderButtonPushed, true);
            app.SelectFolderButton.Tooltip = {'Load the folder that contains the image sequence to be processed.'};
            app.SelectFolderButton.Position = [171 129 100 22];
            app.SelectFolderButton.Text = 'Select Folder';

            % Create InheritFromSourceButton
            app.InheritFromSourceButton = uibutton(app.ParameterPanel, 'state');
            app.InheritFromSourceButton.ValueChangedFcn = createCallbackFcn(app, @InheritFromSourceButtonValueChanged, true);
            app.InheritFromSourceButton.Tooltip = {'Process all images from source folder. Note: Activating this disregards start and end choices.'};
            app.InheritFromSourceButton.Text = 'Inherit From Source';
            app.InheritFromSourceButton.Position = [171 53 174 22];

            % Create GroundTruthLocationLabel
            app.GroundTruthLocationLabel = uilabel(app.ParameterPanel);
            app.GroundTruthLocationLabel.FontWeight = 'bold';
            app.GroundTruthLocationLabel.Position = [10 88 135 22];
            app.GroundTruthLocationLabel.Text = 'Ground Truth Location';

            % Create SelectFileButton
            app.SelectFileButton = uibutton(app.ParameterPanel, 'push');
            app.SelectFileButton.ButtonPushedFcn = createCallbackFcn(app, @SelectFileButtonPushed, true);
            app.SelectFileButton.Tooltip = {'Load the file that determines the ground-truth of the Tracked objects in the image.'};
            app.SelectFileButton.Position = [171 91 100 22];
            app.SelectFileButton.Text = 'Select File';

            % Create GTLocationInput
            app.GTLocationInput = uieditfield(app.ParameterPanel, 'text');
            app.GTLocationInput.HorizontalAlignment = 'right';
            app.GTLocationInput.Position = [278 91 246 22];

            % Create StartButton
            app.StartButton = uibutton(app.ParameterPanel, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.BackgroundColor = [0.6824 0.8196 0.9098];
            app.StartButton.Position = [319 20 208 22];
            app.StartButton.Text = 'Process & Display Image Sequence';

            % Create ImageNameTemplateLabel
            app.ImageNameTemplateLabel = uilabel(app.ParameterPanel);
            app.ImageNameTemplateLabel.FontWeight = 'bold';
            app.ImageNameTemplateLabel.Tooltip = {'Pattern for generating image file names'};
            app.ImageNameTemplateLabel.Position = [10 20 131 22];
            app.ImageNameTemplateLabel.Text = 'Image Name Template';

            % Create ImageNameTemplateInput
            app.ImageNameTemplateInput = uieditfield(app.ParameterPanel, 'text');
            app.ImageNameTemplateInput.HorizontalAlignment = 'right';
            app.ImageNameTemplateInput.Position = [171 20 100 22];
            app.ImageNameTemplateInput.Value = '%06d.jpg';

            % Create ProportionofGTobjectsnotmatchedLabel
            app.ProportionofGTobjectsnotmatchedLabel = uilabel(app.GridLayout);
            app.ProportionofGTobjectsnotmatchedLabel.FontSize = 10;
            app.ProportionofGTobjectsnotmatchedLabel.FontWeight = 'bold';
            app.ProportionofGTobjectsnotmatchedLabel.Layout.Row = 11;
            app.ProportionofGTobjectsnotmatchedLabel.Layout.Column = [9 12];
            app.ProportionofGTobjectsnotmatchedLabel.Text = 'Proportion of GT objects not matched:';

            % Create NotMatched
            app.NotMatched = uilabel(app.GridLayout);
            app.NotMatched.HorizontalAlignment = 'center';
            app.NotMatched.Layout.Row = 12;
            app.NotMatched.Layout.Column = [9 12];
            app.NotMatched.Text = '';

            % Create TracksthatSwitchedGTObjectsLabel
            app.TracksthatSwitchedGTObjectsLabel = uilabel(app.GridLayout);
            app.TracksthatSwitchedGTObjectsLabel.FontSize = 10;
            app.TracksthatSwitchedGTObjectsLabel.FontWeight = 'bold';
            app.TracksthatSwitchedGTObjectsLabel.Layout.Row = 13;
            app.TracksthatSwitchedGTObjectsLabel.Layout.Column = [9 12];
            app.TracksthatSwitchedGTObjectsLabel.Text = 'Tracks that Switched GT Objects:';

            % Create SwitchedGTObjects
            app.SwitchedGTObjects = uilabel(app.GridLayout);
            app.SwitchedGTObjects.HorizontalAlignment = 'center';
            app.SwitchedGTObjects.Layout.Row = 14;
            app.SwitchedGTObjects.Layout.Column = [9 12];
            app.SwitchedGTObjects.Text = '';

            % Create AveragePrecisionforWholeSequenceLabel
            app.AveragePrecisionforWholeSequenceLabel = uilabel(app.GridLayout);
            app.AveragePrecisionforWholeSequenceLabel.FontSize = 10;
            app.AveragePrecisionforWholeSequenceLabel.FontWeight = 'bold';
            app.AveragePrecisionforWholeSequenceLabel.Layout.Row = 18;
            app.AveragePrecisionforWholeSequenceLabel.Layout.Column = [9 12];
            app.AveragePrecisionforWholeSequenceLabel.Text = 'Average Precision for Whole Sequence:';

            % Create AveragePrecision
            app.AveragePrecision = uilabel(app.GridLayout);
            app.AveragePrecision.HorizontalAlignment = 'center';
            app.AveragePrecision.Layout.Row = 19;
            app.AveragePrecision.Layout.Column = [9 12];
            app.AveragePrecision.Text = '';

            % Create AverageRecallforWholeSequenceLabel
            app.AverageRecallforWholeSequenceLabel = uilabel(app.GridLayout);
            app.AverageRecallforWholeSequenceLabel.FontSize = 10;
            app.AverageRecallforWholeSequenceLabel.FontWeight = 'bold';
            app.AverageRecallforWholeSequenceLabel.Layout.Row = 20;
            app.AverageRecallforWholeSequenceLabel.Layout.Column = [9 12];
            app.AverageRecallforWholeSequenceLabel.Text = 'Average Recall for Whole Sequence:';

            % Create AverageRecall
            app.AverageRecall = uilabel(app.GridLayout);
            app.AverageRecall.HorizontalAlignment = 'center';
            app.AverageRecall.Layout.Row = 21;
            app.AverageRecall.Layout.Column = [9 12];
            app.AverageRecall.Text = '';

            % Create F1ScoreforWholeSequenceLabel
            app.F1ScoreforWholeSequenceLabel = uilabel(app.GridLayout);
            app.F1ScoreforWholeSequenceLabel.FontSize = 10;
            app.F1ScoreforWholeSequenceLabel.FontWeight = 'bold';
            app.F1ScoreforWholeSequenceLabel.Layout.Row = 22;
            app.F1ScoreforWholeSequenceLabel.Layout.Column = [9 12];
            app.F1ScoreforWholeSequenceLabel.Text = 'F1 Score for Whole Sequence:';

            % Create F1Score
            app.F1Score = uilabel(app.GridLayout);
            app.F1Score.HorizontalAlignment = 'center';
            app.F1Score.Layout.Row = 23;
            app.F1Score.Layout.Column = [9 12];
            app.F1Score.Text = '';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ObjectTrackerGUI

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end