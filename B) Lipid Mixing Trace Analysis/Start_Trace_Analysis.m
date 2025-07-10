function [DefaultPathname] = Start_Trace_Analysis(varargin)
% - - - - - - - - - - - - - - - - - - - - -

% Input:
% Start_Trace_Analysis_Program(), in this case the user navigates to the
%       .mat output file from the Extract Traces From Video program.
%   OR
% Start_Trace_Analysis_Program(DefaultPath), where DefaultPath is the directory to which 
%       the user will be automatically directed to find the 
%       .mat output file from the Extract Traces From Video program.

% Output:
% A .mat file is created which saves all of the variables in the current 
% workspace. This file is saved in a new folder created in the parent 
% directory where the input file came from. The information about the 
% waiting time for each lipid mixing event, as well as the designation 
% of each trace, is contained in the DataToSave.CombinedAnalyzedTraceData 
% structure, as defined in the Compile_Analyzed_Trace_Data.m file.

% Note: This program has been designed to process many sets of data sequentially,
% but it has only been tested with individual sets, so keep that 
% in mind if you choose to process many sets at once.

% By Bob Rawle, Kasson Lab, University of Virginia, 2016
% Published online in conjunction with:
% Rawle et al., Disentangling Viral Membrane Fusion from Receptor Binding 
% Using Synthetic DNA-Lipid Conjugates, Biophysical Journal (2016) 
% http://dx.doi.org/10.1016/j.bpj.2016.05.048

% Updated by Prof. Bob Rawle, Williams College, 2024
% - - - - - - - - - - - - - - - - - - - - -

disp('====================================')
disp('Initiating Traces Analysis Program.......')

    close all

    % Identify the paths to the data you wish to analyze
    [DataFilenames,DefaultPathname] = Load_Data(varargin);
        % Nested function

    % Define options. Ask if they look ok.
    [Options] = Setup_Options_Trace_Analysis(DefaultPathname);
    
        Options
        AreOptionsOk = input('   Options look good? (y to proceed) :','s');
            
            if strcmp(AreOptionsOk,'y')
                disp('   Excellent. Lets proceed with the analysis.')
                disp('   ...')
            else
                disp('   Options no good? Then change em and run the program again!')
                disp('   Program terminated.')
                disp('====================================')
                return
            end
    
    %Debugging
    if strcmp(Options.DisplayFigures,'y')
%         dbstop in Analyze_Current_Data_Set at 6
%     dbstop
    end
    
    [FigureHandles] = Setup_Figure_Windows(Options);
   
        RestartCount = []; CombinedAnalyzedTraceData = [];
        disp(' '); disp(' '); disp (' ');
    
    % Determine how many files are being analyzed
    if iscell(DataFilenames) %This lets us know if there is more than one file
        NumberOfFiles = length(DataFilenames);
    else
        NumberOfFiles = 1;
    end

    % Analyze files one by one
    for i = 1:NumberOfFiles
        if NumberOfFiles > 1
           CurrDataFileName = DataFilenames{1,i};
        else
           CurrDataFileName = DataFilenames;
        end
        
        CurrDataFilePath = strcat(DefaultPathname,CurrDataFileName);

        % Call the analysis function to analyze the data from the current
        % set
            [AnalyzedTraceData,OtherDataToSave,StatsOfFailures,StatsOfDesignations] =...
            Analyze_Current_Data_Set(CurrDataFilePath,Options,FigureHandles)

        if strcmp(Options.BobStyleSave,'y')
            [Options] = Bob_Style_Save(CurrDataFileName,Options);
        end
        
                
        %To combine the data from dif files, we have to deal with empty structures,
        %which can create problems.  So we deal with it and then
        %combine the current data with the previous iterations
