function [FrameAllVirusStoppedBy,StandardBindTime,FocusFrameNumbers,IgnoreFrameNumbers,focusproblems,ignoreproblems] =...
    Determine_BindTime_Focus_Stop_FrameNumbers(OtherImportedData,InputTraceData,Options)

%Determine standard bind time
    if isempty(Options.ChangeBindingTime)
        StandardBindTime = OtherImportedData.StandardBindTime;
        disp(strcat('standard bind time defined = ',num2str(StandardBindTime), '_min'))
    else
        StandardBindTime = Options.ChangeBindingTime;
        disp(strcat('standard bind time re-defined = ',num2str(StandardBindTime), '_min'))
    end

%Determine frame number all virus particles have stopped moving
    if isfield(InputTraceData(1), 'FrameAllVirusStoppedBy')
        if isnan(InputTraceData(1).FrameAllVirusStoppedBy)
            FrameAllVirusStoppedBy = Options.FrameAllVirusStoppedBy;
        else
            FrameAllVirusStoppedBy = InputTraceData(1).FrameAllVirusStoppedBy;
        end
    else
%         FrameAllVirusStoppedBy = Options.FrameAllVirusStoppedBy;
        FrameAllVirusStoppedBy = [];
    end

% Extract focus frame nums. Note that these frame numbers were shifted automatically 
% in the Extract Traces program to account for the time zero or other frames at the 
% beginning that were chopped from the analysis.
    if isempty(InputTraceData(1).FocusFrameNumbers_Shifted)
        InputTraceData(1).FocusFrameNumbers_Shifted = NaN;
    end

    if isnan(InputTraceData(1).FocusFrameNumbers_Shifted(1)) && isempty(Options.AdditionalFocusFrameNumbers_Shifted)

        focusproblems = 'n';
        FocusFrameNumbers = NaN;
    else
        focusproblems = 'y';
        if isnan(InputTraceData(1).FocusFrameNumbers_Shifted(1)) && ~isempty(Options.AdditionalFocusFrameNumbers_Shifted)
            FocusFrameNumbers = Options.AdditionalFocusFrameNumbers_Shifted;
        else 
            FocusFrameNumbers = InputTraceData(1).FocusFrameNumbers_Shifted;
            FocusFrameNumbers = [FocusFrameNumbers' Options.AdditionalFocusFrameNumbers_Shifted];
        end
        disp(strcat('user def focus problems, fr_shifted = ',num2str(FocusFrameNumbers)));
    end

    
% Extract ignore frame nums. Note that these frame numbers were shifted automatically 
% in the Extract Traces program to account for the time zero or other frames at the 
% beginning that were chopped from the analysis.
    if isempty(InputTraceData(1).IgnoreFrameNumbers_Shifted)
        InputTraceData(1).IgnoreFrameNumbers_Shifted = NaN;
    end

    if isnan(InputTraceData(1).IgnoreFrameNumbers_Shifted(1)) && isempty(Options.AdditionalIgnoreFrameNumbers_Shifted)

        ignoreproblems = 'n';
        IgnoreFrameNumbers = NaN;
    else
        ignoreproblems = 'y';
        if isnan(InputTraceData(1).IgnoreFrameNumbers_Shifted(1)) && ~isempty(Options.AdditionalIgnoreFrameNumbers_Shifted)
            IgnoreFrameNumbers = Options.AdditionalIgnoreFrameNumbers_Shifted;
        else 
            IgnoreFrameNumbers = InputTraceData(1).IgnoreFrameNumbers_Shifted;
            IgnoreFrameNumbers = [IgnoreFrameNumbers' Options.AdditionalIgnoreFrameNumbers_Shifted];
        end
        disp(strcat('user def ignore problems, fr_shifted = ',num2str(IgnoreFrameNumbers)));
    end
    
end