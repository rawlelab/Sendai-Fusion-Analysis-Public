function [NumberOfFiles,FileOptions,NumberOfParameters] = Load_Video_Files(Options,varargin)

% Output:
% SaveFolderDir = directory where the analysis files will be saved
% StackFilenames = file names of the image video stacks (should be a stack of .tif)
% DefaultPathname = directory where the image video stacks are located

FileOptions = [];
InputPaths = varargin{1,1};

if ~strcmp(Options.CombineMultipleVideos,'y')
    %First, we load the .tif files.  Should be an image stack.  We'll also
    %set up the save folder.

    disp('   All righty. Please select the metadata file for the data you wish to analyze.')
    disp('   It should be in the same folder as the data itself...')

    if length(InputPaths) == 1
        [StackFilenames, DefaultPathname] = uigetfile('*.*','Select the metadata file',...
            InputPaths{1},'Multiselect', 'on');

        disp("   Great. Now select the location of the save folder...")


        SaveFolderDir = uigetdir(InputPaths{1},'Choose the directory where data folder will be saved');

    elseif length(InputPaths) == 2
        SaveFolderDir = InputPaths{1,2};
        [StackFilenames, DefaultPathname] = uigetfile('*.*','Select the metadata file',...
            InputPaths{1,1},'Multiselect', 'on');

    else
        [StackFilenames, DefaultPathname] = uigetfile('*.*', 'Multiselect', 'on');

        disp("    Great. Now select the location of the save folder...")

        SaveFolderDir = uigetdir(DefaultPathname,'Choose the directory where data folder will be saved');
    end
    
    disp("   Awesome - let's continue!")

    %Determine the number of files selected by the user
    if iscell(StackFilenames)
        NumberOfFiles = length(StackFilenames);
    else
        NumberOfFiles = 1;
    end
    
else
    SaveFolderDir = InputPaths{1,2};
    for i= 1:Options.NumberOfVideosToCombine
        disp("   Select the metadata file for video #"+num2str(i))
        [StackFilenames{1,i}, DefaultPathnamesToCombine{1,i}] = uigetfile('*.*','Select the metadata file',...
            InputPaths{1,1},'Multiselect', 'on');
    end
    DefaultPathname = DefaultPathnamesToCombine{1,1};
    NumberOfFiles = 1;
    % We call this 1 file because that is what we will ultimately be combining it into
end



    for i= 1:NumberOfFiles     
        CurrentOptions = Options;
        CurrentOptions.DefaultPathname = DefaultPathname;
        CurrentOptions.SaveParentFolder = SaveFolderDir;
        if ~strcmp(Options.CombineMultipleVideos,'y')
            if NumberOfFiles == 1
                CurrentOptions.VideoFilename = StackFilenames;
            else
                CurrentOptions.VideoFilename = StackFilenames{1,i};
            end
        else
            CurrentOptions.VideoFilename = StackFilenames{1,1};
            % We set the VideoFile name as referring to the first video. 
            % That way, if we display the finding image in a later program 
            % (e.g. trace analysis) it won't cause any problems
            
            CurrentOptions.VideoFilenamesToCombine = StackFilenames;
            CurrentOptions.DefaultPathnamesToCombine = DefaultPathnamesToCombine;
        end
              
        if strcmp(Options.ScanParameters,'y')
            [FileOptions,NumberOfParameters] = Setup_Parameter_Scan(FileOptions,i,CurrentOptions);
        else
            FileOptions(i).Parameter(1).Options = CurrentOptions;
            NumberOfParameters = 1;
        end
    end
end