%             [CombinedAnalyzedTraceData,RestartCount]= ...
%             Deal_With_Empty_Recorded_Data(i,AnalyzedTraceData,CombinedAnalyzedTraceData,RestartCount);

        % Print out results/statistics to commandline
        disp('   ...')
        disp('   All traces analyzed.')
        disp('   ...')

            disp(strcat('--------------Results: File_', num2str(i),'_of_',num2str(NumberOfFiles),'--------------'))
            disp(' ')
            disp(strcat('Filename: ', CurrDataFileName))
            StatsOfFailures
            StatsOfDesignations


        % Save the data
        Save_Data_At_Each_Step(AnalyzedTraceData,OtherDataToSave,DefaultPathname,Options.Label,Options)

            disp('---------------------------------------------')
            

    end
    

disp("   Looks like all files have been analyzed, boss!")

    if strcmp(Options.DisplayColoredVirusesAtEnd,'y')
        disp("   Color code info for final image:")
        disp("        Green = 1 Fusion")
        disp("        Red = No Fusion")
        disp("        Yellow = Unbound")
        disp("        Cyan = Slow (aka 'Other')")
    end

disp('   Thank you.  Come again.')
disp('====================================')

        
end

function Save_Data_At_Each_Step(AnalyzedTraceData,OtherDataToSave,DefaultPathname,Label,Options)

    DataToSave.OtherDataToSave = OtherDataToSave;
    
    if strcmp(Options.BobStyleSave,'y')
        IndexofSlash = find(DefaultPathname == '/');
        SaveDataFolder = DefaultPathname(1:IndexofSlash(end-1));
    else
        SaveDataFolder = DefaultPathname;
    end
    
    SaveDataFolder = strcat(SaveDataFolder,'/Analysis/');
    if exist(SaveDataFolder,'dir') == 0
        mkdir(SaveDataFolder);
    end

    if ~isempty(AnalyzedTraceData)
        DataToSave.CombinedAnalyzedTraceData = AnalyzedTraceData;
        
        CurrSaveFilePath = strcat(SaveDataFolder,Label,'.mat');
        save(CurrSaveFilePath,'DataToSave');

        disp('   ...')
        disp("   Output file saved to : " + CurrSaveFilePath)
    end

    

end


function [CombinedAnalyzedTraceData,RestartCount]= ...
                Deal_With_Empty_Recorded_Data(i,AnalyzedTraceData,CombinedAnalyzedTraceData,RestartCount)

    %Compile the data which will be saved (there are lots of
    %complicated if statements here just to deal with the times
    %that there doesn't happen to be any events recorded in a given file).
    if i == 1
        if ~isempty(AnalyzedTraceData)
            CombinedAnalyzedTraceData = AnalyzedTraceData; %This is a structure
            RestartCount = 'n';
        else
            RestartCount = 'y';
        end
        
    else
        if RestartCount == 'y'
            if ~isempty(AnalyzedTraceData)
                CombinedAnalyzedTraceData = AnalyzedTraceData; %This is a structure
                RestartCount = 'n';
            else
                RestartCount = 'y';
            end
        elseif ~isempty(AnalyzedTraceData)
            StartIdx = length(CombinedAnalyzedTraceData) + 1;
            EndIdx = StartIdx + length(AnalyzedTraceData)-1;
            CombinedAnalyzedTraceData(StartIdx:EndIdx) = AnalyzedTraceData;
        end
    end
end

function [DataFilenames,DefaultPathname] = Load_Data(varargin)

    disp('   Please select the file of extracted traces from the raw video.')
    disp('   It should be the output of the Extract Traces program.')
    disp('   It should be a .mat file in the save location you specified...')

        if length(varargin) == 1
            [DataFilenames, DefaultPathname] = uigetfile('*.mat','Select .mat files to be analyzed',...
                char(varargin{1}),'Multiselect', 'on');
        else
            [DataFilenames, DefaultPathname] = uigetfile('*.mat','Select .mat files to be analyzed', 'Multiselect', 'on');
        end

        disp("   Awesome - let's continue!")

end