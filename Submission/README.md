# CITS4402-Project-SmallTargetTracking

This project uses a Matlab implementation to analyse sequences of satellite images to track moving vehicles.

This README file contains instructions on the launching and operation of the target tracking application.


## **(important)** Using VISO Dataset 

The training dataset, which can be found [here](https://github.com/The-Learning-And-Vision-Atelier-LAVA/VISO), should be stored in the root folder in a folder named `/VISO/` (Simply unzip the file and place all contents in folder). Once you have unzipped the file, you must unarchive the `mot.rar` file and store its contents in `/VISO/mot/`. This is the dataset that will be used for the application.

Data explanation:
> Be aware that the 4 main folders in the VISO dataset are, in fine, the same data, which was
organised in different ways. You need to use the “mot” (multiple objects tracking) folder for this
project. The gt.txt files associated to each sequence contain an array in csv format with the first
column representing the frame, the second column the track id, the third to sixth column the
rectangle x, y top left coordinates, width and height in pixels. The remaining columns encode other
arguments of the data and they should be ignored in this project.

In summary, the columns in `gt.txt` are as follows:

| Column | Title | Description
| :-: | :----- | :---------- |
| 1 | Frame | Indicates the frame that contains the object being tracked. |
| 2 | Track ID | ID of the object being tracked | 
| 3 | X Coord | X coordinate of the top left corner of the tracking rectangle |
| 4 | Y Coord | Y coordinate of the top left corner of the tracking rectangle | 
| 5 | Width | Width of the tracking rectangle | 
| 6 | Height | Height of the tracking rectangle |


**NOTE:** The zipped data has a size of 8.6G so should only be stored locally and not included anywhere in the Github Repository when committing code.

## Operating the GUI

Launch the file ObjectTrackerGUI.m. Once open, select the location of the candidate file that you would like to perform the tracking on (images should exist in a folder /img/ within the folder you select). Then, select the location of the `gt.txt` file. Either select the option to inherit the frame range or enter the desired frame range to perform the tracking. Finally, input the template of the image filenames that are to be used for the tracking. 

When you click Process & Display Image Sequence, a new window will pop up to display the image sequence with tracked objects.